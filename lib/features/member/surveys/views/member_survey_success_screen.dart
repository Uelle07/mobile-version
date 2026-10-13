import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/space_app_bar.dart';
import '../../../admin/surveys/repositories/survey_repository.dart';
import '../../dashboard/providers/current_member_provider.dart';

class MemberSurveySuccessScreen extends ConsumerStatefulWidget {
  final String surveyId;
  final SurveyReceiptData? initialReceiptData;

  const MemberSurveySuccessScreen({
    super.key,
    required this.surveyId,
    this.initialReceiptData,
  });

  @override
  ConsumerState<MemberSurveySuccessScreen> createState() =>
      _MemberSurveySuccessScreenState();
}

class _MemberSurveySuccessScreenState
    extends ConsumerState<MemberSurveySuccessScreen> {
  SurveyReceiptData? _receiptData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialReceiptData != null) {
      _receiptData = widget.initialReceiptData;
    } else {
      _loadReceiptFromFirestore();
    }
  }

  Future<void> _loadReceiptFromFirestore() async {
    setState(() => _isLoading = true);
    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      final member = ref.read(currentMemberProvider).value;
      final ids = <String>[
        if (currentUid != null && currentUid.isNotEmpty) currentUid,
        if (member != null && member.id.isNotEmpty) member.id,
      ];
      final repo = ref.read(surveyRepositoryProvider);
      final data = await repo.fetchSurveyReceiptData(widget.surveyId, ids);
      if (mounted) {
        setState(() {
          _receiptData = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _receiptData = SurveyReceiptData(
            surveyId: widget.surveyId,
            surveyTitle: 'Cooperative Survey',
            completedItemsCount: 0,
            submittedAt: DateTime.now(),
          );
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToAvailableSurveys(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      GoRouter.of(context).go('/member/surveys');
    }
  }

  void _navigateToMemberDashboard(BuildContext context) {
    GoRouter.of(context).go('/member');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF13172E) : Colors.white;
    final receiptBg = isDark
        ? const Color(0xFF0B132B).withValues(alpha: 0.75)
        : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    const tealAccent = Color(0xFF00C2A8);
    const emeraldGreen = Color(0xFF10B981);

    final receipt = _receiptData;
    final formattedDate = receipt != null
        ? DateFormat('MMM d, yyyy • h:mm a').format(receipt.submittedAt)
        : DateFormat('MMM d, yyyy • h:mm a').format(DateTime.now());

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: isDark
          ? const Color(0xFF0B132B)
          : const Color(0xFFF1F5F9),
      appBar: const SpaceAppBar(
        title: Text('Submission Receipt'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 80.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: tealAccent.withValues(
                            alpha: isDark ? 0.45 : 0.3,
                          ),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: tealAccent.withValues(
                              alpha: isDark ? 0.16 : 0.08,
                            ),
                            blurRadius: 24,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Top glowing accent bar
                            Container(
                              height: 4,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF00C2A8),
                                    Color(0xFF10B981),
                                    Color(0xFF38BDF8),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Centered 80x80 circular glowing teal badge with checkmark icon
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: tealAccent.withValues(alpha: 0.14),
                                      border: Border.all(
                                        color: tealAccent,
                                        width: 2.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: tealAccent.withValues(
                                            alpha: 0.38,
                                          ),
                                          blurRadius: 22,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.check_rounded,
                                        color: tealAccent,
                                        size: 44,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Title
                                  Text(
                                    'Survey Submitted Successfully',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      height: 1.25,
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // Subtitle
                                  Text(
                                    'Thank you for your valuable participation. Your feedback has been securely registered and recorded into the cooperative system.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: mutedColor,
                                      fontSize: 13.5,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Structured Receipt Box
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(18.0),
                                    decoration: BoxDecoration(
                                      color: receiptBg,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.1,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.08,
                                              ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _buildReceiptRow(
                                          label: 'Survey Title',
                                          valueWidget: Text(
                                            receipt?.surveyTitle ??
                                                'Cooperative Survey',
                                            textAlign: TextAlign.right,
                                            softWrap: true,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          mutedColor: mutedColor,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12.0,
                                          ),
                                          child: Divider(
                                            height: 1,
                                            color: isDark
                                                ? Colors.white.withValues(
                                                    alpha: 0.08,
                                                  )
                                                : Colors.black.withValues(
                                                    alpha: 0.06,
                                                  ),
                                          ),
                                        ),
                                        _buildReceiptRow(
                                          label: 'Completed Items',
                                          valueWidget: Text(
                                            '✔ ${receipt?.completedItemsCount ?? 0} Questions',
                                            textAlign: TextAlign.right,
                                            softWrap: true,
                                            style: const TextStyle(
                                              color: tealAccent,
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          mutedColor: mutedColor,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12.0,
                                          ),
                                          child: Divider(
                                            height: 1,
                                            color: isDark
                                                ? Colors.white.withValues(
                                                    alpha: 0.08,
                                                  )
                                                : Colors.black.withValues(
                                                    alpha: 0.06,
                                                  ),
                                          ),
                                        ),
                                        _buildReceiptRow(
                                          label: 'Submission Time',
                                          valueWidget: Text(
                                            '🕒 $formattedDate',
                                            textAlign: TextAlign.right,
                                            softWrap: true,
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          mutedColor: mutedColor,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12.0,
                                          ),
                                          child: Divider(
                                            height: 1,
                                            color: isDark
                                                ? Colors.white.withValues(
                                                    alpha: 0.08,
                                                  )
                                                : Colors.black.withValues(
                                                    alpha: 0.06,
                                                  ),
                                          ),
                                        ),
                                        _buildReceiptRow(
                                          label: 'Record Status',
                                          valueWidget: Align(
                                            alignment: Alignment.centerRight,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: emeraldGreen.withValues(
                                                  alpha: 0.15,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: emeraldGreen
                                                      .withValues(alpha: 0.5),
                                                ),
                                              ),
                                              child: const Text(
                                                '🛡 Verified & Saved',
                                                softWrap: true,
                                                style: TextStyle(
                                                  color: emeraldGreen,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                          mutedColor: mutedColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Bottom Navigation Buttons (Expanded in Row or stacked on very small widths)
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final availableSurveysBtn =
                                          OutlinedButton.icon(
                                            onPressed: () =>
                                                _navigateToAvailableSurveys(
                                                  context,
                                                ),
                                            icon: const Icon(
                                              Icons.assignment_outlined,
                                              size: 18,
                                            ),
                                            label: const Flexible(
                                              child: Text(
                                                'Available Surveys',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: tealAccent,
                                              side: BorderSide(
                                                color: tealAccent.withValues(
                                                  alpha: 0.6,
                                                ),
                                                width: 1.5,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 14,
                                                    horizontal: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          );

                                      final dashboardBtn = ElevatedButton.icon(
                                        onPressed: () =>
                                            _navigateToMemberDashboard(context),
                                        icon: const Icon(
                                          Icons.dashboard_outlined,
                                          size: 18,
                                        ),
                                        label: const Flexible(
                                          child: Text(
                                            'Member Dashboard',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: tealAccent,
                                          foregroundColor: const Color(
                                            0xFF0F172A,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                            horizontal: 12,
                                          ),
                                          elevation: 3,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      );

                                      if (constraints.maxWidth < 340) {
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            availableSurveysBtn,
                                            const SizedBox(height: 10),
                                            dashboardBtn,
                                          ],
                                        );
                                      }

                                      return Row(
                                        children: [
                                          Expanded(child: availableSurveysBtn),
                                          const SizedBox(width: 12),
                                          Expanded(child: dashboardBtn),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow({
    required String label,
    required Widget valueWidget,
    required Color mutedColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          flex: 4,
          child: Text(
            label,
            softWrap: true,
            style: TextStyle(
              color: mutedColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 6,
          child: valueWidget,
        ),
      ],
    );
  }
}
