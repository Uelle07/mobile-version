import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/models/member.dart';
import '../../../admin/members/repositories/member_repository.dart';
import '../../../auth/controllers/auth_controller.dart';

part 'current_member_provider.g.dart';

@riverpod
Stream<Member?> currentMember(Ref ref) {
  final authState = ref.watch(authControllerProvider);
  final user = authState.value?.user;
  
  if (user == null) {
    return Stream.value(null);
  }
  
  final repository = ref.watch(memberRepositoryProvider);
  return repository.getMember(user.uid);
}
