import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/models/member.dart';
import '../repositories/member_repository.dart';

part 'member_provider.g.dart';

@riverpod
Stream<List<Member>> members(Ref ref) {
  final repository = ref.watch(memberRepositoryProvider);
  return repository.getMembers();
}
