import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/models/survey.dart';
import '../../../member/dashboard/providers/current_member_provider.dart';
import '../repositories/survey_repository.dart';

part 'survey_provider.g.dart';

@riverpod
Stream<List<Survey>> surveys(Ref ref) {
  final repository = ref.watch(surveyRepositoryProvider);
  return repository.watchSurveys();
}

@riverpod
Stream<List<SurveyQuestion>> surveyQuestions(Ref ref, String surveyId) {
  final repository = ref.watch(surveyRepositoryProvider);
  return repository.watchQuestions(surveyId);
}

@riverpod
Stream<List<SurveyChoice>> surveyChoices(Ref ref, String questionId) {
  final repository = ref.watch(surveyRepositoryProvider);
  return repository.watchChoices(questionId);
}

final surveyQuestionCountsProvider = StreamProvider<Map<String, int>>((ref) {
  final repository = ref.watch(surveyRepositoryProvider);
  return repository.watchQuestionCountsBySurvey();
});

final memberSubmissionsProvider = StreamProvider<List<MemberSurveySubmission>>((
  ref,
) {
  final repository = ref.watch(surveyRepositoryProvider);
  final member = ref.watch(currentMemberProvider).value;
  final currentUid = FirebaseAuth.instance.currentUser?.uid;
  final ids = <String>[
    if (currentUid != null && currentUid.isNotEmpty) currentUid,
    if (member != null && member.id.isNotEmpty) member.id,
  ];
  return repository.watchMemberSubmissions(ids);
});
