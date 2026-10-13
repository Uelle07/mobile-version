import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cooperative_member_app/core/models/survey.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final surveyRepositoryProvider = Provider<SurveyRepository>((ref) {
  return SurveyRepository(FirebaseFirestore.instance);
});

class MemberSurveySubmission {
  final String surveyId;
  final DateTime submittedAt;
  final String rawSubmittedAt;
  final int answeredCount;

  const MemberSurveySubmission({
    required this.surveyId,
    required this.submittedAt,
    required this.rawSubmittedAt,
    required this.answeredCount,
  });
}

class SubmittedQuestionAnswer {
  final String questionId;
  final String? choiceId;
  final String answer;

  const SubmittedQuestionAnswer({
    required this.questionId,
    this.choiceId,
    required this.answer,
  });
}

class SurveyQuestionnaireBundle {
  final Survey survey;
  final List<SurveyQuestion> questions;
  final Map<String, List<SurveyChoice>> choicesByQuestion;

  const SurveyQuestionnaireBundle({
    required this.survey,
    required this.questions,
    required this.choicesByQuestion,
  });
}

class SurveyReceiptData {
  final String surveyId;
  final String surveyTitle;
  final int completedItemsCount;
  final DateTime submittedAt;

  const SurveyReceiptData({
    required this.surveyId,
    required this.surveyTitle,
    required this.completedItemsCount,
    required this.submittedAt,
  });
}

class SurveyRepository {
  final FirebaseFirestore _firestore;

  SurveyRepository(this._firestore);

