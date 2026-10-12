// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'member.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Member {

 String get id;@JsonKey(name: 'account_number') String get accountNumber;@JsonKey(name: 'firstname') String get firstName;@JsonKey(name: 'lastname') String get lastName;@JsonKey(name: 'middlename') String? get middleName; String? get email;@JsonKey(name: 'contact_number') String? get phone;@JsonKey(name: 'passport_photo') String? get photoUrl;@JsonKey(name: 'signature_photo') String? get signatureUrl;@JsonKey(name: 'is_verified') bool get isVerified;@JsonKey(name: 'account_status') String get status;@JsonKey(name: 'civil_status') String? get civilStatus;@JsonKey(name: 'sex') String? get gender;@JsonKey(name: 'birthday', fromJson: _dateStringFromJson, toJson: _dateStringToJson) String? get dateOfBirth; String? get nationality;@JsonKey(name: 'address') String? get homeAddress; String? get occupation;@JsonKey(name: 'employer') String? get employerName;@JsonKey(name: 'employer_address') String? get employerAddress;@JsonKey(name: 'father_name') String? get fatherName;@JsonKey(name: 'mother_name') String? get motherName;@JsonKey(name: 'spouse_name') String? get spouseName;@JsonKey(name: 'spouse_occupation') String? get spouseOccupation;@JsonKey(name: 'spouse_employer') String? get spouseEmployer; List<dynamic>? get references;@JsonKey(name: 'created_at', fromJson: _dateTimeFromTimestamp, toJson: _dateTimeToTimestamp) DateTime? get registeredAt;
/// Create a copy of Member
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberCopyWith<Member> get copyWith => _$MemberCopyWithImpl<Member>(this as Member, _$identity);

  /// Serializes this Member to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Member&&(identical(other.id, id) || other.id == id)&&(identical(other.accountNumber, accountNumber) || other.accountNumber == accountNumber)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.middleName, middleName) || other.middleName == middleName)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.signatureUrl, signatureUrl) || other.signatureUrl == signatureUrl)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.status, status) || other.status == status)&&(identical(other.civilStatus, civilStatus) || other.civilStatus == civilStatus)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.nationality, nationality) || other.nationality == nationality)&&(identical(other.homeAddress, homeAddress) || other.homeAddress == homeAddress)&&(identical(other.occupation, occupation) || other.occupation == occupation)&&(identical(other.employerName, employerName) || other.employerName == employerName)&&(identical(other.employerAddress, employerAddress) || other.employerAddress == employerAddress)&&(identical(other.fatherName, fatherName) || other.fatherName == fatherName)&&(identical(other.motherName, motherName) || other.motherName == motherName)&&(identical(other.spouseName, spouseName) || other.spouseName == spouseName)&&(identical(other.spouseOccupation, spouseOccupation) || other.spouseOccupation == spouseOccupation)&&(identical(other.spouseEmployer, spouseEmployer) || other.spouseEmployer == spouseEmployer)&&const DeepCollectionEquality().equals(other.references, references)&&(identical(other.registeredAt, registeredAt) || other.registeredAt == registeredAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,accountNumber,firstName,lastName,middleName,email,phone,photoUrl,signatureUrl,isVerified,status,civilStatus,gender,dateOfBirth,nationality,homeAddress,occupation,employerName,employerAddress,fatherName,motherName,spouseName,spouseOccupation,spouseEmployer,const DeepCollectionEquality().hash(references),registeredAt]);

@override
String toString() {
  return 'Member(id: $id, accountNumber: $accountNumber, firstName: $firstName, lastName: $lastName, middleName: $middleName, email: $email, phone: $phone, photoUrl: $photoUrl, signatureUrl: $signatureUrl, isVerified: $isVerified, status: $status, civilStatus: $civilStatus, gender: $gender, dateOfBirth: $dateOfBirth, nationality: $nationality, homeAddress: $homeAddress, occupation: $occupation, employerName: $employerName, employerAddress: $employerAddress, fatherName: $fatherName, motherName: $motherName, spouseName: $spouseName, spouseOccupation: $spouseOccupation, spouseEmployer: $spouseEmployer, references: $references, registeredAt: $registeredAt)';
}


}

