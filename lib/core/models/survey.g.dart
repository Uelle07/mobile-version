// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'survey.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

int _parseSafeInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
}

_Survey _$SurveyFromJson(Map<String, dynamic> json) => _Survey(
  id: (json['id'] ?? '').toString(),
  title: (json['title'] ?? '').toString(),
  description: (json['description'] ?? '').toString(),
  instructions: (json['instructions'] ?? '').toString(),
  status: (json['status'] ?? 'draft').toString(),
  questionsCount: _parseSafeInt(
    json['questionsCount'] ?? json['questions_count'],
  ),
  respondentsCount: _parseSafeInt(
    json['respondentsCount'] ?? json['respondents_count'],
  ),
  startDate: const TimestampConverter().fromJson(json['start_date']),
  endDate: const TimestampConverter().fromJson(json['end_date']),
  createdAt: const TimestampConverter().fromJson(json['created_at']),
  createdByStaffId: json['created_by_staff_id']?.toString(),
);

Map<String, dynamic> _$SurveyToJson(_Survey instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'instructions': instance.instructions,
  'status': instance.status,
  'questionsCount': instance.questionsCount,
  'respondentsCount': instance.respondentsCount,
  'start_date': const TimestampConverter().toJson(instance.startDate),
  'end_date': const TimestampConverter().toJson(instance.endDate),
  'created_at': const TimestampConverter().toJson(instance.createdAt),
  'created_by_staff_id': instance.createdByStaffId,
};

_SurveyQuestion _$SurveyQuestionFromJson(Map<String, dynamic> json) =>
    _SurveyQuestion(
      id: (json['id'] ?? '').toString(),
      surveyId: (json['survey_id'] ?? '').toString(),
      question: (json['question'] ?? json['question_text'] ?? '').toString(),
      type: (json['type'] ?? json['question_type'] ?? 'short_answer').toString(),
      questionOrder: _parseSafeInt(json['question_order']),
      createdAt: const TimestampConverter().fromJson(json['created_at']),
    );

Map<String, dynamic> _$SurveyQuestionToJson(_SurveyQuestion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'survey_id': instance.surveyId,
      'question': instance.question,
      'type': instance.type,
      'question_order': instance.questionOrder,
      'created_at': const TimestampConverter().toJson(instance.createdAt),
    };

_SurveyChoice _$SurveyChoiceFromJson(Map<String, dynamic> json) =>
    _SurveyChoice(
      id: (json['id'] ?? '').toString(),
      questionId: (json['question_id'] ?? '').toString(),
      choiceText:
          (json['choice_text'] ?? json['choice'] ?? json['text'] ?? '')
              .toString(),
      choiceOrder: _parseSafeInt(json['choice_order']),
      createdAt: const TimestampConverter().fromJson(json['created_at']),
    );

Map<String, dynamic> _$SurveyChoiceToJson(_SurveyChoice instance) =>
    <String, dynamic>{
      'id': instance.id,
      'question_id': instance.questionId,
      'choice_text': instance.choiceText,
      'choice_order': instance.choiceOrder,
      'created_at': const TimestampConverter().toJson(instance.createdAt),
    };
