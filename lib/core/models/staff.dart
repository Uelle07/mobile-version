import 'package:freezed_annotation/freezed_annotation.dart';

part 'staff.freezed.dart';
part 'staff.g.dart';

@freezed
abstract class Staff with _$Staff {
  const factory Staff({
    required String id,
    required String name,
    required String role,
    String? email,
    String? photoUrl,
  }) = _Staff;

  factory Staff.fromJson(Map<String, dynamic> json) => _$StaffFromJson(json);
}
