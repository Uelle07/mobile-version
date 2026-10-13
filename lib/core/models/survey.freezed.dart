// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'survey.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Survey {

 String get id; String get title; String get description; String get instructions; String get status; int get questionsCount; int get respondentsCount;@TimestampConverter()@JsonKey(name: 'start_date') DateTime? get startDate;@TimestampConverter()@JsonKey(name: 'end_date') DateTime? get endDate;@TimestampConverter()@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'created_by_staff_id') String? get createdByStaffId;
/// Create a copy of Survey
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SurveyCopyWith<Survey> get copyWith => _$SurveyCopyWithImpl<Survey>(this as Survey, _$identity);

  /// Serializes this Survey to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Survey&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.instructions, instructions) || other.instructions == instructions)&&(identical(other.status, status) || other.status == status)&&(identical(other.questionsCount, questionsCount) || other.questionsCount == questionsCount)&&(identical(other.respondentsCount, respondentsCount) || other.respondentsCount == respondentsCount)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdByStaffId, createdByStaffId) || other.createdByStaffId == createdByStaffId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,instructions,status,questionsCount,respondentsCount,startDate,endDate,createdAt,createdByStaffId);

@override
String toString() {
  return 'Survey(id: $id, title: $title, description: $description, instructions: $instructions, status: $status, questionsCount: $questionsCount, respondentsCount: $respondentsCount, startDate: $startDate, endDate: $endDate, createdAt: $createdAt, createdByStaffId: $createdByStaffId)';
}


}

