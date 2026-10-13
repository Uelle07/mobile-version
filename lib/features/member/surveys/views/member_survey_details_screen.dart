import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/survey.dart';
import '../../../../core/widgets/space_app_bar.dart';
import '../../../admin/members/repositories/member_repository.dart';
import '../../../admin/surveys/repositories/survey_repository.dart';
import '../../dashboard/providers/current_member_provider.dart';
import 'member_survey_success_screen.dart';

enum NormalizedQuestionType {
  multipleChoice,
  yesNo,
  rating,
  shortAnswer,
}

class _OptionItem {
  final String? choiceId;
  final String text;
  final int ratingNumber;
  final String ratingShortLabel;

  const _OptionItem({
    required this.choiceId,
    required this.text,
    this.ratingNumber = 1,
    this.ratingShortLabel = '',
  });
}

class MemberSurveyDetailsScreen extends ConsumerStatefulWidget {
  final Survey? survey;
  final String? surveyId;

  const MemberSurveyDetailsScreen({
    super.key,
    this.survey,
    this.surveyId,
  }) : assert(survey != null || surveyId != null);

  String get resolvedSurveyId => survey?.id ?? surveyId!;

  @override
  ConsumerState<MemberSurveyDetailsScreen> createState() =>
      _MemberSurveyDetailsScreenState();
}

