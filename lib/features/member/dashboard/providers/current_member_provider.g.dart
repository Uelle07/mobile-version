// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_member_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(currentMember)
final currentMemberProvider = CurrentMemberProvider._();

final class CurrentMemberProvider
    extends $FunctionalProvider<AsyncValue<Member?>, Member?, Stream<Member?>>
    with $FutureModifier<Member?>, $StreamProvider<Member?> {
  CurrentMemberProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentMemberProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentMemberHash();

  @$internal
  @override
  $StreamProviderElement<Member?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Member?> create(Ref ref) {
    return currentMember(ref);
  }
}

String _$currentMemberHash() => r'7c042c52bb55a33fffdc76b563a1cbdeb20e6151';
