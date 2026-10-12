import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/models/survey.dart';
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