/// @nodoc
abstract mixin class $SurveyCopyWith<$Res>  {
  factory $SurveyCopyWith(Survey value, $Res Function(Survey) _then) = _$SurveyCopyWithImpl;
@useResult
$Res call({
 String id, String title, String description, String instructions, String status, int questionsCount, int respondentsCount,@TimestampConverter()@JsonKey(name: 'start_date') DateTime? startDate,@TimestampConverter()@JsonKey(name: 'end_date') DateTime? endDate,@TimestampConverter()@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'created_by_staff_id') String? createdByStaffId
});




}
/// @nodoc
class _$SurveyCopyWithImpl<$Res>
    implements $SurveyCopyWith<$Res> {
  _$SurveyCopyWithImpl(this._self, this._then);

  final Survey _self;
  final $Res Function(Survey) _then;

/// Create a copy of Survey
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = null,Object? instructions = null,Object? status = null,Object? questionsCount = null,Object? respondentsCount = null,Object? startDate = freezed,Object? endDate = freezed,Object? createdAt = freezed,Object? createdByStaffId = freezed,}) {
  return _then(Survey(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,instructions: null == instructions ? _self.instructions : instructions // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,questionsCount: null == questionsCount ? _self.questionsCount : questionsCount // ignore: cast_nullable_to_non_nullable
as int,respondentsCount: null == respondentsCount ? _self.respondentsCount : respondentsCount // ignore: cast_nullable_to_non_nullable
as int,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdByStaffId: freezed == createdByStaffId ? _self.createdByStaffId : createdByStaffId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Survey].
extension SurveyPatterns on Survey {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Survey value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Survey() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Survey value)  $default,){
final _that = this;
switch (_that) {
case _Survey():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Survey value)?  $default,){
final _that = this;
switch (_that) {
case _Survey() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String description,  String instructions,  String status,  int questionsCount,  int respondentsCount, @TimestampConverter()@JsonKey(name: 'start_date')  DateTime? startDate, @TimestampConverter()@JsonKey(name: 'end_date')  DateTime? endDate, @TimestampConverter()@JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'created_by_staff_id')  String? createdByStaffId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Survey() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.instructions,_that.status,_that.questionsCount,_that.respondentsCount,_that.startDate,_that.endDate,_that.createdAt,_that.createdByStaffId);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String description,  String instructions,  String status,  int questionsCount,  int respondentsCount, @TimestampConverter()@JsonKey(name: 'start_date')  DateTime? startDate, @TimestampConverter()@JsonKey(name: 'end_date')  DateTime? endDate, @TimestampConverter()@JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'created_by_staff_id')  String? createdByStaffId)  $default,) {final _that = this;
switch (_that) {
case _Survey():
return $default(_that.id,_that.title,_that.description,_that.instructions,_that.status,_that.questionsCount,_that.respondentsCount,_that.startDate,_that.endDate,_that.createdAt,_that.createdByStaffId);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String description,  String instructions,  String status,  int questionsCount,  int respondentsCount, @TimestampConverter()@JsonKey(name: 'start_date')  DateTime? startDate, @TimestampConverter()@JsonKey(name: 'end_date')  DateTime? endDate, @TimestampConverter()@JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'created_by_staff_id')  String? createdByStaffId)?  $default,) {final _that = this;
switch (_that) {
case _Survey() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.instructions,_that.status,_that.questionsCount,_that.respondentsCount,_that.startDate,_that.endDate,_that.createdAt,_that.createdByStaffId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Survey implements Survey {
  const _Survey({required this.id, required this.title, this.description = '', this.instructions = '', this.status = 'draft', this.questionsCount = 0, this.respondentsCount = 0, @TimestampConverter()@JsonKey(name: 'start_date') this.startDate, @TimestampConverter()@JsonKey(name: 'end_date') this.endDate, @TimestampConverter()@JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'created_by_staff_id') this.createdByStaffId});
  factory _Survey.fromJson(Map<String, dynamic> json) => _$SurveyFromJson(json);

@override final  String id;
@override final  String title;
@override@JsonKey() final  String description;
@override@JsonKey() final  String instructions;
@override@JsonKey() final  String status;
@override@JsonKey() final  int questionsCount;
@override@JsonKey() final  int respondentsCount;
@override@TimestampConverter()@JsonKey(name: 'start_date') final  DateTime? startDate;
@override@TimestampConverter()@JsonKey(name: 'end_date') final  DateTime? endDate;
@override@TimestampConverter()@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'created_by_staff_id') final  String? createdByStaffId;

/// Create a copy of Survey
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SurveyCopyWith<_Survey> get copyWith => __$SurveyCopyWithImpl<_Survey>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SurveyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Survey&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.instructions, instructions) || other.instructions == instructions)&&(identical(other.status, status) || other.status == status)&&(identical(other.questionsCount, questionsCount) || other.questionsCount == questionsCount)&&(identical(other.respondentsCount, respondentsCount) || other.respondentsCount == respondentsCount)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdByStaffId, createdByStaffId) || other.createdByStaffId == createdByStaffId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,instructions,status,questionsCount,respondentsCount,startDate,endDate,createdAt,createdByStaffId);

@override
String toString() {
  return 'Survey(id: $id, title: $title, description: $description, instructions: $instructions, status: $status, questionsCount: $questionsCount, respondentsCount: $respondentsCount, startDate: $startDate, endDate: $endDate, createdAt: $createdAt, createdByStaffId: $createdByStaffId)';
}


}