/// @nodoc
abstract mixin class $MemberCopyWith<$Res>  {
  factory $MemberCopyWith(Member value, $Res Function(Member) _then) = _$MemberCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'account_number') String accountNumber,@JsonKey(name: 'firstname') String firstName,@JsonKey(name: 'lastname') String lastName,@JsonKey(name: 'middlename') String? middleName, String? email,@JsonKey(name: 'contact_number') String? phone,@JsonKey(name: 'passport_photo') String? photoUrl,@JsonKey(name: 'signature_photo') String? signatureUrl,@JsonKey(name: 'is_verified') bool isVerified,@JsonKey(name: 'account_status') String status,@JsonKey(name: 'civil_status') String? civilStatus,@JsonKey(name: 'sex') String? gender,@JsonKey(name: 'birthday', fromJson: _dateStringFromJson, toJson: _dateStringToJson) String? dateOfBirth, String? nationality,@JsonKey(name: 'address') String? homeAddress, String? occupation,@JsonKey(name: 'employer') String? employerName,@JsonKey(name: 'employer_address') String? employerAddress,@JsonKey(name: 'father_name') String? fatherName,@JsonKey(name: 'mother_name') String? motherName,@JsonKey(name: 'spouse_name') String? spouseName,@JsonKey(name: 'spouse_occupation') String? spouseOccupation,@JsonKey(name: 'spouse_employer') String? spouseEmployer, List<dynamic>? references,@JsonKey(name: 'created_at', fromJson: _dateTimeFromTimestamp, toJson: _dateTimeToTimestamp) DateTime? registeredAt
});




}
/// @nodoc
class _$MemberCopyWithImpl<$Res>
    implements $MemberCopyWith<$Res> {
  _$MemberCopyWithImpl(this._self, this._then);

  final Member _self;
  final $Res Function(Member) _then;

/// Create a copy of Member
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? accountNumber = null,Object? firstName = null,Object? lastName = null,Object? middleName = freezed,Object? email = freezed,Object? phone = freezed,Object? photoUrl = freezed,Object? signatureUrl = freezed,Object? isVerified = null,Object? status = null,Object? civilStatus = freezed,Object? gender = freezed,Object? dateOfBirth = freezed,Object? nationality = freezed,Object? homeAddress = freezed,Object? occupation = freezed,Object? employerName = freezed,Object? employerAddress = freezed,Object? fatherName = freezed,Object? motherName = freezed,Object? spouseName = freezed,Object? spouseOccupation = freezed,Object? spouseEmployer = freezed,Object? references = freezed,Object? registeredAt = freezed,}) {
  return _then(Member(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,accountNumber: null == accountNumber ? _self.accountNumber : accountNumber // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,middleName: freezed == middleName ? _self.middleName : middleName // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,signatureUrl: freezed == signatureUrl ? _self.signatureUrl : signatureUrl // ignore: cast_nullable_to_non_nullable
as String?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,civilStatus: freezed == civilStatus ? _self.civilStatus : civilStatus // ignore: cast_nullable_to_non_nullable
as String?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as String?,nationality: freezed == nationality ? _self.nationality : nationality // ignore: cast_nullable_to_non_nullable
as String?,homeAddress: freezed == homeAddress ? _self.homeAddress : homeAddress // ignore: cast_nullable_to_non_nullable
as String?,occupation: freezed == occupation ? _self.occupation : occupation // ignore: cast_nullable_to_non_nullable
as String?,employerName: freezed == employerName ? _self.employerName : employerName // ignore: cast_nullable_to_non_nullable
as String?,employerAddress: freezed == employerAddress ? _self.employerAddress : employerAddress // ignore: cast_nullable_to_non_nullable
as String?,fatherName: freezed == fatherName ? _self.fatherName : fatherName // ignore: cast_nullable_to_non_nullable
as String?,motherName: freezed == motherName ? _self.motherName : motherName // ignore: cast_nullable_to_non_nullable
as String?,spouseName: freezed == spouseName ? _self.spouseName : spouseName // ignore: cast_nullable_to_non_nullable
as String?,spouseOccupation: freezed == spouseOccupation ? _self.spouseOccupation : spouseOccupation // ignore: cast_nullable_to_non_nullable
as String?,spouseEmployer: freezed == spouseEmployer ? _self.spouseEmployer : spouseEmployer // ignore: cast_nullable_to_non_nullable
as String?,references: freezed == references ? _self.references : references // ignore: cast_nullable_to_non_nullable
as List<dynamic>?,registeredAt: freezed == registeredAt ? _self.registeredAt : registeredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Member].
extension MemberPatterns on Member {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Member value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Member() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Member value)  $default,){
final _that = this;
switch (_that) {
case _Member():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Member value)?  $default,){
final _that = this;
switch (_that) {
case _Member() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'account_number')  String accountNumber, @JsonKey(name: 'firstname')  String firstName, @JsonKey(name: 'lastname')  String lastName, @JsonKey(name: 'middlename')  String? middleName,  String? email, @JsonKey(name: 'contact_number')  String? phone, @JsonKey(name: 'passport_photo')  String? photoUrl, @JsonKey(name: 'signature_photo')  String? signatureUrl, @JsonKey(name: 'is_verified')  bool isVerified, @JsonKey(name: 'account_status')  String status, @JsonKey(name: 'civil_status')  String? civilStatus, @JsonKey(name: 'sex')  String? gender, @JsonKey(name: 'birthday', fromJson: _dateStringFromJson, toJson: _dateStringToJson)  String? dateOfBirth,  String? nationality, @JsonKey(name: 'address')  String? homeAddress,  String? occupation, @JsonKey(name: 'employer')  String? employerName, @JsonKey(name: 'employer_address')  String? employerAddress, @JsonKey(name: 'father_name')  String? fatherName, @JsonKey(name: 'mother_name')  String? motherName, @JsonKey(name: 'spouse_name')  String? spouseName, @JsonKey(name: 'spouse_occupation')  String? spouseOccupation, @JsonKey(name: 'spouse_employer')  String? spouseEmployer,  List<dynamic>? references, @JsonKey(name: 'created_at', fromJson: _dateTimeFromTimestamp, toJson: _dateTimeToTimestamp)  DateTime? registeredAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Member() when $default != null:
return $default(_that.id,_that.accountNumber,_that.firstName,_that.lastName,_that.middleName,_that.email,_that.phone,_that.photoUrl,_that.signatureUrl,_that.isVerified,_that.status,_that.civilStatus,_that.gender,_that.dateOfBirth,_that.nationality,_that.homeAddress,_that.occupation,_that.employerName,_that.employerAddress,_that.fatherName,_that.motherName,_that.spouseName,_that.spouseOccupation,_that.spouseEmployer,_that.references,_that.registeredAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'account_number')  String accountNumber, @JsonKey(name: 'firstname')  String firstName, @JsonKey(name: 'lastname')  String lastName, @JsonKey(name: 'middlename')  String? middleName,  String? email, @JsonKey(name: 'contact_number')  String? phone, @JsonKey(name: 'passport_photo')  String? photoUrl, @JsonKey(name: 'signature_photo')  String? signatureUrl, @JsonKey(name: 'is_verified')  bool isVerified, @JsonKey(name: 'account_status')  String status, @JsonKey(name: 'civil_status')  String? civilStatus, @JsonKey(name: 'sex')  String? gender, @JsonKey(name: 'birthday', fromJson: _dateStringFromJson, toJson: _dateStringToJson)  String? dateOfBirth,  String? nationality, @JsonKey(name: 'address')  String? homeAddress,  String? occupation, @JsonKey(name: 'employer')  String? employerName, @JsonKey(name: 'employer_address')  String? employerAddress, @JsonKey(name: 'father_name')  String? fatherName, @JsonKey(name: 'mother_name')  String? motherName, @JsonKey(name: 'spouse_name')  String? spouseName, @JsonKey(name: 'spouse_occupation')  String? spouseOccupation, @JsonKey(name: 'spouse_employer')  String? spouseEmployer,  List<dynamic>? references, @JsonKey(name: 'created_at', fromJson: _dateTimeFromTimestamp, toJson: _dateTimeToTimestamp)  DateTime? registeredAt)  $default,) {final _that = this;
switch (_that) {
case _Member():
return $default(_that.id,_that.accountNumber,_that.firstName,_that.lastName,_that.middleName,_that.email,_that.phone,_that.photoUrl,_that.signatureUrl,_that.isVerified,_that.status,_that.civilStatus,_that.gender,_that.dateOfBirth,_that.nationality,_that.homeAddress,_that.occupation,_that.employerName,_that.employerAddress,_that.fatherName,_that.motherName,_that.spouseName,_that.spouseOccupation,_that.spouseEmployer,_that.references,_that.registeredAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'account_number')  String accountNumber, @JsonKey(name: 'firstname')  String firstName, @JsonKey(name: 'lastname')  String lastName, @JsonKey(name: 'middlename')  String? middleName,  String? email, @JsonKey(name: 'contact_number')  String? phone, @JsonKey(name: 'passport_photo')  String? photoUrl, @JsonKey(name: 'signature_photo')  String? signatureUrl, @JsonKey(name: 'is_verified')  bool isVerified, @JsonKey(name: 'account_status')  String status, @JsonKey(name: 'civil_status')  String? civilStatus, @JsonKey(name: 'sex')  String? gender, @JsonKey(name: 'birthday', fromJson: _dateStringFromJson, toJson: _dateStringToJson)  String? dateOfBirth,  String? nationality, @JsonKey(name: 'address')  String? homeAddress,  String? occupation, @JsonKey(name: 'employer')  String? employerName, @JsonKey(name: 'employer_address')  String? employerAddress, @JsonKey(name: 'father_name')  String? fatherName, @JsonKey(name: 'mother_name')  String? motherName, @JsonKey(name: 'spouse_name')  String? spouseName, @JsonKey(name: 'spouse_occupation')  String? spouseOccupation, @JsonKey(name: 'spouse_employer')  String? spouseEmployer,  List<dynamic>? references, @JsonKey(name: 'created_at', fromJson: _dateTimeFromTimestamp, toJson: _dateTimeToTimestamp)  DateTime? registeredAt)?  $default,) {final _that = this;
switch (_that) {
case _Member() when $default != null:
return $default(_that.id,_that.accountNumber,_that.firstName,_that.lastName,_that.middleName,_that.email,_that.phone,_that.photoUrl,_that.signatureUrl,_that.isVerified,_that.status,_that.civilStatus,_that.gender,_that.dateOfBirth,_that.nationality,_that.homeAddress,_that.occupation,_that.employerName,_that.employerAddress,_that.fatherName,_that.motherName,_that.spouseName,_that.spouseOccupation,_that.spouseEmployer,_that.references,_that.registeredAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Member implements Member {
  const _Member({required this.id, @JsonKey(name: 'account_number') required this.accountNumber, @JsonKey(name: 'firstname') required this.firstName, @JsonKey(name: 'lastname') required this.lastName, @JsonKey(name: 'middlename') this.middleName, this.email, @JsonKey(name: 'contact_number') this.phone, @JsonKey(name: 'passport_photo') this.photoUrl, @JsonKey(name: 'signature_photo') this.signatureUrl, @JsonKey(name: 'is_verified') this.isVerified = false, @JsonKey(name: 'account_status') this.status = 'Active', @JsonKey(name: 'civil_status') this.civilStatus, @JsonKey(name: 'sex') this.gender, @JsonKey(name: 'birthday', fromJson: _dateStringFromJson, toJson: _dateStringToJson) this.dateOfBirth, this.nationality, @JsonKey(name: 'address') this.homeAddress, this.occupation, @JsonKey(name: 'employer') this.employerName, @JsonKey(name: 'employer_address') this.employerAddress, @JsonKey(name: 'father_name') this.fatherName, @JsonKey(name: 'mother_name') this.motherName, @JsonKey(name: 'spouse_name') this.spouseName, @JsonKey(name: 'spouse_occupation') this.spouseOccupation, @JsonKey(name: 'spouse_employer') this.spouseEmployer,  List<dynamic>? references, @JsonKey(name: 'created_at', fromJson: _dateTimeFromTimestamp, toJson: _dateTimeToTimestamp) this.registeredAt}): _references = references;
  factory _Member.fromJson(Map<String, dynamic> json) => _$MemberFromJson(json);

@override final  String id;
@override@JsonKey(name: 'account_number') final  String accountNumber;
@override@JsonKey(name: 'firstname') final  String firstName;
@override@JsonKey(name: 'lastname') final  String lastName;
@override@JsonKey(name: 'middlename') final  String? middleName;
@override final  String? email;
@override@JsonKey(name: 'contact_number') final  String? phone;
@override@JsonKey(name: 'passport_photo') final  String? photoUrl;
@override@JsonKey(name: 'signature_photo') final  String? signatureUrl;
@override@JsonKey(name: 'is_verified') final  bool isVerified;
@override@JsonKey(name: 'account_status') final  String status;
@override@JsonKey(name: 'civil_status') final  String? civilStatus;
@override@JsonKey(name: 'sex') final  String? gender;
@override@JsonKey(name: 'birthday', fromJson: _dateStringFromJson, toJson: _dateStringToJson) final  String? dateOfBirth;
@override final  String? nationality;
@override@JsonKey(name: 'address') final  String? homeAddress;
@override final  String? occupation;
@override@JsonKey(name: 'employer') final  String? employerName;
@override@JsonKey(name: 'employer_address') final  String? employerAddress;
@override@JsonKey(name: 'father_name') final  String? fatherName;
@override@JsonKey(name: 'mother_name') final  String? motherName;
@override@JsonKey(name: 'spouse_name') final  String? spouseName;
@override@JsonKey(name: 'spouse_occupation') final  String? spouseOccupation;
@override@JsonKey(name: 'spouse_employer') final  String? spouseEmployer;
 final  List<dynamic>? _references;
@override List<dynamic>? get references {
  final value = _references;
  if (value == null) return null;
  if (_references is EqualUnmodifiableListView) return _references;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(name: 'created_at', fromJson: _dateTimeFromTimestamp, toJson: _dateTimeToTimestamp) final  DateTime? registeredAt;

/// Create a copy of Member
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemberCopyWith<_Member> get copyWith => __$MemberCopyWithImpl<_Member>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemberToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Member&&(identical(other.id, id) || other.id == id)&&(identical(other.accountNumber, accountNumber) || other.accountNumber == accountNumber)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.middleName, middleName) || other.middleName == middleName)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.signatureUrl, signatureUrl) || other.signatureUrl == signatureUrl)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.status, status) || other.status == status)&&(identical(other.civilStatus, civilStatus) || other.civilStatus == civilStatus)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.nationality, nationality) || other.nationality == nationality)&&(identical(other.homeAddress, homeAddress) || other.homeAddress == homeAddress)&&(identical(other.occupation, occupation) || other.occupation == occupation)&&(identical(other.employerName, employerName) || other.employerName == employerName)&&(identical(other.employerAddress, employerAddress) || other.employerAddress == employerAddress)&&(identical(other.fatherName, fatherName) || other.fatherName == fatherName)&&(identical(other.motherName, motherName) || other.motherName == motherName)&&(identical(other.spouseName, spouseName) || other.spouseName == spouseName)&&(identical(other.spouseOccupation, spouseOccupation) || other.spouseOccupation == spouseOccupation)&&(identical(other.spouseEmployer, spouseEmployer) || other.spouseEmployer == spouseEmployer)&&const DeepCollectionEquality().equals(other._references, _references)&&(identical(other.registeredAt, registeredAt) || other.registeredAt == registeredAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,accountNumber,firstName,lastName,middleName,email,phone,photoUrl,signatureUrl,isVerified,status,civilStatus,gender,dateOfBirth,nationality,homeAddress,occupation,employerName,employerAddress,fatherName,motherName,spouseName,spouseOccupation,spouseEmployer,const DeepCollectionEquality().hash(_references),registeredAt]);

