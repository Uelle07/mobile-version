// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'survey_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(surveys)
final surveysProvider = SurveysProvider._();

final class SurveysProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Survey>>,
          List<Survey>,
          Stream<List<Survey>>
        >
    with $FutureModifier<List<Survey>>, $StreamProvider<List<Survey>> {
  SurveysProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'surveysProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$surveysHash();

  @$internal
  @override
  $StreamProviderElement<List<Survey>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Survey>> create(Ref ref) {
    return surveys(ref);
  }
}

String _$surveysHash() => r'49ac3b03b91cb169025c3d083db9f539bd0cfa7d';