/// @nodoc
abstract mixin class _$SurveyCopyWith<$Res> implements $SurveyCopyWith<$Res> {
  factory _$SurveyCopyWith(_Survey value, $Res Function(_Survey) _then) = __$SurveyCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String description, String instructions, String status, int questionsCount, int respondentsCount,@TimestampConverter()@JsonKey(name: 'start_date') DateTime? startDate,@TimestampConverter()@JsonKey(name: 'end_date') DateTime? endDate,@TimestampConverter()@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'created_by_staff_id') String? createdByStaffId
});




}
/// @nodoc
class __$SurveyCopyWithImpl<$Res>
    implements _$SurveyCopyWith<$Res> {
  __$SurveyCopyWithImpl(this._self, this._then);

  final _Survey _self;
  final $Res Function(_Survey) _then;

/// Create a copy of Survey
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = null,Object? instructions = null,Object? status = null,Object? questionsCount = null,Object? respondentsCount = null,Object? startDate = freezed,Object? endDate = freezed,Object? createdAt = freezed,Object? createdByStaffId = freezed,}) {
  return _then(_Survey(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,instructions: null == instructions ? _self.instructions : instructions // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,questionsCount: null == questionsCount ? _self.questionsCount : questionsCount // ignore: cast_nullable_to_non_nullable
as int,respondentsCount: null == respondentsCount ? _self.respondentsCount : respondentsCount // ignore: cast_nullable_to_non_nullable
as int,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdByStaffId: freezed == createdByStaffId ? _self.createdByStaffId : createdByStaffId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$SurveyQuestion {

 String get id;@JsonKey(name: 'survey_id') String get surveyId; String get question; String get type;@JsonKey(name: 'question_order') int get questionOrder;@TimestampConverter()@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of SurveyQuestion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SurveyQuestionCopyWith<SurveyQuestion> get copyWith => _$SurveyQuestionCopyWithImpl<SurveyQuestion>(this as SurveyQuestion, _$identity);

  /// Serializes this SurveyQuestion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SurveyQuestion&&(identical(other.id, id) || other.id == id)&&(identical(other.surveyId, surveyId) || other.surveyId == surveyId)&&(identical(other.question, question) || other.question == question)&&(identical(other.type, type) || other.type == type)&&(identical(other.questionOrder, questionOrder) || other.questionOrder == questionOrder)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,surveyId,question,type,questionOrder,createdAt);

@override
String toString() {
  return 'SurveyQuestion(id: $id, surveyId: $surveyId, question: $question, type: $type, questionOrder: $questionOrder, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $SurveyQuestionCopyWith<$Res>  {
  factory $SurveyQuestionCopyWith(SurveyQuestion value, $Res Function(SurveyQuestion) _then) = _$SurveyQuestionCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'survey_id') String surveyId, String question, String type,@JsonKey(name: 'question_order') int questionOrder,@TimestampConverter()@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class _$SurveyQuestionCopyWithImpl<$Res>
    implements $SurveyQuestionCopyWith<$Res> {
  _$SurveyQuestionCopyWithImpl(this._self, this._then);

  final SurveyQuestion _self;
  final $Res Function(SurveyQuestion) _then;

/// Create a copy of SurveyQuestion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? surveyId = null,Object? question = null,Object? type = null,Object? questionOrder = null,Object? createdAt = freezed,}) {
  return _then(SurveyQuestion(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,surveyId: null == surveyId ? _self.surveyId : surveyId // ignore: cast_nullable_to_non_nullable
as String,question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,questionOrder: null == questionOrder ? _self.questionOrder : questionOrder // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [SurveyQuestion].
extension SurveyQuestionPatterns on SurveyQuestion {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SurveyQuestion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SurveyQuestion() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SurveyQuestion value)  $default,){
final _that = this;
switch (_that) {
case _SurveyQuestion():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SurveyQuestion value)?  $default,){
final _that = this;
switch (_that) {
case _SurveyQuestion() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'survey_id')  String surveyId,  String question,  String type, @JsonKey(name: 'question_order')  int questionOrder, @TimestampConverter()@JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SurveyQuestion() when $default != null:
return $default(_that.id,_that.surveyId,_that.question,_that.type,_that.questionOrder,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'survey_id')  String surveyId,  String question,  String type, @JsonKey(name: 'question_order')  int questionOrder, @TimestampConverter()@JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _SurveyQuestion():
return $default(_that.id,_that.surveyId,_that.question,_that.type,_that.questionOrder,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'survey_id')  String surveyId,  String question,  String type, @JsonKey(name: 'question_order')  int questionOrder, @TimestampConverter()@JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _SurveyQuestion() when $default != null:
return $default(_that.id,_that.surveyId,_that.question,_that.type,_that.questionOrder,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SurveyQuestion implements SurveyQuestion {
  const _SurveyQuestion({required this.id, @JsonKey(name: 'survey_id') required this.surveyId, required this.question, required this.type, @JsonKey(name: 'question_order') this.questionOrder = 0, @TimestampConverter()@JsonKey(name: 'created_at') this.createdAt});
  factory _SurveyQuestion.fromJson(Map<String, dynamic> json) => _$SurveyQuestionFromJson(json);

@override final  String id;
@override@JsonKey(name: 'survey_id') final  String surveyId;
@override final  String question;
@override final  String type;
@override@JsonKey(name: 'question_order') final  int questionOrder;
@override@TimestampConverter()@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of SurveyQuestion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SurveyQuestionCopyWith<_SurveyQuestion> get copyWith => __$SurveyQuestionCopyWithImpl<_SurveyQuestion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SurveyQuestionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SurveyQuestion&&(identical(other.id, id) || other.id == id)&&(identical(other.surveyId, surveyId) || other.surveyId == surveyId)&&(identical(other.question, question) || other.question == question)&&(identical(other.type, type) || other.type == type)&&(identical(other.questionOrder, questionOrder) || other.questionOrder == questionOrder)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,surveyId,question,type,questionOrder,createdAt);

@override
String toString() {
  return 'SurveyQuestion(id: $id, surveyId: $surveyId, question: $question, type: $type, questionOrder: $questionOrder, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$SurveyQuestionCopyWith<$Res> implements $SurveyQuestionCopyWith<$Res> {
  factory _$SurveyQuestionCopyWith(_SurveyQuestion value, $Res Function(_SurveyQuestion) _then) = __$SurveyQuestionCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'survey_id') String surveyId, String question, String type,@JsonKey(name: 'question_order') int questionOrder,@TimestampConverter()@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class __$SurveyQuestionCopyWithImpl<$Res>
    implements _$SurveyQuestionCopyWith<$Res> {
  __$SurveyQuestionCopyWithImpl(this._self, this._then);

  final _SurveyQuestion _self;
  final $Res Function(_SurveyQuestion) _then;

/// Create a copy of SurveyQuestion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? surveyId = null,Object? question = null,Object? type = null,Object? questionOrder = null,Object? createdAt = freezed,}) {
  return _then(_SurveyQuestion(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,surveyId: null == surveyId ? _self.surveyId : surveyId // ignore: cast_nullable_to_non_nullable
as String,question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,questionOrder: null == questionOrder ? _self.questionOrder : questionOrder // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$SurveyChoice {

 String get id;@JsonKey(name: 'question_id') String get questionId;@JsonKey(name: 'choice_text') String get choiceText;@JsonKey(name: 'choice_order') int get choiceOrder;@TimestampConverter()@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of SurveyChoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SurveyChoiceCopyWith<SurveyChoice> get copyWith => _$SurveyChoiceCopyWithImpl<SurveyChoice>(this as SurveyChoice, _$identity);

  /// Serializes this SurveyChoice to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SurveyChoice&&(identical(other.id, id) || other.id == id)&&(identical(other.questionId, questionId) || other.questionId == questionId)&&(identical(other.choiceText, choiceText) || other.choiceText == choiceText)&&(identical(other.choiceOrder, choiceOrder) || other.choiceOrder == choiceOrder)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,questionId,choiceText,choiceOrder,createdAt);

@override
String toString() {
  return 'SurveyChoice(id: $id, questionId: $questionId, choiceText: $choiceText, choiceOrder: $choiceOrder, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $SurveyChoiceCopyWith<$Res>  {
  factory $SurveyChoiceCopyWith(SurveyChoice value, $Res Function(SurveyChoice) _then) = _$SurveyChoiceCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'question_id') String questionId,@JsonKey(name: 'choice_text') String choiceText,@JsonKey(name: 'choice_order') int choiceOrder,@TimestampConverter()@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class _$SurveyChoiceCopyWithImpl<$Res>
    implements $SurveyChoiceCopyWith<$Res> {
  _$SurveyChoiceCopyWithImpl(this._self, this._then);

  final SurveyChoice _self;
  final $Res Function(SurveyChoice) _then;

/// Create a copy of SurveyChoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? questionId = null,Object? choiceText = null,Object? choiceOrder = null,Object? createdAt = freezed,}) {
  return _then(SurveyChoice(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,questionId: null == questionId ? _self.questionId : questionId // ignore: cast_nullable_to_non_nullable
as String,choiceText: null == choiceText ? _self.choiceText : choiceText // ignore: cast_nullable_to_non_nullable
as String,choiceOrder: null == choiceOrder ? _self.choiceOrder : choiceOrder // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [SurveyChoice].
extension SurveyChoicePatterns on SurveyChoice {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SurveyChoice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SurveyChoice() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SurveyChoice value)  $default,){
final _that = this;
switch (_that) {
case _SurveyChoice():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SurveyChoice value)?  $default,){
final _that = this;
switch (_that) {
case _SurveyChoice() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'question_id')  String questionId, @JsonKey(name: 'choice_text')  String choiceText, @JsonKey(name: 'choice_order')  int choiceOrder, @TimestampConverter()@JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SurveyChoice() when $default != null:
return $default(_that.id,_that.questionId,_that.choiceText,_that.choiceOrder,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'question_id')  String questionId, @JsonKey(name: 'choice_text')  String choiceText, @JsonKey(name: 'choice_order')  int choiceOrder, @TimestampConverter()@JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _SurveyChoice():
return $default(_that.id,_that.questionId,_that.choiceText,_that.choiceOrder,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'question_id')  String questionId, @JsonKey(name: 'choice_text')  String choiceText, @JsonKey(name: 'choice_order')  int choiceOrder, @TimestampConverter()@JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _SurveyChoice() when $default != null:
return $default(_that.id,_that.questionId,_that.choiceText,_that.choiceOrder,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SurveyChoice implements SurveyChoice {
  const _SurveyChoice({required this.id, @JsonKey(name: 'question_id') required this.questionId, @JsonKey(name: 'choice_text') required this.choiceText, @JsonKey(name: 'choice_order') this.choiceOrder = 0, @TimestampConverter()@JsonKey(name: 'created_at') this.createdAt});
  factory _SurveyChoice.fromJson(Map<String, dynamic> json) => _$SurveyChoiceFromJson(json);

@override final  String id;
@override@JsonKey(name: 'question_id') final  String questionId;
@override@JsonKey(name: 'choice_text') final  String choiceText;
@override@JsonKey(name: 'choice_order') final  int choiceOrder;
@override@TimestampConverter()@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of SurveyChoice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SurveyChoiceCopyWith<_SurveyChoice> get copyWith => __$SurveyChoiceCopyWithImpl<_SurveyChoice>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SurveyChoiceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SurveyChoice&&(identical(other.id, id) || other.id == id)&&(identical(other.questionId, questionId) || other.questionId == questionId)&&(identical(other.choiceText, choiceText) || other.choiceText == choiceText)&&(identical(other.choiceOrder, choiceOrder) || other.choiceOrder == choiceOrder)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,questionId,choiceText,choiceOrder,createdAt);

@override
String toString() {
  return 'SurveyChoice(id: $id, questionId: $questionId, choiceText: $choiceText, choiceOrder: $choiceOrder, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$SurveyChoiceCopyWith<$Res> implements $SurveyChoiceCopyWith<$Res> {
  factory _$SurveyChoiceCopyWith(_SurveyChoice value, $Res Function(_SurveyChoice) _then) = __$SurveyChoiceCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'question_id') String questionId,@JsonKey(name: 'choice_text') String choiceText,@JsonKey(name: 'choice_order') int choiceOrder,@TimestampConverter()@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class __$SurveyChoiceCopyWithImpl<$Res>
    implements _$SurveyChoiceCopyWith<$Res> {
  __$SurveyChoiceCopyWithImpl(this._self, this._then);

  final _SurveyChoice _self;
  final $Res Function(_SurveyChoice) _then;

/// Create a copy of SurveyChoice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? questionId = null,Object? choiceText = null,Object? choiceOrder = null,Object? createdAt = freezed,}) {
  return _then(_SurveyChoice(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,questionId: null == questionId ? _self.questionId : questionId // ignore: cast_nullable_to_non_nullable
as String,choiceText: null == choiceText ? _self.choiceText : choiceText // ignore: cast_nullable_to_non_nullable
as String,choiceOrder: null == choiceOrder ? _self.choiceOrder : choiceOrder // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
