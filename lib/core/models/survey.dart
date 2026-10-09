import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'survey.freezed.dart';
part 'survey.g.dart';

class TimestampConverter implements JsonConverter<DateTime?, dynamic> {
  const TimestampConverter();

  @override
  DateTime? fromJson(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.tryParse(timestamp);
    if (timestamp is int) return DateTime.fromMillisecondsSinceEpoch(timestamp);
    return null;
  }

  @override
  dynamic toJson(DateTime? date) {
    return date == null ? null : Timestamp.fromDate(date);
  }
}

@freezed
abstract class Survey with _$Survey {
  const factory Survey({
    required String id,
    required String title,
    @Default('') String description,
    @Default('draft') String status, // 'draft', 'active', 'closed'
    @Default(0) int questionsCount,
    @Default(0) int respondentsCount,
    @TimestampConverter() @JsonKey(name: 'start_date') DateTime? startDate,
    @TimestampConverter() @JsonKey(name: 'end_date') DateTime? endDate,
    @TimestampConverter() @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'created_by_staff_id') String? createdByStaffId,
  }) = _Survey;

  factory Survey.fromJson(Map<String, dynamic> json) => _$SurveyFromJson(json);
}

@freezed
abstract class SurveyQuestion with _$SurveyQuestion {
  const factory SurveyQuestion({
    required String id,
    @JsonKey(name: 'survey_id') required String surveyId,
    required String question,
    required String type, // 'multiple_choice', 'text'
    @JsonKey(name: 'question_order') @Default(0) int questionOrder,
    @TimestampConverter() @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _SurveyQuestion;

  factory SurveyQuestion.fromJson(Map<String, dynamic> json) =>
      _$SurveyQuestionFromJson(json);
}

@freezed
abstract class SurveyChoice with _$SurveyChoice {
  const factory SurveyChoice({
    required String id,
    @JsonKey(name: 'question_id') required String questionId,
    @JsonKey(name: 'choice_text') required String choiceText,
    @JsonKey(name: 'choice_order') @Default(0) int choiceOrder,
    @TimestampConverter() @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _SurveyChoice;

  factory SurveyChoice.fromJson(Map<String, dynamic> json) =>
      _$SurveyChoiceFromJson(json);
}
