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
  phone: json['phone'] as String?,
  photoUrl: json['photoUrl'] as String?,
  signatureUrl: json['signatureUrl'] as String?,
  isVerified: json['isVerified'] as bool? ?? false,
  registeredAt: _dateTimeFromTimestamp(json['registeredAt'] as Timestamp?),
);

Map<String, dynamic> _$MemberToJson(_Member instance) => <String, dynamic>{
  'id': instance.id,
  'account_number': instance.accountNumber,
  'firstname': instance.firstName,
  'lastname': instance.lastName,
  'middlename': instance.middleName,
  'email': instance.email,
  'phone': instance.phone,
  'photoUrl': instance.photoUrl,
  'signatureUrl': instance.signatureUrl,
  'isVerified': instance.isVerified,
  'registeredAt': _dateTimeToTimestamp(instance.registeredAt),
};
