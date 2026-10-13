import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/survey.dart';
import '../../../../core/widgets/space_app_bar.dart';
import '../../../admin/surveys/providers/survey_provider.dart';
import '../../../admin/surveys/repositories/survey_repository.dart';
import 'member_survey_details_screen.dart';

enum ActiveSurveyFilter {
  all,
  available,
  completed,
}

enum HistorySurveyFilter {
  all,
  last30Days,
  thisYear,
}

/// Standalone route wrapper for `/member/surveys` ensuring `resizeToAvoidBottomInset: true`.
class MemberSurveysScreen extends StatelessWidget {
  const MemberSurveysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: SpaceAppBar(
        title: Text('Cooperative Surveys'),
      ),
      body: MemberSurveyListTab(),
    );
  }
}

class MemberSurveyListTab extends ConsumerStatefulWidget {
  const MemberSurveyListTab({super.key});

  @override
  ConsumerState<MemberSurveyListTab> createState() =>
      _MemberSurveyListTabState();
}

class _MemberSurveyListTabState extends ConsumerState<MemberSurveyListTab> {
  final TextEditingController _activeSearchController = TextEditingController();
  final TextEditingController _historySearchController =
      TextEditingController();

  String _activeSearchQuery = '';
  ActiveSurveyFilter _activeFilter = ActiveSurveyFilter.all;

  String _historySearchQuery = '';
  HistorySurveyFilter _historyFilter = HistorySurveyFilter.all;

  @override
  void dispose() {
    _activeSearchController.dispose();
    _historySearchController.dispose();
    super.dispose();
  }

  bool _isSurveyCurrentlyActive(Survey s, DateTime now) {
    final statusLower = s.status.trim().toLowerCase();
    if (statusLower != 'active' && statusLower != 'published') {
      return false;
    }
    if (s.endDate != null && s.endDate!.isBefore(now)) {
      return false;
    }
    return true;
  }

  String _formatDateRange(DateTime? startDate, DateTime? endDate) {
    final df = DateFormat('MMM d, yyyy');
    final startStr = startDate != null ? df.format(startDate) : 'Open';
    final endStr = endDate != null ? df.format(endDate) : 'No End Date';
    return '$startStr – $endStr';
  }

