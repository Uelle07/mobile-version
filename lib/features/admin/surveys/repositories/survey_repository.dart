import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cooperative_member_app/core/models/survey.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final surveyRepositoryProvider = Provider<SurveyRepository>((ref) {
  return SurveyRepository(FirebaseFirestore.instance);
});

class SurveyRepository {
  final FirebaseFirestore _firestore;

  SurveyRepository(this._firestore);

  // --- Surveys ---

  Stream<List<Survey>> watchSurveys() {
    return _firestore
        .collection('surveys')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Survey.fromJson(data);
          }).toList(),
        );
  }

  Stream<Survey> watchSurvey(String surveyId) {
    return _firestore.collection('surveys').doc(surveyId).snapshots().map((
      doc,
    ) {
      final data = doc.data() ?? {};
      data['id'] = doc.id;
      return Survey.fromJson(data);
    });
  }

  Future<void> createSurvey(Survey survey) async {
    final data = survey.toJson();
    data.remove('id');
    data['created_at'] = FieldValue.serverTimestamp();
    await _firestore.collection('surveys').add(data);
  }

  Future<void> updateSurvey(Survey survey) async {
    final data = survey.toJson();
    data.remove('id');
    await _firestore.collection('surveys').doc(survey.id).update(data);
  }

  Future<void> deleteSurvey(String surveyId) async {
    // Delete survey questions and choices first in a real app,
    // or use a Cloud Function for cascading deletes.
    // For now, we just delete the survey document.
    await _firestore.collection('surveys').doc(surveyId).delete();
  }

  Future<void> publishSurvey(String surveyId) async {
    await _firestore.collection('surveys').doc(surveyId).update({
      'status': 'active',
    });
  }

  // --- Auto-healing ---

  Future<void> healSurveyCounts(
    String surveyId,
    int currentQuestionsCount,
    int currentRespondentsCount,
  ) async {
    final questionsQuery = await _firestore
        .collection('survey_questions')
        .where('survey_id', isEqualTo: surveyId)
        .count()
        .get();
    final responsesQuery = await _firestore
        .collection('responses')
        .where('survey_id', isEqualTo: surveyId)
        .count()
        .get();

    final trueQuestionsCount = questionsQuery.count ?? 0;
    final trueRespondentsCount = responsesQuery.count ?? 0;

    if (trueQuestionsCount != currentQuestionsCount ||
        trueRespondentsCount != currentRespondentsCount) {
      await _firestore.collection('surveys').doc(surveyId).update({
        'questionsCount': trueQuestionsCount,
        'respondentsCount': trueRespondentsCount,
      });
    }
  }

  Future<void> _updateQuestionsCount(String surveyId) async {
    final questionsQuery = await _firestore
        .collection('survey_questions')
        .where('survey_id', isEqualTo: surveyId)
        .count()
        .get();
    final count = questionsQuery.count ?? 0;
    await _firestore.collection('surveys').doc(surveyId).update({
      'questionsCount': count,
    });
  }

  // --- Questions ---

  Stream<List<SurveyQuestion>> watchQuestions(String surveyId) {
    return _firestore
        .collection('survey_questions')
        .where('survey_id', isEqualTo: surveyId)
        // Removed orderBy('question_order') temporarily to allow older questions to show
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return SurveyQuestion.fromJson(data);
          }).toList();
          list.sort(
            (a, b) => (a.questionOrder ?? 0).compareTo(b.questionOrder ?? 0),
          );
          return list;
        });
  }

  Future<void> addQuestion(
    SurveyQuestion question,
    List<String> choices,
  ) async {
    final data = question.toJson();
    data.remove('id');
    data['created_at'] = FieldValue.serverTimestamp();

    // Auto-increment question_order
    final countSnapshot = await _firestore
        .collection('survey_questions')
        .where('survey_id', isEqualTo: question.surveyId)
        .count()
        .get();
    data['question_order'] = countSnapshot.count ?? 0;

    final docRef = await _firestore.collection('survey_questions').add(data);

    // Add choices if any
    for (int i = 0; i < choices.length; i++) {
      await _firestore.collection('survey_choices').add({
        'question_id': docRef.id,
        'choice_text': choices[i],
        'choice_order': i,
        'created_at': FieldValue.serverTimestamp(),
      });
    }

    // Auto-sync survey count
    await _updateQuestionsCount(question.surveyId);
  }

  Future<void> deleteQuestion(String surveyId, String questionId) async {
    await _firestore.collection('survey_questions').doc(questionId).delete();

    // Cleanup choices
    final choicesSnapshot = await _firestore
        .collection('survey_choices')
        .where('question_id', isEqualTo: questionId)
        .get();
    for (var doc in choicesSnapshot.docs) {
      await doc.reference.delete();
    }

    // Auto-sync survey count
    await _updateQuestionsCount(surveyId);
  }

  // --- Choices ---

  Stream<List<SurveyChoice>> watchChoices(String questionId) {
    return _firestore
        .collection('survey_choices')
        .where('question_id', isEqualTo: questionId)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return SurveyChoice.fromJson(data);
          }).toList();
          docs.sort((a, b) => a.choiceOrder.compareTo(b.choiceOrder));
          return docs;
        });
  }

  // --- Stats ---

  Future<int> getTotalMembersCount() async {
    final query = await _firestore
        .collection('member')
        .where('account_status', isEqualTo: 'Active')
        .count()
        .get();
    return query.count ?? 0;
  }

  Future<void> generateMockData(String surveyId) async {
    // 1. Add Jane Doe member if not exists
    final membersQuery = await _firestore
        .collection('member')
        .where('name', isEqualTo: 'Jane Doe')
        .get();
    String memberId;
    if (membersQuery.docs.isEmpty) {
      final docRef = await _firestore.collection('member').add({
        'name': 'Jane Doe',
        'email': 'jane.doe@example.com',
        'account_status': 'Active',
        'created_at': FieldValue.serverTimestamp(),
      });
      memberId = docRef.id;
    } else {
      memberId = membersQuery.docs.first.id;
    }

    // 2. Check if response already exists
    final responseQuery = await _firestore
        .collection('survey_responses')
        .where('survey_id', isEqualTo: surveyId)
        .where('member_id', isEqualTo: memberId)
        .get();
    if (responseQuery.docs.isNotEmpty) return; // already mocked

    // 3. Get questions
    final questionsQuery = await _firestore
        .collection('survey_questions')
        .where('survey_id', isEqualTo: surveyId)
        .get();
    final questions = questionsQuery.docs;

    // 4. Create response
    final responseRef = await _firestore.collection('survey_responses').add({
      'survey_id': surveyId,
      'member_id': memberId,
      'member_name': 'Jane Doe',
      'submitted_at': FieldValue.serverTimestamp(),
    });

    // 5. Create answers
    for (var q in questions) {
      final qData = q.data();
      final qType = qData['type'];
      String answerText = '';

      if (qType == 'description') {
        answerText =
            'This is a sample description answer for testing. It has a few words to calculate average.';
      } else if (qType == 'yes_no') {
        answerText = 'Yes';
      } else if (qType == 'rating') {
        answerText = '5';
      } else if (qType == 'multiple_choice') {
        final choicesQuery = await _firestore
            .collection('survey_choices')
            .where('question_id', isEqualTo: q.id)
            .get();
        if (choicesQuery.docs.isNotEmpty) {
          answerText = choicesQuery.docs.first.data()['choice_text'];
        } else {
          answerText = 'Sample Choice';
        }
      }

      await _firestore.collection('survey_answers').add({
        'response_id': responseRef.id,
        'question_id': q.id,
        'answer': answerText,
      });
    }

    // 6. Update survey respondent count
    await _firestore.collection('surveys').doc(surveyId).update({
      'respondentsCount': FieldValue.increment(1),
    });
  }
}
