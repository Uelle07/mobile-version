import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'member.freezed.dart';
part 'member.g.dart';

@freezed
abstract class Member with _$Member {
  const factory Member({
    required String id,
    @JsonKey(name: 'account_number') required String accountNumber,
    @JsonKey(name: 'firstname') required String firstName,
    @JsonKey(name: 'lastname') required String lastName,
    @JsonKey(name: 'middlename') String? middleName,
    String? email,
    @JsonKey(name: 'contact_number') String? phone,
    @JsonKey(name: 'passport_photo') String? photoUrl,
    @JsonKey(name: 'signature_photo') String? signatureUrl,
    @JsonKey(name: 'is_verified') @Default(false) bool isVerified,
    @JsonKey(name: 'account_status') @Default('Active') String status,
    @JsonKey(name: 'civil_status') String? civilStatus,
    @JsonKey(name: 'sex') String? gender,
    @JsonKey(
      name: 'birthday',
      fromJson: _dateStringFromJson,
      toJson: _dateStringToJson,
    )
    String? dateOfBirth,
    String? nationality,
    @JsonKey(name: 'address') String? homeAddress,
    String? occupation,
    @JsonKey(name: 'employer') String? employerName,
    @JsonKey(name: 'employer_address') String? employerAddress,
    @JsonKey(name: 'father_name') String? fatherName,
    @JsonKey(name: 'mother_name') String? motherName,
    @JsonKey(name: 'spouse_name') String? spouseName,
    @JsonKey(name: 'spouse_occupation') String? spouseOccupation,
    @JsonKey(name: 'spouse_employer') String? spouseEmployer,
    List<dynamic>? references,
    @JsonKey(
      name: 'created_at',
      fromJson: _dateTimeFromTimestamp,
      toJson: _dateTimeToTimestamp,
    )
    DateTime? registeredAt,
  }) = _Member;

  factory Member.fromJson(Map<String, dynamic> json) => _$MemberFromJson(json);
}

DateTime? _dateTimeFromTimestamp(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}
Timestamp? _dateTimeToTimestamp(DateTime? dateTime) =>
    dateTime == null ? null : Timestamp.fromDate(dateTime);

String? _dateStringFromJson(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  if (value is Timestamp) {
    final date = value.toDate();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  return value.toString();
}

dynamic _dateStringToJson(String? value) => value;