  static DateTime? parseFlexibleDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return null;
      return DateTime.tryParse(trimmed)?.toLocal();
    }
    return null;
  }

  // --- Surveys ---

  Stream<List<Survey>> watchSurveys() {
    return _firestore.collection('surveys').snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return Survey.fromJson(data);
      }).toList();
      list.sort((a, b) {
        final dateA =
            a.createdAt ?? a.startDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB =
            b.createdAt ?? b.startDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });
      return list;
    });
  }

  Stream<Survey> watchSurvey(String surveyId) {
    return _firestore.collection('surveys').doc(surveyId).snapshots().map((
      doc,
    ) {
      final data = Map<String, dynamic>.from(doc.data() ?? {});
      data['id'] = doc.id;
      return Survey.fromJson(data);
    });
  }

  Future<Survey?> getSurveyOnce(String surveyId) async {
    final doc = await _firestore.collection('surveys').doc(surveyId).get();
    if (!doc.exists || doc.data() == null) return null;
    final data = Map<String, dynamic>.from(doc.data()!);
    data['id'] = doc.id;
    return Survey.fromJson(data);
  }

  Stream<Map<String, int>> watchQuestionCountsBySurvey() {
    return _firestore.collection('survey_questions').snapshots().map((snap) {
      final counts = <String, int>{};
      for (final doc in snap.docs) {
        final sId = (doc.data()['survey_id'] ?? '').toString();
        if (sId.isNotEmpty) {
          counts[sId] = (counts[sId] ?? 0) + 1;
        }
      }
      return counts;
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
    final responsesSnap = await _firestore
        .collection('responses')
        .where('survey_id', isEqualTo: surveyId)
        .get();

    final uniqueMembers = <String>{};
    for (final doc in responsesSnap.docs) {
      final mId = (doc.data()['member_id'] ?? '').toString();
      if (mId.isNotEmpty) uniqueMembers.add(mId);
    }
    if (uniqueMembers.isEmpty) {
      final fallbackSnap = await _firestore
          .collection('survey_responses')
          .where('survey_id', isEqualTo: surveyId)
          .get();
      for (final doc in fallbackSnap.docs) {
        final mId = (doc.data()['member_id'] ?? '').toString();
        if (mId.isNotEmpty) uniqueMembers.add(mId);
      }
    }

    final trueQuestionsCount = questionsQuery.count ?? 0;
    final trueRespondentsCount = uniqueMembers.isNotEmpty
        ? uniqueMembers.length
        : currentRespondentsCount;

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
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            data['id'] = doc.id;
            return SurveyQuestion.fromJson(data);
          }).toList();
          list.sort(
            (a, b) => a.questionOrder.compareTo(b.questionOrder),
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
        'survey_id': question.surveyId,
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
            final data = Map<String, dynamic>.from(doc.data());
            data['id'] = doc.id;
            return SurveyChoice.fromJson(data);
          }).toList();
          docs.sort((a, b) => a.choiceOrder.compareTo(b.choiceOrder));
          return docs;
        });
  }

  // --- Member Survey Flows ---

  /// Streams all unique survey submissions for the given member ID(s),
  /// sorted descending by submission timestamp.
  Stream<List<MemberSurveySubmission>> watchMemberSubmissions(
    List<String> memberIds,
  ) {
    final validIds = memberIds
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    if (validIds.isEmpty) {
      return Stream.value(const []);
    }

    return _firestore
        .collection('responses')
        .where('member_id', whereIn: validIds)
        .snapshots()
        .asyncMap((responsesSnap) async {
          final Map<String, DateTime> latestDateBySurvey = {};
          final Map<String, String> rawDateBySurvey = {};
          final Map<String, int> countBySurvey = {};

          void recordDoc(Map<String, dynamic> data) {
            final sId = (data['survey_id'] ?? '').toString().trim();
            if (sId.isEmpty) return;
            final rawSub = data['submitted_at'];
            final parsed =
                parseFlexibleDateTime(rawSub) ??
                DateTime.fromMillisecondsSinceEpoch(0);
            countBySurvey[sId] = (countBySurvey[sId] ?? 0) + 1;
            final existing = latestDateBySurvey[sId];
            if (existing == null || parsed.isAfter(existing)) {
              latestDateBySurvey[sId] = parsed;
              rawDateBySurvey[sId] = rawSub?.toString() ?? parsed.toIso8601String();
            }
          }

          for (final doc in responsesSnap.docs) {
            recordDoc(doc.data());
          }

          // Also check legacy survey_responses collection as fallback
          try {
            final legacySnap = await _firestore
                .collection('survey_responses')
                .where('member_id', whereIn: validIds)
                .get();
            for (final doc in legacySnap.docs) {
              final data = doc.data();
              final sId = (data['survey_id'] ?? '').toString().trim();
              if (sId.isNotEmpty && !latestDateBySurvey.containsKey(sId)) {
                recordDoc(data);
              }
            }
          } catch (_) {}

          final submissions = latestDateBySurvey.keys.map((sId) {
            return MemberSurveySubmission(
              surveyId: sId,
              submittedAt: latestDateBySurvey[sId]!,
              rawSubmittedAt: rawDateBySurvey[sId] ?? '',
              answeredCount: countBySurvey[sId] ?? 1,
            );
          }).toList();

          submissions.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
          return submissions;
        });
  }

  /// Pre-flight duplicate submission check on `responses` collection.
  Future<bool> hasMemberSubmittedSurvey(
    String surveyId,
    List<String> memberIds,
  ) async {
    final validIds = memberIds
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    if (validIds.isEmpty) return false;

    final query = await _firestore
        .collection('responses')
        .where('survey_id', isEqualTo: surveyId)
        .where('member_id', whereIn: validIds)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) return true;

    final fallbackQuery = await _firestore
        .collection('survey_responses')
        .where('survey_id', isEqualTo: surveyId)
        .where('member_id', whereIn: validIds)
        .limit(1)
        .get();
    return fallbackQuery.docs.isNotEmpty;
  }

  /// Fetches questions and choices for a survey (matching `survey_id` on `survey_choices`
  /// with fallback matching `question_id`), sorted ascending by order.
  Future<SurveyQuestionnaireBundle?> fetchSurveyQuestionnaireBundle(
    String surveyId,
  ) async {
    final survey = await getSurveyOnce(surveyId);
    if (survey == null) return null;

    final qSnap = await _firestore
        .collection('survey_questions')
        .where('survey_id', isEqualTo: surveyId)
        .get();
    final questions = qSnap.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] = doc.id;
      return SurveyQuestion.fromJson(data);
    }).toList();
    questions.sort((a, b) => a.questionOrder.compareTo(b.questionOrder));

    final Map<String, List<SurveyChoice>> choicesByQuestion = {
      for (final q in questions) q.id: <SurveyChoice>[],
    };
    final Set<String> seenChoiceIds = {};

    // 1. Primary query: survey_choices where survey_id == surveyId
    try {
      final bySurveySnap = await _firestore
          .collection('survey_choices')
          .where('survey_id', isEqualTo: surveyId)
          .get();
      for (final doc in bySurveySnap.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        final choice = SurveyChoice.fromJson(data);
        if (choice.questionId.isNotEmpty &&
            choicesByQuestion.containsKey(choice.questionId)) {
          if (seenChoiceIds.add(choice.id)) {
            choicesByQuestion[choice.questionId]!.add(choice);
          }
        }
      }
    } catch (_) {}

    // 2. Fallback query: for any question missing choices, query by question_id
    for (final q in questions) {
      if (choicesByQuestion[q.id]?.isEmpty ?? true) {
        try {
          final byQuestionSnap = await _firestore
              .collection('survey_choices')
              .where('question_id', isEqualTo: q.id)
              .get();
          for (final doc in byQuestionSnap.docs) {
            final data = Map<String, dynamic>.from(doc.data());
            data['id'] = doc.id;
            final choice = SurveyChoice.fromJson(data);
            if (seenChoiceIds.add(choice.id)) {
              choicesByQuestion[q.id]!.add(choice);
            }
          }
        } catch (_) {}
      }
      choicesByQuestion[q.id]!.sort(
        (a, b) => a.choiceOrder.compareTo(b.choiceOrder),
      );
    }

    return SurveyQuestionnaireBundle(
      survey: survey,
      questions: questions,
      choicesByQuestion: choicesByQuestion,
    );
  }

  /// Submits a member's questionnaire responses and syncs `responses`,
  /// `survey_results`, and `surveys/{surveyId}.respondentsCount`.
  Future<SurveyReceiptData> submitMemberQuestionnaire({
    required Survey survey,
    required String memberId,
    required List<String> allMemberIds,
    required String memberName,
    required List<SubmittedQuestionAnswer> answers,
  }) async {
    final alreadySubmitted = await hasMemberSubmittedSurvey(
      survey.id,
      allMemberIds.isNotEmpty ? allMemberIds : [memberId],
    );
    if (alreadySubmitted) {
      throw Exception(
        'You have already submitted your response for this survey. Thank you!',
      );
    }

    final now = DateTime.now();
    final submittedAtIso = now.toUtc().toIso8601String();

    // 1. Insert each question's response into `responses` collection
    for (final item in answers) {
      await _firestore.collection('responses').add({
        'survey_id': survey.id,
        'question_id': item.questionId,
        'member_id': memberId,
        'choice_id': item.choiceId,
        'answer': item.answer,
        'submitted_at': submittedAtIso,
      });
    }

    // Also record in `survey_responses` and `survey_answers` so Flutter Admin stays synced
    try {
      final responseRef = await _firestore.collection('survey_responses').add({
        'survey_id': survey.id,
        'member_id': memberId,
        'member_name': memberName,
        'submitted_at': FieldValue.serverTimestamp(),
      });
      for (final item in answers) {
        await _firestore.collection('survey_answers').add({
          'response_id': responseRef.id,
          'question_id': item.questionId,
          'choice_id': item.choiceId,
          'answer': item.answer,
        });
      }
    } catch (_) {}

    // 2. Update Aggregated Choice Counts (`survey_results` collection)
    for (final item in answers) {
      if (item.choiceId != null && item.choiceId!.isNotEmpty) {
        final qResponsesSnap = await _firestore
            .collection('responses')
            .where('question_id', isEqualTo: item.questionId)
            .get();
        final totalQuestionResponses = qResponsesSnap.docs.length;

        // Calculate counts for all choices on this question and specifically the selected choiceId
        final Map<String, int> countsByChoiceId = {};
        for (final doc in qResponsesSnap.docs) {
          final cId = doc.data()['choice_id']?.toString();
          if (cId != null && cId.isNotEmpty) {
            countsByChoiceId[cId] = (countsByChoiceId[cId] ?? 0) + 1;
          }
        }
        // Ensure the selected choiceId is always updated even if 0
        countsByChoiceId.putIfAbsent(item.choiceId!, () => 1);

        for (final entry in countsByChoiceId.entries) {
          final cId = entry.key;
          final choiceCount = entry.value;
          final double percentage = totalQuestionResponses > 0
              ? (choiceCount / totalQuestionResponses) * 100.0
              : 0.0;

          await _firestore
              .collection('survey_results')
              .doc('${survey.id}_${item.questionId}_$cId')
              .set({
                'survey_id': survey.id,
                'question_id': item.questionId,
                'choice_id': cId,
                'response_count': choiceCount,
                'percentage': percentage,
              }, SetOptions(merge: true));
        }
      }
    }

    // 3. Update Respondents Count (`surveys/{surveyId}`)
    final allSurveyResponsesSnap = await _firestore
        .collection('responses')
        .where('survey_id', isEqualTo: survey.id)
        .get();
    final uniqueMembers = <String>{};
    for (final doc in allSurveyResponsesSnap.docs) {
      final mId = (doc.data()['member_id'] ?? '').toString().trim();
      if (mId.isNotEmpty) {
        uniqueMembers.add(mId);
      }
    }
    final uniqueMembersCount = uniqueMembers.isNotEmpty
        ? uniqueMembers.length
        : 1;

    await _firestore.collection('surveys').doc(survey.id).set({
      'respondentsCount': uniqueMembersCount,
    }, SetOptions(merge: true));

    return SurveyReceiptData(
      surveyId: survey.id,
      surveyTitle: survey.title,
      completedItemsCount: answers.length,
      submittedAt: now,
    );
  }

  /// Fetches receipt details for Screen 3 (`survey_success.php`) if navigated directly by ID.
  Future<SurveyReceiptData?> fetchSurveyReceiptData(
    String surveyId,
    List<String> memberIds,
  ) async {
    final survey = await getSurveyOnce(surveyId);
    final validIds = memberIds
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    DateTime submittedAt = DateTime.now();
    int completedCount = survey?.questionsCount ?? 0;

    if (validIds.isNotEmpty) {
      final respSnap = await _firestore
          .collection('responses')
          .where('survey_id', isEqualTo: surveyId)
          .where('member_id', whereIn: validIds)
          .get();
      if (respSnap.docs.isNotEmpty) {
        completedCount = respSnap.docs.length;
        for (final doc in respSnap.docs) {
          final dt = parseFlexibleDateTime(doc.data()['submitted_at']);
          if (dt != null) {
            submittedAt = dt;
            break;
          }
        }
      }
    }

    if (completedCount == 0) {
      final qCountSnap = await _firestore
          .collection('survey_questions')
          .where('survey_id', isEqualTo: surveyId)
          .count()
          .get();
      completedCount = qCountSnap.count ?? 0;
    }

    return SurveyReceiptData(
      surveyId: surveyId,
      surveyTitle: survey?.title ?? 'Cooperative Survey',
      completedItemsCount: completedCount,
      submittedAt: submittedAt,
    );
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

  Future<void> submitSurveyResponse({
    required String surveyId,
    required String memberId,
    required String memberName,
    required Map<String, String> answers, // questionId -> answer text
  }) async {
    final survey =
        await getSurveyOnce(surveyId) ??
        Survey(id: surveyId, title: 'Cooperative Survey');
    final itemList = answers.entries
        .map(
          (e) => SubmittedQuestionAnswer(
            questionId: e.key,
            choiceId: null,
            answer: e.value,
          ),
        )
        .toList();
    await submitMemberQuestionnaire(
      survey: survey,
      memberId: memberId,
      allMemberIds: [memberId],
      memberName: memberName,
      answers: itemList,
    );
  }
}
