// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Member _$MemberFromJson(Map<String, dynamic> json) => _Member(
  id: json['id'] as String,
  accountNumber: json['account_number'] as String,
  firstName: json['firstname'] as String,
  lastName: json['lastname'] as String,
  middleName: json['middlename'] as String?,
  email: json['email'] as String?,
  phone: json['contact_number'] as String?,
  photoUrl: json['passport_photo'] as String?,
  signatureUrl: json['signature_photo'] as String?,
  isVerified: json['is_verified'] as bool? ?? false,
  status: json['account_status'] as String? ?? 'Active',
  civilStatus: json['civil_status'] as String?,
  gender: json['sex'] as String?,
  dateOfBirth: _dateStringFromJson(json['birthday']),
  nationality: json['nationality'] as String?,
  homeAddress: json['address'] as String?,
  occupation: json['occupation'] as String?,
  employerName: json['employer'] as String?,
  employerAddress: json['employer_address'] as String?,
  fatherName: json['father_name'] as String?,
  motherName: json['mother_name'] as String?,
  spouseName: json['spouse_name'] as String?,
  spouseOccupation: json['spouse_occupation'] as String?,
  spouseEmployer: json['spouse_employer'] as String?,
  registeredAt: _dateTimeFromTimestamp(json['created_at'] as Timestamp?),
);

Map<String, dynamic> _$MemberToJson(_Member instance) => <String, dynamic>{
  'id': instance.id,
  'account_number': instance.accountNumber,
  'firstname': instance.firstName,
  'lastname': instance.lastName,
  'middlename': instance.middleName,
  'email': instance.email,
  'contact_number': instance.phone,
  'passport_photo': instance.photoUrl,
  'signature_photo': instance.signatureUrl,
  'is_verified': instance.isVerified,
  'account_status': instance.status,
  'civil_status': instance.civilStatus,
  'sex': instance.gender,
  'birthday': _dateStringToJson(instance.dateOfBirth),
  'nationality': instance.nationality,
  'address': instance.homeAddress,
  'occupation': instance.occupation,
  'employer': instance.employerName,
  'employer_address': instance.employerAddress,
  'father_name': instance.fatherName,
  'mother_name': instance.motherName,
  'spouse_name': instance.spouseName,
  'spouse_occupation': instance.spouseOccupation,
  'spouse_employer': instance.spouseEmployer,
  'created_at': _dateTimeToTimestamp(instance.registeredAt),
};