  String _truncateDescription(String desc, {int maxChars = 90}) {
    final trimmed = desc.trim();
    if (trimmed.length <= maxChars) return trimmed;
    return '${trimmed.substring(0, maxChars).trimRight()}...';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surveysAsync = ref.watch(surveysProvider);
    final questionCountsAsync = ref.watch(surveyQuestionCountsProvider);
    final submissionsAsync = ref.watch(memberSubmissionsProvider);

    final questionCountsMap = questionCountsAsync.value ?? const <String, int>{};
    final submissions =
        submissionsAsync.value ?? const <MemberSurveySubmission>[];
    final answeredSurveyIds = submissions.map((e) => e.surveyId).toSet();

    return SafeArea(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: surveysAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 80.0),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  'Failed to load surveys: $error',
                  style: const TextStyle(color: Color(0xFFF87171)),
                ),
              ),
              data: (allSurveys) {
                final now = DateTime.now();
                final surveysById = {for (final s in allSurveys) s.id: s};

                // Active surveys in DB
                final activeSurveys = allSurveys
                    .where((s) => _isSurveyCurrentlyActive(s, now))
                    .toList();

                final totalActiveCount = activeSurveys.length;
                final availableToTakeCount = activeSurveys
                    .where((s) => !answeredSurveyIds.contains(s.id))
                    .length;
                final completedActiveCount = activeSurveys
                    .where((s) => answeredSurveyIds.contains(s.id))
                    .length;

                // Filter active surveys by search + filter chip
                final trimmedQuery = _activeSearchController.text
                    .trim()
                    .toLowerCase();
                final filteredActiveSurveys = activeSurveys.where((survey) {
                  final isAnswered = answeredSurveyIds.contains(survey.id);
                  if (_activeFilter == ActiveSurveyFilter.available &&
                      isAnswered) {
                    return false;
                  }
                  if (_activeFilter == ActiveSurveyFilter.completed &&
                      !isAnswered) {
                    return false;
                  }
                  if (trimmedQuery.isNotEmpty) {
                    final status = survey.status.toLowerCase().trim();
                    final code = survey.id.length >= 8
                        ? survey.id.substring(0, 8).toLowerCase()
                        : survey.id.toLowerCase();
                    final titleMatch = survey.title
                        .toLowerCase()
                        .contains(trimmedQuery);
                    final descMatch = survey.description
                        .toLowerCase()
                        .contains(trimmedQuery);
                    final statusMatch = status.contains(trimmedQuery);
                    final codeMatch = code.contains(trimmedQuery);
                    return titleMatch || descMatch || statusMatch || codeMatch;
                  }
                  return true;
                }).toList();

                // Filter history log items
                final trimmedHistoryQuery = _historySearchController.text
                    .trim()
                    .toLowerCase();
                final filteredHistory = submissions.where((sub) {
                  final survey = surveysById[sub.surveyId];
                  final surveyTitle =
                      survey?.title ?? 'Cooperative Survey #${sub.surveyId}';
                  final surveyDesc = survey?.description ?? '';
                  final surveyStatus = survey?.status ?? 'completed';
                  final code = sub.surveyId.length >= 8
                      ? sub.surveyId.substring(0, 8).toLowerCase()
                      : sub.surveyId.toLowerCase();

                  if (_historyFilter == HistorySurveyFilter.last30Days) {
                    final diffDays = now.difference(sub.submittedAt).inDays;
                    if (diffDays > 30 || diffDays < -1) return false;
                  } else if (_historyFilter == HistorySurveyFilter.thisYear) {
                    if (sub.submittedAt.year != now.year) return false;
                  }

                  if (trimmedHistoryQuery.isNotEmpty) {
                    return surveyTitle.toLowerCase().contains(
                          trimmedHistoryQuery,
                        ) ||
                        surveyDesc.toLowerCase().contains(
                          trimmedHistoryQuery,
                        ) ||
                        surveyStatus.toLowerCase().contains(
                          trimmedHistoryQuery,
                        ) ||
                        code.contains(trimmedHistoryQuery);
                  }
                  return true;
                }).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // A. Hero Banner Card
                    _buildHeroBannerCard(
                      availableCount: availableToTakeCount,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 18),

                    // B. Search & Filter Toolbar (Active Questionnaires)
                    _buildActiveSearchAndFilterToolbar(
                      allCount: totalActiveCount,
                      availableCount: availableToTakeCount,
                      completedCount: completedActiveCount,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 20),

                    // C. Active Surveys List Header
                    _buildQuestionnairesSectionHeader(
                      availableCount: availableToTakeCount,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),

                    // Active Surveys List or Empty State
                    if (activeSurveys.isEmpty)
                      _buildEmptyStateCard(
                        icon: Icons.assignment_late_outlined,
                        title: 'No Active Surveys Available',
                        message:
                            'There are currently no active surveys scheduled for member participation. Please check back later for new cooperative inquiries.',
                        isDark: isDark,
                      )
                    else if (filteredActiveSurveys.isEmpty)
                      _buildEmptyStateCard(
                        icon: Icons.search_off_rounded,
                        title: 'No Matching Surveys Found',
                        message:
                            'Try adjusting your keyword search or active filter chip.',
                        isDark: isDark,
                      )
                    else
                      ...filteredActiveSurveys.map((survey) {
                        final isAnswered = answeredSurveyIds.contains(
                          survey.id,
                        );
                        final qCount =
                            questionCountsMap[survey.id] ??
                            survey.questionsCount;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14.0),
                          child: _buildActiveSurveyCard(
                            context: context,
                            survey: survey,
                            questionCount: qCount,
                            isAnswered: isAnswered,
                            isDark: isDark,
                          ),
                        );
                      }),

                    const SizedBox(height: 24),

                    // D. Survey History Log Section Divider
                    _buildSubmissionRecordsDivider(isDark),
                    const SizedBox(height: 20),

                    // History Header Card & Search/Filter Bar
                    _buildHistorySectionCard(
                      totalSubmittedCount: submissions.length,
                      filteredHistory: filteredHistory,
                      surveysById: surveysById,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBannerCard({
    required int availableCount,
    required bool isDark,
  }) {
    final cardBg = isDark ? const Color(0xFF13172E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    const cyanAccent = Color(0xFF00C2A8);
    const emeraldGreen = Color(0xFF10B981);
    const skyBlue = Color(0xFF38BDF8);

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
                    Color(0xFF8B5CF6),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge: MEMBER FEEDBACK & INQUIRIES with clipboard icon
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cyanAccent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: cyanAccent.withValues(alpha: 0.45),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          color: cyanAccent,
                          size: 13,
                        ),
                        SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            'MEMBER FEEDBACK & INQUIRIES',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: cyanAccent,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Title: "Cooperative Surveys"
                  Text(
                    'Cooperative Surveys',
                    softWrap: true,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Single-row Metadata Bar (scales down if needed so pills never stack on mobile)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: emeraldGreen.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: emeraldGreen.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: emeraldGreen,
                                size: 13,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '$availableCount Available Survey(s)',
                                style: const TextStyle(
                                  color: emeraldGreen,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: skyBlue.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: skyBlue.withValues(alpha: 0.45),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_user_rounded,
                                color: skyBlue,
                                size: 13,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Member Participation Portal',
                                style: TextStyle(
                                  color: skyBlue,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
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
          ],
        ),
      ),
    );
  }

  bool get _hasActiveMemberFilter =>
      _activeFilter != ActiveSurveyFilter.all ||
      _historyFilter != HistorySurveyFilter.all;

  Widget _buildFilterIconButton({required bool isDark}) {
    const cyanAccent = Color(0xFF00C2A8);
    final hasFilter = _hasActiveMemberFilter;

    return SizedBox(
      width: 48,
      height: 48,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showMemberFilterBottomSheet(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: hasFilter
                  ? cyanAccent.withValues(alpha: 0.15)
                  : const Color(0xFF162032),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasFilter
                    ? cyanAccent
                    : Colors.white.withValues(alpha: 0.15),
                width: hasFilter ? 1.5 : 1.0,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.filter_list,
                  color: hasFilter
                      ? cyanAccent
                      : Colors.white.withValues(alpha: 0.85),
                  size: 22,
                ),
                if (hasFilter)
                  Positioned(
                    top: 9,
                    right: 9,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: cyanAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: cyanAccent.withValues(alpha: 0.6),
                            blurRadius: 4,
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMemberFilterBottomSheet(BuildContext context) {
    ActiveSurveyFilter tempActiveFilter = _activeFilter;
    HistorySurveyFilter tempHistoryFilter = _historyFilter;
    const cyanAccent = Color(0xFF00C2A8);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0B132B), Color(0xFF1C2541)],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 24,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag handle pill
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.24),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Header: Slider/Filter icon + "Filter Options" + Close (x) button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: cyanAccent.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: cyanAccent.withValues(
                                          alpha: 0.4,
                                        ),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.tune_rounded,
                                      color: cyanAccent,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Flexible(
                                    child: Text(
                                      'Filter Options',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Close',
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white70,
                                size: 22,
                              ),
                              onPressed: () => Navigator.pop(sheetContext),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Divider(
                          color: Colors.white.withValues(alpha: 0.1),
                          height: 1,
                        ),
                        const SizedBox(height: 16),

                        // Group 1: Participation Status
                        Row(
                          children: [
                            const Icon(
                              Icons.assignment_turned_in_outlined,
                              size: 16,
                              color: cyanAccent,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'PARTICIPATION STATUS',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildModalOptionTile(
                          title: 'All Questionnaires',
                          subtitle: 'Show all active questionnaires',
                          icon: Icons.all_inbox_rounded,
                          isSelected:
                              tempActiveFilter == ActiveSurveyFilter.all,
                          onTap: () => setModalState(
                            () => tempActiveFilter = ActiveSurveyFilter.all,
                          ),
                        ),
                        _buildModalOptionTile(
                          title: 'Available to Take',
                          subtitle: 'Not yet answered by current member',
                          icon: Icons.bolt_rounded,
                          isSelected:
                              tempActiveFilter == ActiveSurveyFilter.available,
                          onTap: () => setModalState(
                            () =>
                                tempActiveFilter = ActiveSurveyFilter.available,
                          ),
                        ),
                        _buildModalOptionTile(
                          title: 'Completed',
                          subtitle: 'Already submitted by current member',
                          icon: Icons.check_circle_outline_rounded,
                          isSelected:
                              tempActiveFilter == ActiveSurveyFilter.completed,
                          onTap: () => setModalState(
                            () =>
                                tempActiveFilter = ActiveSurveyFilter.completed,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Group 2: Submission History Timeline
                        Row(
                          children: [
                            const Icon(
                              Icons.history_rounded,
                              size: 16,
                              color: cyanAccent,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'SUBMISSION HISTORY TIMELINE',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildModalOptionTile(
                          title: 'All History',
                          subtitle: 'Complete chronological submission history',
                          icon: Icons.calendar_month_rounded,
                          isSelected:
                              tempHistoryFilter == HistorySurveyFilter.all,
                          onTap: () => setModalState(
                            () => tempHistoryFilter = HistorySurveyFilter.all,
                          ),
                        ),
                        _buildModalOptionTile(
                          title: 'Last 30 Days',
                          subtitle: 'Submitted within the past 30 days',
                          icon: Icons.event_available_rounded,
                          isSelected:
                              tempHistoryFilter ==
                              HistorySurveyFilter.last30Days,
                          onTap: () => setModalState(
                            () => tempHistoryFilter =
                                HistorySurveyFilter.last30Days,
                          ),
                        ),
                        _buildModalOptionTile(
                          title: 'This Year',
                          subtitle: 'Submitted during the current calendar year',
                          icon: Icons.date_range_rounded,
                          isSelected:
                              tempHistoryFilter == HistorySurveyFilter.thisYear,
                          onTap: () => setModalState(
                            () =>
                                tempHistoryFilter = HistorySurveyFilter.thisYear,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Footer Action Buttons: Reset + Apply Filters
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.25),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {
                                  setModalState(() {
                                    tempActiveFilter = ActiveSurveyFilter.all;
                                    tempHistoryFilter = HistorySurveyFilter.all;
                                  });
                                  setState(() {
                                    _activeFilter = ActiveSurveyFilter.all;
                                    _historyFilter = HistorySurveyFilter.all;
                                  });
                                },
                                child: const Text(
                                  'Reset',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: cyanAccent,
                                  foregroundColor: const Color(0xFF0B132B),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _activeFilter = tempActiveFilter;
                                    _historyFilter = tempHistoryFilter;
                                  });
                                  Navigator.pop(sheetContext);
                                },
                                child: const Text(
                                  'Apply Filters',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const cyanAccent = Color(0xFF00C2A8);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? cyanAccent.withValues(alpha: 0.15)
                  : const Color(0xFF162032).withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? cyanAccent
                    : Colors.white.withValues(alpha: 0.12),
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: isSelected ? cyanAccent : Colors.white70,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isSelected ? cyanAccent : Colors.white,
                          fontSize: 13.5,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.58),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  size: 19,
                  color: isSelected ? cyanAccent : Colors.white38,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSearchAndFilterToolbar({
    required int allCount,
    required int availableCount,
    required int completedCount,
    required bool isDark,
  }) {
    final cardBg = isDark ? const Color(0xFF13172E) : Colors.white;
    final inputBg = isDark
        ? const Color(0xFF0B132B).withValues(alpha: 0.8)
        : const Color(0xFFF8FAFC);
    const cyanAccent = Color(0xFF00C2A8);

    final Widget searchTextField = TextField(
      controller: _activeSearchController,
      maxLength: 100,
      onChanged: (val) => setState(() => _activeSearchQuery = val),
      style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF0F172A),
        fontSize: 13.5,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: 'Search surveys by title...',
        hintStyle: TextStyle(
          color: isDark ? Colors.white38 : Colors.black38,
          fontSize: 12.5,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: cyanAccent,
          size: 19,
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 38,
          minHeight: 38,
        ),
        suffixIcon: _activeSearchController.text.isNotEmpty
            ? IconButton(
                tooltip: 'Clear search',
                icon: Icon(
                  Icons.clear,
                  size: 18,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
                onPressed: () {
                  _activeSearchController.clear();
                  setState(() => _activeSearchQuery = '');
                },
              )
            : null,
        filled: true,
        fillColor: inputBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cyanAccent, width: 1.8),
        ),
      ),
    );

    final Widget filterIconButton = _buildFilterIconButton(isDark: isDark);

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search + Filter Row Layout
          Row(
            children: [
              Expanded(child: searchTextField),
              const SizedBox(width: 10),
              filterIconButton,
            ],
          ),
          const SizedBox(height: 12),

          // All 3 filter chips fit in one glance on a single row with zero clipping or overflow
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFilterChip(
                    label: 'All ($allCount)',
                    isSelected: _activeFilter == ActiveSurveyFilter.all,
                    onTap: () =>
                        setState(() => _activeFilter = ActiveSurveyFilter.all),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 6),
                  _buildFilterChip(
                    label: 'Available to Take ($availableCount)',
                    isSelected: _activeFilter == ActiveSurveyFilter.available,
                    onTap: () => setState(
                      () => _activeFilter = ActiveSurveyFilter.available,
                    ),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 6),
                  _buildFilterChip(
                    label: 'Completed ($completedCount)',
                    isSelected: _activeFilter == ActiveSurveyFilter.completed,
                    onTap: () => setState(
                      () => _activeFilter = ActiveSurveyFilter.completed,
                    ),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    const cyanAccent = Color(0xFF00C2A8);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? cyanAccent.withValues(alpha: 0.18)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? cyanAccent
                : (isDark ? Colors.white12 : Colors.black12),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            color: isSelected
                ? cyanAccent
                : (isDark ? Colors.white70 : Colors.black87),
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionnairesSectionHeader({
    required int availableCount,
    required bool isDark,
  }) {
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    const cyanAccent = Color(0xFF00C2A8);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              const Icon(Icons.quiz_outlined, color: cyanAccent, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Questionnaires',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 17.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: cyanAccent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cyanAccent.withValues(alpha: 0.45)),
          ),
          child: Text(
            'Available to Take: $availableCount',
            style: const TextStyle(
              color: cyanAccent,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveSurveyCard({
    required BuildContext context,
    required Survey survey,
    required int questionCount,
    required bool isAnswered,
    required bool isDark,
  }) {
    final cardBg = isDark ? const Color(0xFF13172E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    const cyanAccent = Color(0xFF00C2A8);
    const emeraldGreen = Color(0xFF10B981);

    final descriptionText = survey.description.trim().isNotEmpty
        ? survey.description.trim()
        : 'No additional description provided for this survey.';

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAnswered
              ? emeraldGreen.withValues(alpha: isDark ? 0.35 : 0.25)
              : cyanAccent.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.2,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Single-line Top Row: Status Pill + Date Range
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Status Pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (isAnswered ? emeraldGreen : cyanAccent).withValues(
                    alpha: 0.14,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (isAnswered ? emeraldGreen : cyanAccent)
                        .withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAnswered
                          ? Icons.check_circle_rounded
                          : Icons.bolt_rounded,
                      size: 13,
                      color: isAnswered ? emeraldGreen : cyanAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isAnswered ? 'Completed' : 'Open for Responses',
                      style: TextStyle(
                        color: isAnswered ? emeraldGreen : cyanAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Date Range: Calendar icon + <start_date> – <end_date or "No End Date">
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: mutedColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _formatDateRange(survey.startDate, survey.endDate),
                        style: TextStyle(
                          color: mutedColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title: Bold white text (survey.title)
          Text(
            survey.title,
            softWrap: true,
            style: TextStyle(
              color: textColor,
              fontSize: 17.5,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),

          // Description: Muted text
          Text(
            descriptionText,
            softWrap: true,
            style: TextStyle(
              color: mutedColor,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),

          // Footer Divider
          Divider(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 12),

          // Single-line Footer Row: Left Question(s) + Right Action Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.playlist_add_check_rounded,
                      size: 18,
                      color: cyanAccent,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '$questionCount Question(s)',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              if (isAnswered)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.black.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: mutedColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Already Submitted',
                        style: TextStyle(
                          color: mutedColor,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => MemberSurveyDetailsScreen(
                          survey: survey,
                          surveyId: survey.id,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cyanAccent,
                    foregroundColor: const Color(0xFF0F172A),
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Answer Survey →',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateCard({
    required IconData icon,
    required String title,
    required String message,
    required bool isDark,
  }) {
    final cardBg = isDark ? const Color(0xFF13172E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: const Color(0xFF00C2A8)),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            softWrap: true,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            softWrap: true,
            style: TextStyle(
              color: mutedColor,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionRecordsDivider(bool isDark) {
    final lineColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.12);
    const emeraldGreen = Color(0xFF10B981);

    return Row(
      children: [
        Expanded(child: Divider(color: lineColor, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: emeraldGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: emeraldGreen.withValues(alpha: 0.4),
              ),
            ),
            child: const Text(
              'Submission Records',
              style: TextStyle(
                color: emeraldGreen,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
        Expanded(child: Divider(color: lineColor, thickness: 1)),
      ],
    );
  }

  Widget _buildHistorySectionCard({
    required int totalSubmittedCount,
    required List<MemberSurveySubmission> filteredHistory,
    required Map<String, Survey> surveysById,
    required bool isDark,
  }) {
    final cardBg = isDark ? const Color(0xFF13172E) : Colors.white;
    final itemBg = isDark
        ? const Color(0xFF0B132B).withValues(alpha: 0.7)
        : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    const emeraldGreen = Color(0xFF10B981);
    const cyanAccent = Color(0xFF00C2A8);

    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row: Title "Survey History Log" + Green badge "X Submitted Survey(s)"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.history_edu_rounded,
                      color: emeraldGreen,
                      size: 21,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Survey History Log',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: emeraldGreen.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: emeraldGreen.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  '$totalSubmittedCount Submitted Survey(s)',
                  style: const TextStyle(
                    color: emeraldGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            'A complete chronological record of all your submitted cooperative questionnaires, feedback responses, and member inquiries.',
            softWrap: true,
            style: TextStyle(
              color: mutedColor,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),

          // History Search & Filter Bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _historySearchController,
                  maxLength: 100,
                  onChanged: (val) => setState(() => _historySearchQuery = val),
                  style: TextStyle(color: textColor, fontSize: 13.5),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'Search submitted history...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: emeraldGreen,
                      size: 19,
                    ),
                    suffixIcon: _historySearchController.text.isNotEmpty
                        ? IconButton(
                            tooltip: 'Clear search',
                            icon: Icon(
                              Icons.clear,
                              size: 18,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                            onPressed: () {
                              _historySearchController.clear();
                              setState(() => _historySearchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: itemBg,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: cyanAccent,
                        width: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _buildFilterIconButton(isDark: isDark),
            ],
          ),
          const SizedBox(height: 10),

          // All 3 History Filter Chips fit in one glance on a single row with zero clipping or overflow
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFilterChip(
                    label: 'All History ($totalSubmittedCount)',
                    isSelected: _historyFilter == HistorySurveyFilter.all,
                    onTap: () =>
                        setState(() => _historyFilter = HistorySurveyFilter.all),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 6),
                  _buildFilterChip(
                    label: 'Last 30 Days',
                    isSelected: _historyFilter == HistorySurveyFilter.last30Days,
                    onTap: () => setState(
                      () => _historyFilter = HistorySurveyFilter.last30Days,
                    ),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 6),
                  _buildFilterChip(
                    label: 'This Year',
                    isSelected: _historyFilter == HistorySurveyFilter.thisYear,
                    onTap: () => setState(
                      () => _historyFilter = HistorySurveyFilter.thisYear,
                    ),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Mandate #5: Survey History Log (Table-to-Card Conversion)
          if (totalSubmittedCount == 0)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: itemBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 36,
                    color: mutedColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No Survey History Yet — You have not submitted any survey responses yet.',
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: TextStyle(
                      color: mutedColor,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            )
          else if (filteredHistory.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: itemBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
              child: Text(
                'No submitted surveys match your current history filter.',
                textAlign: TextAlign.center,
                softWrap: true,
                style: TextStyle(
                  color: mutedColor,
                  fontSize: 13,
                ),
              ),
            )
          else
            ...filteredHistory.map((sub) {
              final survey = surveysById[sub.surveyId];
              final title =
                  survey?.title ?? 'Cooperative Survey #${sub.surveyId}';
              final desc = survey?.description.trim() ?? '';
              final truncatedDesc = desc.isNotEmpty
                  ? _truncateDescription(desc, maxChars: 90)
                  : '';
              final formattedSubmittedAt = DateFormat(
                'MMM d, yyyy • h:mm a',
              ).format(sub.submittedAt);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Container(
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: itemBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Survey Title + File icon
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: cyanAccent.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.description_outlined,
                              color: cyanAccent,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  softWrap: true,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (truncatedDesc.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    truncatedDesc,
                                    softWrap: true,
                                    style: TextStyle(
                                      color: mutedColor,
                                      fontSize: 12.5,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Single-line Status Badge ("Completed") & Submission Date
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: emeraldGreen.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: emeraldGreen.withValues(alpha: 0.45),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: emeraldGreen,
                                  size: 13,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Completed',
                                  style: TextStyle(
                                    color: emeraldGreen,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 12,
                                    color: mutedColor,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    formattedSubmittedAt,
                                    style: TextStyle(
                                      color: mutedColor,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