@override
String toString() {
  return 'Member(id: $id, accountNumber: $accountNumber, firstName: $firstName, lastName: $lastName, middleName: $middleName, email: $email, phone: $phone, photoUrl: $photoUrl, signatureUrl: $signatureUrl, isVerified: $isVerified, status: $status, civilStatus: $civilStatus, gender: $gender, dateOfBirth: $dateOfBirth, nationality: $nationality, homeAddress: $homeAddress, occupation: $occupation, employerName: $employerName, employerAddress: $employerAddress, fatherName: $fatherName, motherName: $motherName, spouseName: $spouseName, spouseOccupation: $spouseOccupation, spouseEmployer: $spouseEmployer, references: $references, registeredAt: $registeredAt)';
}


}

/// @nodoc
abstract mixin class _$MemberCopyWith<$Res> implements $MemberCopyWith<$Res> {
  factory _$MemberCopyWith(_Member value, $Res Function(_Member) _then) = __$MemberCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'account_number') String accountNumber,@JsonKey(name: 'firstname') String firstName,@JsonKey(name: 'lastname') String lastName,@JsonKey(name: 'middlename') String? middleName, String? email,@JsonKey(name: 'contact_number') String? phone,@JsonKey(name: 'passport_photo') String? photoUrl,@JsonKey(name: 'signature_photo') String? signatureUrl,@JsonKey(name: 'is_verified') bool isVerified,@JsonKey(name: 'account_status') String status,@JsonKey(name: 'civil_status') String? civilStatus,@JsonKey(name: 'sex') String? gender,@JsonKey(name: 'birthday', fromJson: _dateStringFromJson, toJson: _dateStringToJson) String? dateOfBirth, String? nationality,@JsonKey(name: 'address') String? homeAddress, String? occupation,@JsonKey(name: 'employer') String? employerName,@JsonKey(name: 'employer_address') String? employerAddress,@JsonKey(name: 'father_name') String? fatherName,@JsonKey(name: 'mother_name') String? motherName,@JsonKey(name: 'spouse_name') String? spouseName,@JsonKey(name: 'spouse_occupation') String? spouseOccupation,@JsonKey(name: 'spouse_employer') String? spouseEmployer, List<dynamic>? references,@JsonKey(name: 'created_at', fromJson: _dateTimeFromTimestamp, toJson: _dateTimeToTimestamp) DateTime? registeredAt
});




}
/// @nodoc
class __$MemberCopyWithImpl<$Res>
    implements _$MemberCopyWith<$Res> {
  __$MemberCopyWithImpl(this._self, this._then);

  final _Member _self;
  final $Res Function(_Member) _then;

/// Create a copy of Member
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? accountNumber = null,Object? firstName = null,Object? lastName = null,Object? middleName = freezed,Object? email = freezed,Object? phone = freezed,Object? photoUrl = freezed,Object? signatureUrl = freezed,Object? isVerified = null,Object? status = null,Object? civilStatus = freezed,Object? gender = freezed,Object? dateOfBirth = freezed,Object? nationality = freezed,Object? homeAddress = freezed,Object? occupation = freezed,Object? employerName = freezed,Object? employerAddress = freezed,Object? fatherName = freezed,Object? motherName = freezed,Object? spouseName = freezed,Object? spouseOccupation = freezed,Object? spouseEmployer = freezed,Object? references = freezed,Object? registeredAt = freezed,}) {
  return _then(_Member(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,accountNumber: null == accountNumber ? _self.accountNumber : accountNumber // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,middleName: freezed == middleName ? _self.middleName : middleName // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,signatureUrl: freezed == signatureUrl ? _self.signatureUrl : signatureUrl // ignore: cast_nullable_to_non_nullable
as String?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,civilStatus: freezed == civilStatus ? _self.civilStatus : civilStatus // ignore: cast_nullable_to_non_nullable
as String?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as String?,nationality: freezed == nationality ? _self.nationality : nationality // ignore: cast_nullable_to_non_nullable
as String?,homeAddress: freezed == homeAddress ? _self.homeAddress : homeAddress // ignore: cast_nullable_to_non_nullable
as String?,occupation: freezed == occupation ? _self.occupation : occupation // ignore: cast_nullable_to_non_nullable
as String?,employerName: freezed == employerName ? _self.employerName : employerName // ignore: cast_nullable_to_non_nullable
as String?,employerAddress: freezed == employerAddress ? _self.employerAddress : employerAddress // ignore: cast_nullable_to_non_nullable
as String?,fatherName: freezed == fatherName ? _self.fatherName : fatherName // ignore: cast_nullable_to_non_nullable
as String?,motherName: freezed == motherName ? _self.motherName : motherName // ignore: cast_nullable_to_non_nullable
as String?,spouseName: freezed == spouseName ? _self.spouseName : spouseName // ignore: cast_nullable_to_non_nullable
as String?,spouseOccupation: freezed == spouseOccupation ? _self.spouseOccupation : spouseOccupation // ignore: cast_nullable_to_non_nullable
as String?,spouseEmployer: freezed == spouseEmployer ? _self.spouseEmployer : spouseEmployer // ignore: cast_nullable_to_non_nullable
as String?,references: freezed == references ? _self._references : references // ignore: cast_nullable_to_non_nullable
as List<dynamic>?,registeredAt: freezed == registeredAt ? _self.registeredAt : registeredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
