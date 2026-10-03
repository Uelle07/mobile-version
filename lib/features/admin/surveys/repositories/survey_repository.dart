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
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return Survey.fromJson(data);
            }).toList());
  }
  
  Stream<Survey> watchSurvey(String surveyId) {
    return _firestore
        .collection('surveys')
        .doc(surveyId)
        .snapshots()
        .map((doc) {
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

  Future<void> healSurveyCounts(String surveyId, int currentQuestionsCount, int currentRespondentsCount) async {
    final questionsQuery = await _firestore.collection('survey_questions').where('survey_id', isEqualTo: surveyId).count().get();
    final responsesQuery = await _firestore.collection('responses').where('survey_id', isEqualTo: surveyId).count().get();

    final trueQuestionsCount = questionsQuery.count ?? 0;
    final trueRespondentsCount = responsesQuery.count ?? 0;

    if (trueQuestionsCount != currentQuestionsCount || trueRespondentsCount != currentRespondentsCount) {
      await _firestore.collection('surveys').doc(surveyId).update({
        'questionsCount': trueQuestionsCount,
        'respondentsCount': trueRespondentsCount,
      });
    }
  }
  
  Future<void> _updateQuestionsCount(String surveyId) async {
    final questionsQuery = await _firestore.collection('survey_questions').where('survey_id', isEqualTo: surveyId).count().get();
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
        .orderBy('question_order')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return SurveyQuestion.fromJson(data);
            }).toList());
  }

  Future<void> addQuestion(SurveyQuestion question, List<String> choices) async {
    final data = question.toJson();
    data.remove('id');
    data['created_at'] = FieldValue.serverTimestamp();
    
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
    final choicesSnapshot = await _firestore.collection('survey_choices').where('question_id', isEqualTo: questionId).get();
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
        .orderBy('choice_order')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return SurveyChoice.fromJson(data);
            }).toList());
  }
  
  // --- Stats ---
  
  Future<int> getTotalMembersCount() async {
    final query = await _firestore.collection('members').count().get();
    return query.count ?? 0;
  }
}
