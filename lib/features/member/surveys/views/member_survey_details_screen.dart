import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/survey.dart';
import '../../../admin/members/repositories/member_repository.dart';
import '../../../admin/surveys/providers/survey_provider.dart';
import '../../../admin/surveys/repositories/survey_repository.dart';
import '../../dashboard/providers/current_member_provider.dart';
import 'package:cooperative_member_app/core/widgets/space_app_bar.dart';

class MemberSurveyDetailsScreen extends ConsumerStatefulWidget {
  final Survey survey;

  const MemberSurveyDetailsScreen({super.key, required this.survey});

  @override
  ConsumerState<MemberSurveyDetailsScreen> createState() =>
      _MemberSurveyDetailsScreenState();
}

class _MemberSurveyDetailsScreenState
    extends ConsumerState<MemberSurveyDetailsScreen> {
  final Map<String, String> _answers = {};
  bool _isSubmitting = false;
  final _formKey = GlobalKey<FormState>();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found. Please log in again.')),
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

      final memberId = (member != null && member.id.isNotEmpty)
          ? member.id
          : currentUser.uid;
      final memberName = (member != null &&
              '${member.firstName} ${member.lastName}'.trim().isNotEmpty)
          ? '${member.firstName} ${member.lastName}'.trim()
          : (currentUser.displayName?.isNotEmpty == true
              ? currentUser.displayName!
              : (currentUser.email?.split('@').first ?? 'Member'));

      final repository = ref.read(surveyRepositoryProvider);
      await repository.submitSurveyResponse(
        surveyId: widget.survey.id,
        memberId: memberId,
        memberName: memberName,
        answers: _answers,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Survey submitted successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
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
    final primaryColor = Theme.of(context).primaryColor;
    final questionsAsync = ref.watch(surveyQuestionsProvider(widget.survey.id));

    return Scaffold(
      appBar: SpaceAppBar(
        title: Text(widget.survey.title),
      ),
      body: questionsAsync.when(
        data: (questions) {
          if (questions.isEmpty) {
            return const Center(
              child: Text('No questions found for this survey.'),
            );
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Top Survey Hero Header Card (matching web take_survey.php)
                _buildSurveyHeaderCard(
                  context,
                  questions.length,
                  primaryColor,
                  isDark,
                ),
                const SizedBox(height: 20),

                // Question Cards
                ...questions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final question = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildQuestionCard(
                      context,
                      question,
                      index + 1,
                      primaryColor,
                      isDark,
                    ),
                  );
                }),

                // Submit Button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor:
                            ThemeData.estimateBrightnessForColor(primaryColor) ==
                                    Brightness.dark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Submit Survey',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildSurveyHeaderCard(
    BuildContext context,
    int questionCount,
    Color primaryColor,
    bool isDark,
  ) {
    final cardBg = isDark ? const Color(0xFF13172E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];

    String formattedEndDate = 'No End Date';
    if (widget.survey.endDate != null) {
      formattedEndDate =
          DateFormat('M/d/y, h:mm:ss a').format(widget.survey.endDate!);
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withValues(alpha: isDark ? 0.45 : 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: isDark ? 0.18 : 0.08),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Glowing neon top accent bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 3.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor,
                      primaryColor.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Circular Avatar / Icon
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withValues(alpha: 0.15),
                      border: Border.all(
                        color: primaryColor,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.35),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.quiz_outlined,
                        color: primaryColor,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Info Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Active Member Survey Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.5),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.2),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: primaryColor,
                                size: 13,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  'ACTIVE MEMBER SURVEY',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Survey Title
                        Text(
                          widget.survey.title,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // Survey Description (if any)
                        if (widget.survey.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.survey.description,
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),

                        // Meta details (Closes & Question Count)
                        Wrap(
                          spacing: 14,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 13,
                                  color: primaryColor,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Closes: $formattedEndDate',
                                  style: TextStyle(
                                    color: subtitleColor,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.format_list_bulleted,
                                  size: 14,
                                  color: primaryColor,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '$questionCount Question(s)',
                                  style: TextStyle(
                                    color: subtitleColor,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
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

  Widget _buildQuestionCard(
    BuildContext context,
    SurveyQuestion question,
    int questionNumber,
    Color primaryColor,
    bool isDark,
  ) {
    final cardBg = isDark ? const Color(0xFF13172E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.08);

    String typeLabel;
    IconData typeIcon;
    switch (question.type.toLowerCase()) {
      case 'multiple_choice':
        typeLabel = 'MULTIPLE CHOICE';
        typeIcon = Icons.list_alt;
        break;
      case 'yes_no':
        typeLabel = 'YES / NO';
        typeIcon = Icons.thumbs_up_down_outlined;
        break;
      case 'rating':
        typeLabel = 'RATING (1 - 5)';
        typeIcon = Icons.star_outline;
        break;
      default:
        typeLabel = 'OPEN ENDED';
        typeIcon = Icons.edit_note;
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar: Question Number pill + Question Type pill
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  'Q$questionNumber',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      typeIcon,
                      size: 13,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      typeLabel,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Question Prompt
          Text(
            question.question,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15.5,
              color: textColor,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),

          // Input Control
          _buildInputControl(question, primaryColor, isDark),
        ],
      ),
    );
  }

  Widget _buildInputControl(
    SurveyQuestion question,
    Color primaryColor,
    bool isDark,
  ) {
    final inputBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? Colors.white24 : Colors.black26;

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: inputBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );

    if (question.type == 'multiple_choice') {
      return Consumer(
        builder: (context, ref, child) {
          final choicesAsync = ref.watch(surveyChoicesProvider(question.id));
          return choicesAsync.when(
            data: (choices) {
              if (choices.isEmpty) {
                return const Text('No choices available.');
              }
              return DropdownButtonFormField<String>(
                decoration: inputDecoration,
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                items: choices.map((c) {
                  return DropdownMenuItem(
                    value: c.choiceText,
                    child: Text(
                      c.choiceText,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    _answers[question.id] = val;
                  }
                },
                onSaved: (val) {
                  if (val != null) {
                    _answers[question.id] = val;
                  }
                },
                validator: (val) =>
                    val == null ? 'Please select an option' : null,
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, s) => Text('Error loading choices: $e'),
          );
        },
      );
    } else if (question.type == 'yes_no') {
      return DropdownButtonFormField<String>(
        decoration: inputDecoration,
        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        items: const [
          DropdownMenuItem(value: 'Yes', child: Text('Yes')),
          DropdownMenuItem(value: 'No', child: Text('No')),
        ],
        onChanged: (val) {
          if (val != null) {
            _answers[question.id] = val;
          }
        },
        onSaved: (val) {
          if (val != null) {
            _answers[question.id] = val;
          }
        },
        validator: (val) => val == null ? 'Please select Yes or No' : null,
      );
    } else if (question.type == 'rating') {
      return DropdownButtonFormField<String>(
        decoration: inputDecoration,
        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        items: List.generate(5, (index) => (index + 1).toString()).map((r) {
          return DropdownMenuItem(value: r, child: Text(r));
        }).toList(),
        onChanged: (val) {
          if (val != null) {
            _answers[question.id] = val;
          }
        },
        onSaved: (val) {
          if (val != null) {
            _answers[question.id] = val;
          }
        },
        validator: (val) => val == null ? 'Please select a rating' : null,
      );
    } else {
      // Default to text input
      return TextFormField(
        decoration: inputDecoration.copyWith(
          hintText: 'Enter your answer',
        ),
        maxLines: question.type == 'description' ? 3 : 1,
        onChanged: (val) {
          _answers[question.id] = val.trim();
        },
        onSaved: (val) {
          if (val != null) {
            _answers[question.id] = val.trim();
          }
        },
        validator: (val) {
          if (val == null || val.trim().isEmpty) {
            return 'Please enter an answer';
          }
          return null;
        },
      );
    }
  }
}
