// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'survey.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Survey _$SurveyFromJson(Map<String, dynamic> json) => _Survey(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String? ?? '',
  status: json['status'] as String? ?? 'draft',
  questionsCount: (json['questionsCount'] as num?)?.toInt() ?? 0,
  respondentsCount: (json['respondentsCount'] as num?)?.toInt() ?? 0,
  startDate: const TimestampConverter().fromJson(json['start_date']),
  endDate: const TimestampConverter().fromJson(json['end_date']),
  createdAt: const TimestampConverter().fromJson(json['created_at']),
  createdByStaffId: json['created_by_staff_id'] as String?,
);

Map<String, dynamic> _$SurveyToJson(_Survey instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
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
      id: json['id'] as String,
      surveyId: json['survey_id'] as String,
      question: json['question'] as String,
      type: json['type'] as String,
      questionOrder: (json['question_order'] as num?)?.toInt() ?? 0,
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
      id: json['id'] as String,
      questionId: json['question_id'] as String,
      choiceText: json['choice_text'] as String,
      choiceOrder: (json['choice_order'] as num?)?.toInt() ?? 0,
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