class _MemberSurveyDetailsScreenState
    extends ConsumerState<MemberSurveyDetailsScreen> {
  final ScrollController _scrollController = ScrollController();

  bool _isCheckingPreflight = true;
  bool _isSubmitting = false;

  Survey? _survey;
  List<SurveyQuestion> _questions = [];
  Map<String, List<SurveyChoice>> _choicesByQuestion = {};

  /// Maps question.id -> selected choiceId (if choice from DB)
  final Map<String, String?> _selectedChoiceIds = {};

  /// Maps question.id -> selected answer text or typed text
  final Map<String, String> _answers = {};

  /// TextEditingControllers for short_answer questions
  final Map<String, TextEditingController> _textControllers = {};

  /// Per-question validation error message (question.id -> error string)
  final Map<String, String> _questionErrors = {};

  /// Ordered list of validation errors for the top global error banner
  List<String> _validationBannerErrors = [];

  @override
  void initState() {
    super.initState();
    _survey = widget.survey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runPreflightAndLoad();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _navigateBackToSurveys() {
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      GoRouter.of(context).go('/member/surveys');
    }
  }

  Future<void> _showAlertAndNavigateBack(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF13172E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Color(0xFF38BDF8)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Survey Notice',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.45,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C2A8),
              foregroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Back to Surveys',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    _navigateBackToSurveys();
  }

  Future<void> _runPreflightAndLoad() async {
    final targetSurveyId = widget.resolvedSurveyId;
    final repo = ref.read(surveyRepositoryProvider);
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      await _showAlertAndNavigateBack(
        'Please log in to participate in cooperative surveys.',
      );
      return;
    }

    try {
      var member = ref.read(currentMemberProvider).value;
      if (member == null) {
        final accNo = currentUser.email?.contains('@') == true
            ? currentUser.email!.split('@').first
            : null;
        member = await ref
            .read(memberRepositoryProvider)
            .getMemberOnce(currentUser.uid, accountNumber: accNo);
      }

      final memberIds = <String>[
        currentUser.uid,
        if (member != null && member.id.isNotEmpty) member.id,
      ];

      // 1. Pre-Flight Duplicate Submission Guard
      final alreadySubmitted = await repo.hasMemberSubmittedSurvey(
        targetSurveyId,
        memberIds,
      );
      if (alreadySubmitted) {
        await _showAlertAndNavigateBack(
          'You have already submitted your response for this survey. Thank you!',
        );
        return;
      }

      // 2. Pre-Flight Active & Schedule Validation
      final bundle = await repo.fetchSurveyQuestionnaireBundle(targetSurveyId);
      if (bundle == null) {
        await _showAlertAndNavigateBack(
          'This survey is currently closed or not active.',
        );
        return;
      }

      final fetchedSurvey = bundle.survey;
      final statusLower = fetchedSurvey.status.trim().toLowerCase();
      final now = DateTime.now();
      final isExpired =
          fetchedSurvey.endDate != null && fetchedSurvey.endDate!.isBefore(now);

      if ((statusLower != 'active' && statusLower != 'published') ||
          isExpired) {
        await _showAlertAndNavigateBack(
          'This survey is currently closed or not active.',
        );
        return;
      }

      for (final q in bundle.questions) {
        if (_normalizeQuestionType(q.type) ==
            NormalizedQuestionType.shortAnswer) {
          _textControllers.putIfAbsent(q.id, () => TextEditingController());
        }
      }

      if (mounted) {
        setState(() {
          _survey = fetchedSurvey;
          _questions = bundle.questions;
          _choicesByQuestion = bundle.choicesByQuestion;
          _isCheckingPreflight = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingPreflight = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load survey: $e')),
        );
      }
    }
  }

  NormalizedQuestionType _normalizeQuestionType(String rawType) {
    final normalized = rawType.trim().toLowerCase();
    if (const [
      'multiple_choice',
      'mcq',
      'choice',
      'single_choice',
    ].contains(normalized)) {
      return NormalizedQuestionType.multipleChoice;
    }
    if (const [
      'yes_no',
      'yesno',
      'boolean',
      'yes_or_no',
    ].contains(normalized)) {
      return NormalizedQuestionType.yesNo;
    }
    if (const [
      'rating',
      'scale',
      'rating_scale',
      'scale_1_5',
      'scale_of_1_to_5',
    ].contains(normalized)) {
      return NormalizedQuestionType.rating;
    }
    if (const [
      'short_answer',
      'description',
      'open_ended',
      'text',
      'paragraph',
      'long_answer',
    ].contains(normalized)) {
      return NormalizedQuestionType.shortAnswer;
    }
    return NormalizedQuestionType.shortAnswer;
  }

  List<_OptionItem> _resolveOptionsForQuestion(SurveyQuestion q) {
    final qType = _normalizeQuestionType(q.type);
    final dbChoices = _choicesByQuestion[q.id] ?? const <SurveyChoice>[];

    if (qType == NormalizedQuestionType.multipleChoice) {
      return dbChoices
          .map((c) => _OptionItem(choiceId: c.id, text: c.choiceText))
          .toList();
    }

    if (qType == NormalizedQuestionType.yesNo) {
      if (dbChoices.isNotEmpty) {
        return dbChoices
            .map((c) => _OptionItem(choiceId: c.id, text: c.choiceText))
            .toList();
      }
      return const [
        _OptionItem(choiceId: null, text: 'Yes'),
        _OptionItem(choiceId: null, text: 'No'),
      ];
    }

    if (qType == NormalizedQuestionType.rating) {
      const defaultLabels = [
        'Poor',
        'Fair',
        'Good',
        'Very Good',
        'Excellent',
      ];
      const defaultFullTexts = [
        '1 (Poor)',
        '2 (Fair)',
        '3 (Good)',
        '4 (Very Good)',
        '5 (Excellent)',
      ];

      return List.generate(5, (index) {
        final numVal = index + 1;
        SurveyChoice? matchedChoice;
        if (index < dbChoices.length) {
          matchedChoice = dbChoices[index];
        } else {
          for (final c in dbChoices) {
            if (c.choiceText.trim().startsWith('$numVal')) {
              matchedChoice = c;
              break;
            }
          }
        }
        return _OptionItem(
          choiceId: matchedChoice?.id,
          text: matchedChoice?.choiceText ?? defaultFullTexts[index],
          ratingNumber: numVal,
          ratingShortLabel: defaultLabels[index],
        );
      });
    }

    return const [];
  }

  bool _validateAllQuestions() {
    final Map<String, String> errorsByQ = {};
    final List<String> orderedErrors = [];

    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final qNum = i + 1;
      final qType = _normalizeQuestionType(q.type);

      if (qType == NormalizedQuestionType.shortAnswer) {
        final controller = _textControllers[q.id];
        final trimmed = (controller?.text ?? _answers[q.id] ?? '').trim();
        _answers[q.id] = trimmed;
        if (trimmed.isEmpty) {
          final msg = 'Question #$qNum (${q.question}) requires an answer.';
          errorsByQ[q.id] = msg;
          orderedErrors.add(msg);
        }
      } else {
        final selectedAnswer = (_answers[q.id] ?? '').trim();
        if (selectedAnswer.isEmpty) {
          String msg;
          switch (qType) {
            case NormalizedQuestionType.multipleChoice:
              msg =
                  'Please select an option for Question #$qNum (${q.question}).';
              break;
            case NormalizedQuestionType.yesNo:
              msg =
                  'Please select Yes or No for Question #$qNum (${q.question}).';
              break;
            case NormalizedQuestionType.rating:
              msg =
                  'Please select a rating (1 to 5) for Question #$qNum (${q.question}).';
              break;
            case NormalizedQuestionType.shortAnswer:
              msg = 'Question #$qNum (${q.question}) requires an answer.';
              break;
          }
          errorsByQ[q.id] = msg;
          orderedErrors.add(msg);
        }
      }
    }

    setState(() {
      _questionErrors
        ..clear()
        ..addAll(errorsByQ);
      _validationBannerErrors = orderedErrors;
    });

    if (orderedErrors.isNotEmpty) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
      return false;
    }

    return true;
  }

  Future<void> _submitSurvey() async {
    FocusScope.of(context).unfocus();

    if (!_validateAllQuestions()) {
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _survey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired. Please log in again.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      var member = ref.read(currentMemberProvider).value;
      if (member == null) {
        final accNo = currentUser.email?.contains('@') == true
            ? currentUser.email!.split('@').first
            : null;
        member = await ref
            .read(memberRepositoryProvider)
            .getMemberOnce(currentUser.uid, accountNumber: accNo);
      }

      final primaryMemberId = currentUser.uid;
      final allMemberIds = <String>[
        currentUser.uid,
        if (member != null && member.id.isNotEmpty) member.id,
      ];
      final memberName =
          (member != null &&
              '${member.firstName} ${member.lastName}'.trim().isNotEmpty)
          ? '${member.firstName} ${member.lastName}'.trim()
          : (currentUser.displayName?.isNotEmpty == true
                ? currentUser.displayName!
                : (currentUser.email?.split('@').first ?? 'Member'));

      final List<SubmittedQuestionAnswer> payload = _questions.map((q) {
        final qType = _normalizeQuestionType(q.type);
        final answerText = (qType == NormalizedQuestionType.shortAnswer)
            ? (_textControllers[q.id]?.text ?? _answers[q.id] ?? '').trim()
            : (_answers[q.id] ?? '').trim();
        final choiceId = (qType == NormalizedQuestionType.shortAnswer)
            ? null
            : _selectedChoiceIds[q.id];
        return SubmittedQuestionAnswer(
          questionId: q.id,
          choiceId: choiceId,
          answer: answerText,
        );
      }).toList();

      final repo = ref.read(surveyRepositoryProvider);
      final receiptData = await repo.submitMemberQuestionnaire(
        survey: _survey!,
        memberId: primaryMemberId,
        allMemberIds: allMemberIds,
        memberName: memberName,
        answers: payload,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MemberSurveySuccessScreen(
            surveyId: _survey!.id,
            initialReceiptData: receiptData,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        final cleanMsg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Text(
              cleanMsg,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(currentMemberProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surveyTitle = _survey?.title ?? 'Take Survey';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: isDark
          ? const Color(0xFF0B132B)
          : const Color(0xFFF1F5F9),
      appBar: SpaceAppBar(
        title: Text(surveyTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: _isCheckingPreflight
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 80.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _buildSurveyBody(context, isDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSurveyBody(BuildContext context, bool isDark) {
    final survey = _survey;
    if (survey == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Back Button: ← Back to Surveys
        Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
            onTap: _isSubmitting ? null : _navigateBackToSurveys,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.16)
                      : Colors.black.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    size: 16,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '← Back to Surveys',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Global Validation Error Banner (if any)
        if (_validationBannerErrors.isNotEmpty) ...[
          _buildGlobalErrorBanner(),
          const SizedBox(height: 16),
        ],

        // Hero Header Card
        _buildHeroHeaderCard(survey, _questions.length, isDark),
        const SizedBox(height: 16),

        // Instructions Card (Visible only if survey.instructions is non-empty)
        if (survey.instructions.trim().isNotEmpty) ...[
          _buildInstructionsCard(survey.instructions.trim(), isDark),
          const SizedBox(height: 16),
        ],

        // Questions List
        if (_questions.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF13172E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.quiz_outlined,
                  size: 44,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                const SizedBox(height: 12),
                Text(
                  'No questions have been configured for this survey yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        else ...[
          ...List.generate(_questions.length, (index) {
            final q = _questions[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _buildSurveyQuestionCard(
                question: q,
                questionNumber: index + 1,
                isDark: isDark,
              ),
            );
          }),
          const SizedBox(height: 8),

          // Action Button Row (Cancel & Submit Survey)
          _buildActionButtonsRow(isDark),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildGlobalErrorBanner() {
    const redError = Color(0xFFEF4444);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: redError.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: redError.withValues(alpha: 0.7),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFF87171),
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '⚠ Please answer all required survey questions:',
                  softWrap: true,
                  style: TextStyle(
                    color: Color(0xFFFECACA),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._validationBannerErrors.map(
            (err) => Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 5.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(
                      color: Color(0xFFF87171),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      err,
                      softWrap: true,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeaderCard(
    Survey survey,
    int questionCount,
    bool isDark,
  ) {
    final cardBg = isDark ? const Color(0xFF13172E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    const cyanAccent = Color(0xFF00C2A8);

    String formattedEndDate = 'No End Date';
    if (survey.endDate != null) {
      formattedEndDate = DateFormat('MMM d, yyyy • h:mm a').format(
        survey.endDate!,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: cyanAccent.withValues(alpha: isDark ? 0.45 : 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: cyanAccent.withValues(alpha: isDark ? 0.16 : 0.08),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF00C2A8),
                    Color(0xFF38BDF8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge: "ACTIVE MEMBER SURVEY"
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: cyanAccent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: cyanAccent.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          color: cyanAccent,
                          size: 14,
                        ),
                        SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            'ACTIVE MEMBER SURVEY',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: cyanAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    survey.title,
                    softWrap: true,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),

                  // Description (preserve line breaks)
                  if (survey.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      survey.description.trim(),
                      softWrap: true,
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 13.5,
                        height: 1.45,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),

                  // Single-line Meta Row: Closes: <end_date or No End Date> | <N> Question(s)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 13.5,
                              color: cyanAccent,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Closes: $formattedEndDate',
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.fact_check_outlined,
                              size: 14.5,
                              color: cyanAccent,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '$questionCount Question(s)',
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsCard(String instructions, bool isDark) {
    const skyBlue = Color(0xFF38BDF8);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: skyBlue.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: skyBlue.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ℹ SURVEY INSTRUCTIONS:',
            style: TextStyle(
              color: skyBlue,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            instructions,
            softWrap: true,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveyQuestionCard({
    required SurveyQuestion question,
    required int questionNumber,
    required bool isDark,
  }) {
    final qType = _normalizeQuestionType(question.type);
    final errorMsg = _questionErrors[question.id];
    final hasError = errorMsg != null && errorMsg.isNotEmpty;

    final cardBg = isDark ? const Color(0xFF13172E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    const cyanColor = Color(0xFF00C2A8);
    const redBorderColor = Color(0xFFEF4444);

    // Type Pill styling per spec:
    // Multiple Choice: Sky Blue (#38BDF8) — "Multiple Choice"
    // Yes or No: Emerald Green (#34D399) — "Yes or No"
    // Scale of 1 to 5: Amber Gold (#FBBF24) — "Scale of 1 to 5"
    // Description Form: Purple (#C084FC) — "Description Form"
    String typeLabel;
    Color typeColor;
    IconData typeIcon;
    switch (qType) {
      case NormalizedQuestionType.multipleChoice:
        typeLabel = 'Multiple Choice';
        typeColor = const Color(0xFF38BDF8);
        typeIcon = Icons.radio_button_checked_rounded;
        break;
      case NormalizedQuestionType.yesNo:
        typeLabel = 'Yes or No';
        typeColor = const Color(0xFF34D399);
        typeIcon = Icons.thumbs_up_down_outlined;
        break;
      case NormalizedQuestionType.rating:
        typeLabel = 'Scale of 1 to 5';
        typeColor = const Color(0xFFFBBF24);
        typeIcon = Icons.star_rounded;
        break;
      case NormalizedQuestionType.shortAnswer:
        typeLabel = 'Description Form';
        typeColor = const Color(0xFFC084FC);
        typeIcon = Icons.notes_rounded;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasError
              ? redBorderColor
              : (isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08)),
          width: hasError ? 1.8 : 1.0,
        ),
        boxShadow: [
          if (hasError)
            BoxShadow(
              color: redBorderColor.withValues(alpha: 0.18),
              blurRadius: 12,
              spreadRadius: 1,
            )
          else if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Single-line Question Header Badges (Q# + Type Pill on left, * Required on right)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Number Pill: Q1, Q2, etc. (Cyan border/fill)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: cyanColor.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: cyanColor.withValues(alpha: 0.55),
                          ),
                        ),
                        child: Text(
                          'Q$questionNumber',
                          style: const TextStyle(
                            color: cyanColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Type Pill (Color-coded)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: typeColor.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(typeIcon, size: 13, color: typeColor),
                            const SizedBox(width: 5),
                            Text(
                              typeLabel,
                              style: TextStyle(
                                color: typeColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Required Badge: Red (#F87171) — "* Required"
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF87171).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFFF87171).withValues(alpha: 0.4),
                  ),
                ),
                child: const Text(
                  '* Required',
                  style: TextStyle(
                    color: Color(0xFFF87171),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Question Prompt: Bold white text (q.question)
          Text(
            question.question,
            softWrap: true,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),

          // Question Input Control by Type
          _buildQuestionInputByType(question, qType, isDark, hasError),

          // Inline Validation Error Message (if any)
          if (hasError) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFF87171),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    errorMsg,
                    softWrap: true,
                    style: const TextStyle(
                      color: Color(0xFFF87171),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionInputByType(
    SurveyQuestion question,
    NormalizedQuestionType qType,
    bool isDark,
    bool hasError,
  ) {
    final hintColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    switch (qType) {
      case NormalizedQuestionType.multipleChoice:
        final options = _resolveOptionsForQuestion(question);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select one option from the choices below:',
              style: TextStyle(
                color: hintColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            if (options.isEmpty)
              Text(
                'No options configured for this question.',
                style: TextStyle(color: hintColor, fontSize: 13),
              )
            else
              ...options.map((opt) {
                final isSelected = _answers[question.id] == opt.text;
                const cyanHighlight = Color(0xFF00C2A8);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedChoiceIds[question.id] = opt.choiceId;
                        _answers[question.id] = opt.text;
                        _questionErrors.remove(question.id);
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? cyanHighlight.withValues(alpha: 0.14)
                            : (isDark
                                  ? const Color(0xFF0B132B).withValues(
                                      alpha: 0.65,
                                    )
                                  : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? cyanHighlight
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : Colors.black.withValues(alpha: 0.12)),
                          width: isSelected ? 1.8 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            color: isSelected
                                ? cyanHighlight
                                : (isDark ? Colors.white54 : Colors.black45),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              opt.text,
                              softWrap: true,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        );

      case NormalizedQuestionType.yesNo:
        final options = _resolveOptionsForQuestion(question);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Please select either Yes or No:',
              style: TextStyle(
                color: hintColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final cards = options.map((opt) {
                  final isYes = opt.text.trim().toLowerCase().startsWith('y');
                  final activeColor = isYes
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444);
                  final iconData = isYes
                      ? Icons.thumb_up_alt_rounded
                      : Icons.thumb_down_alt_rounded;
                  final isSelected = _answers[question.id] == opt.text;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedChoiceIds[question.id] = opt.choiceId;
                        _answers[question.id] = opt.text;
                        _questionErrors.remove(question.id);
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? activeColor.withValues(alpha: 0.16)
                            : (isDark
                                  ? const Color(0xFF0B132B).withValues(
                                      alpha: 0.65,
                                    )
                                  : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? activeColor
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : Colors.black.withValues(alpha: 0.12)),
                          width: isSelected ? 1.8 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: activeColor.withValues(alpha: 0.28),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            iconData,
                            color: isSelected
                                ? activeColor
                                : (isDark ? Colors.white60 : Colors.black54),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              opt.text,
                              softWrap: true,
                              style: TextStyle(
                                color: isSelected
                                    ? activeColor
                                    : (isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A)),
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList();

                if (constraints.maxWidth < 320 || cards.length != 2) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: cards
                        .map(
                          (c) => Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: c,
                          ),
                        )
                        .toList(),
                  );
                }

                return Row(
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 12),
                    Expanded(child: cards[1]),
                  ],
                );
              },
            ),
          ],
        );

      case NormalizedQuestionType.rating:
        final options = _resolveOptionsForQuestion(question);
        const goldColor = Color(0xFFFBBF24);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Rate on a scale from 1 (Poor) to 5 (Excellent):',
              style: TextStyle(
                color: hintColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            // Mandate #4: Use LayoutBuilder — 1-column stack on phones (< 500px), 5-column row only on tablets
            LayoutBuilder(
              builder: (context, constraints) {
                final isWideTablet = constraints.maxWidth >= 500;

                if (!isWideTablet) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: options.map((opt) {
                      final isSelected = _answers[question.id] == opt.text;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedChoiceIds[question.id] = opt.choiceId;
                              _answers[question.id] = opt.text;
                              _questionErrors.remove(question.id);
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? goldColor.withValues(alpha: 0.16)
                                  : (isDark
                                        ? const Color(0xFF0B132B).withValues(
                                            alpha: 0.65,
                                          )
                                        : const Color(0xFFF8FAFC)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? goldColor
                                    : (isDark
                                          ? Colors.white.withValues(alpha: 0.12)
                                          : Colors.black.withValues(
                                              alpha: 0.12,
                                            )),
                                width: isSelected ? 1.8 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Number badge (1-5)
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? goldColor
                                        : goldColor.withValues(alpha: 0.15),
                                    border: Border.all(
                                      color: goldColor.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${opt.ratingNumber}',
                                      style: TextStyle(
                                        color: isSelected
                                            ? const Color(0xFF0F172A)
                                            : goldColor,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Stars + Label wrapped in Expanded
                                Expanded(
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: List.generate(
                                          opt.ratingNumber,
                                          (_) => const Icon(
                                            Icons.star_rounded,
                                            color: goldColor,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        opt.ratingShortLabel,
                                        softWrap: true,
                                        style: TextStyle(
                                          color: isSelected
                                              ? goldColor
                                              : (isDark
                                                    ? Colors.white
                                                    : const Color(0xFF0F172A)),
                                          fontSize: 13.5,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  isSelected
                                      ? Icons.check_circle_rounded
                                      : Icons.circle_outlined,
                                  color: isSelected
                                      ? goldColor
                                      : (isDark
                                            ? Colors.white38
                                            : Colors.black38),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }

                // Tablet 5-column horizontal layout
                return Row(
                  children: List.generate(options.length, (i) {
                    final opt = options[i];
                    final isSelected = _answers[question.id] == opt.text;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: i < options.length - 1 ? 8.0 : 0,
                        ),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedChoiceIds[question.id] = opt.choiceId;
                              _answers[question.id] = opt.text;
                              _questionErrors.remove(question.id);
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? goldColor.withValues(alpha: 0.16)
                                  : (isDark
                                        ? const Color(0xFF0B132B).withValues(
                                            alpha: 0.65,
                                          )
                                        : const Color(0xFFF8FAFC)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? goldColor
                                    : (isDark
                                          ? Colors.white.withValues(alpha: 0.12)
                                          : Colors.black.withValues(
                                              alpha: 0.12,
                                            )),
                                width: isSelected ? 1.8 : 1.0,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? goldColor
                                        : goldColor.withValues(alpha: 0.15),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${opt.ratingNumber}',
                                      style: TextStyle(
                                        color: isSelected
                                            ? const Color(0xFF0F172A)
                                            : goldColor,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  children: List.generate(
                                    opt.ratingNumber,
                                    (_) => const Icon(
                                      Icons.star_rounded,
                                      color: goldColor,
                                      size: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  opt.ratingShortLabel,
                                  textAlign: TextAlign.center,
                                  softWrap: true,
                                  style: TextStyle(
                                    color: isSelected
                                        ? goldColor
                                        : (isDark
                                              ? Colors.white70
                                              : Colors.black87),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        );

      case NormalizedQuestionType.shortAnswer:
        final controller = _textControllers.putIfAbsent(
          question.id,
          () => TextEditingController(text: _answers[question.id] ?? ''),
        );
        const cyanFocus = Color(0xFF00C2A8);
        const redError = Color(0xFFEF4444);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Please provide your detailed response or comments in the box below:',
              style: TextStyle(
                color: hintColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              minLines: 4,
              maxLines: 8,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 14,
                height: 1.4,
              ),
              onChanged: (val) {
                _answers[question.id] = val.trim();
                if (val.trim().isNotEmpty &&
                    _questionErrors.containsKey(question.id)) {
                  setState(() {
                    _questionErrors.remove(question.id);
                  });
                }
              },
              decoration: InputDecoration(
                hintText: 'Type your detailed answer here...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 13.5,
                ),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF0B132B).withValues(alpha: 0.8)
                    : const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: hasError
                        ? redError
                        : (isDark ? Colors.white24 : Colors.black26),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: hasError
                        ? redError
                        : (isDark ? Colors.white24 : Colors.black26),
                    width: hasError ? 1.8 : 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: hasError ? redError : cyanFocus,
                    width: 2.0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '✒ Open-ended feedback field',
                style: TextStyle(
                  color: hintColor,
                  fontSize: 11.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildActionButtonsRow(bool isDark) {
    const cyanColor = Color(0xFF00C2A8);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cancelBtn = OutlinedButton.icon(
          onPressed: _isSubmitting ? null : _navigateBackToSurveys,
          icon: const Icon(Icons.close_rounded, size: 18),
          label: const Flexible(
            child: Text(
              'Cancel',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? Colors.white70 : Colors.black87,
            side: BorderSide(
              color: isDark ? Colors.white24 : Colors.black26,
            ),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        final submitBtn = ElevatedButton(
          onPressed: _isSubmitting ? null : _submitSurvey,
          style: ElevatedButton.styleFrom(
            backgroundColor: cyanColor,
            foregroundColor: const Color(0xFF0F172A),
            disabledBackgroundColor: cyanColor.withValues(alpha: 0.5),
            disabledForegroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isSubmitting
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Submitting Survey...',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                  ],
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 18),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Submit Survey',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
        );

        if (constraints.maxWidth < 340) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              submitBtn,
              const SizedBox(height: 10),
              cancelBtn,
            ],
          );
        }

        return Row(
          children: [
            Expanded(flex: 2, child: cancelBtn),
            const SizedBox(width: 12),
            Expanded(flex: 3, child: submitBtn),
          ],
        );
      },
    );
  }
}
