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

@ProviderFor(surveyQuestions)
final surveyQuestionsProvider = SurveyQuestionsFamily._();

final class SurveyQuestionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SurveyQuestion>>,
          List<SurveyQuestion>,
          Stream<List<SurveyQuestion>>
        >
    with
        $FutureModifier<List<SurveyQuestion>>,
        $StreamProvider<List<SurveyQuestion>> {
  SurveyQuestionsProvider._({
    required SurveyQuestionsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'surveyQuestionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$surveyQuestionsHash();

  @override
  String toString() {
    return r'surveyQuestionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<SurveyQuestion>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SurveyQuestion>> create(Ref ref) {
    final argument = this.argument as String;
    return surveyQuestions(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SurveyQuestionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$surveyQuestionsHash() => r'9b199e55b67e6fc81b5275c6d9c058895643a950';

final class SurveyQuestionsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<SurveyQuestion>>, String> {
  SurveyQuestionsFamily._()
    : super(
        retry: null,
        name: r'surveyQuestionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SurveyQuestionsProvider call(String surveyId) =>
      SurveyQuestionsProvider._(argument: surveyId, from: this);

  @override
  String toString() => r'surveyQuestionsProvider';
}

@ProviderFor(surveyChoices)
final surveyChoicesProvider = SurveyChoicesFamily._();

final class SurveyChoicesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SurveyChoice>>,
          List<SurveyChoice>,
          Stream<List<SurveyChoice>>
        >
    with
        $FutureModifier<List<SurveyChoice>>,
        $StreamProvider<List<SurveyChoice>> {
  SurveyChoicesProvider._({
    required SurveyChoicesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'surveyChoicesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$surveyChoicesHash();

  @override
  String toString() {
    return r'surveyChoicesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<SurveyChoice>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SurveyChoice>> create(Ref ref) {
    final argument = this.argument as String;
    return surveyChoices(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SurveyChoicesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$surveyChoicesHash() => r'303c2a4420c7926159934dac74422c52f2811529';

final class SurveyChoicesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<SurveyChoice>>, String> {
  SurveyChoicesFamily._()
    : super(
        retry: null,
        name: r'surveyChoicesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SurveyChoicesProvider call(String questionId) =>
      SurveyChoicesProvider._(argument: questionId, from: this);

  @override
  String toString() => r'surveyChoicesProvider';
}
