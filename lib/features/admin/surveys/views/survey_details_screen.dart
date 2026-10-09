import 'package:cooperative_member_app/core/widgets/space_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cooperative_member_app/core/models/survey.dart';
import 'package:cooperative_member_app/features/admin/surveys/repositories/survey_repository.dart';

class SurveyDetailsScreen extends ConsumerStatefulWidget {
  final String surveyId;
  final String? initialTab;

  const SurveyDetailsScreen({Key? key, required this.surveyId, this.initialTab})
    : super(key: key);

  @override
  ConsumerState<SurveyDetailsScreen> createState() =>
      _SurveyDetailsScreenState();
}

class _SurveyDetailsScreenState extends ConsumerState<SurveyDetailsScreen> {
  int _activeTab = 0; // 0: Questions, 1: Responses, 2: Settings
  int _activeResponseSubTab = 0; // 0: Summary, 1: Question, 2: Individual
  int _totalMembers = 0;

  @override
  void initState() {
    super.initState();
    // Auto-generate mock data for Jane Doe on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = ref.read(surveyRepositoryProvider);
      repo.generateMockData(widget.surveyId);
    });

    if (widget.initialTab == 'responses') {
      _activeTab = 1;
    } else if (widget.initialTab == 'settings') {
      _activeTab = 2;
    }
    _loadStats();
  }

  Future<void> _loadStats() async {
    final repo = ref.read(surveyRepositoryProvider);
    final count = await repo.getTotalMembersCount();
    if (mounted) {
      setState(() {
        _totalMembers = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(surveyRepositoryProvider);

    return Scaffold(
      appBar: const SpaceAppBar(automaticallyImplyLeading: false),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<Survey>(
        stream: repo.watchSurvey(widget.surveyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            );
          }

          final survey = snapshot.data!;
          final participationRate = _totalMembers == 0
              ? 0.0
              : (survey.respondentsCount / _totalMembers) * 100;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(context, survey),
                SizedBox(height: 24),
                _buildTabs(survey),
                SizedBox(height: 24),
                if (_activeTab == 0)
                  _buildQuestionsTab(survey, repo)
                else if (_activeTab == 1)
                  _buildResponsesTab(survey, participationRate, repo)
                else
                  _buildSettingsTab(survey, repo),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _activeTab == 0
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFFC042FF),
              onPressed: () => _showQuestionBuilder(context, widget.surveyId),
              icon: Icon(
                Icons.add,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              label: Text(
                'Add Question',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildHeaderCard(BuildContext context, Survey survey) {
    final df = DateFormat('MMM dd, yyyy, h:mm a');
    final startStr = survey.startDate != null
        ? df.format(survey.startDate!)
        : 'No start date';
    final endStr = survey.endDate != null
        ? df.format(survey.endDate!)
        : 'No end date';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => context.pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    size: 16,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.assignment, color: Colors.pinkAccent, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'QUESTIONNAIRE MANAGEMENT',
                        style: TextStyle(
                          color: Colors.pinkAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.pinkAccent),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.list, color: Colors.pinkAccent, size: 14),
                    SizedBox(width: 4),
                    Text(
                      '${survey.questionsCount} Questions',
                      style: TextStyle(
                        color: Colors.pinkAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.greenAccent.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.greenAccent,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      survey.status == 'active'
                          ? 'Published'
                          : survey.status.capitalize(),
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Text(
            survey.title,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            survey.description.isEmpty ? 'No description' : survey.description,
            style: TextStyle(
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.calendar_month,
                    color: Colors.pinkAccent,
                    size: 14,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '$startStr — $endStr',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(Survey survey) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              title: 'Questions (${survey.questionsCount})',
              icon: Icons.list,
              isActive: _activeTab == 0,
              onTap: () => setState(() => _activeTab = 0),
            ),
          ),
          Expanded(
            child: _TabButton(
              title: 'Responses (${survey.respondentsCount})',
              icon: Icons.bar_chart,
              isActive: _activeTab == 1,
              onTap: () => setState(() => _activeTab = 1),
            ),
          ),
          Expanded(
            child: _TabButton(
              title: 'Settings',
              icon: Icons.settings,
              isActive: _activeTab == 2,
              onTap: () => setState(() => _activeTab = 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsTab(Survey survey, SurveyRepository repo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Question List (${survey.questionsCount})',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Configured survey items and response options',
          style: TextStyle(
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
        SizedBox(height: 16),
        StreamBuilder<List<SurveyQuestion>>(
          stream: repo.watchQuestions(survey.id),
          builder: (context, qSnapshot) {
            if (qSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            final questions = qSnapshot.data ?? [];
            if (questions.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'No questions added yet.',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.54),
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: List.generate(questions.length, (index) {
                final q = questions[index];
                return _QuestionCard(question: q, index: index + 1, repo: repo);
              }),
            );
          },
        ),
      ],
    );
  }

  Widget _buildResponsesTab(
    Survey survey,
    double participationRate,
    SurveyRepository repo,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${survey.respondentsCount} Responses',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Aggregated response summaries, question-level analysis, and individual answer sheets',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Colors.white24),
                ),
              ),
              onPressed: () {},
              icon: Icon(Icons.print, size: 16),
              label: Text('Print Report'),
            ),
          ],
        ),
        SizedBox(height: 24),
        Center(
          child: SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeResponseSubTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _activeResponseSubTab == 0
                            ? Colors.teal.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.teal.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.pie_chart,
                            color: _activeResponseSubTab == 0
                                ? Colors.tealAccent
                                : Theme.of(context).textTheme.bodyMedium?.color
                                      ?.withOpacity(0.6),
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Summary',
                              style: TextStyle(
                                fontSize: 12,
                                color: _activeResponseSubTab == 0
                                    ? Colors.tealAccent
                                    : Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color
                                          ?.withOpacity(0.6),
                                fontWeight: _activeResponseSubTab == 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeResponseSubTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _activeResponseSubTab == 1
                            ? Colors.teal.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.teal.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.list,
                            color: _activeResponseSubTab == 1
                                ? Colors.tealAccent
                                : Theme.of(context).textTheme.bodyMedium?.color
                                      ?.withOpacity(0.6),
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Question',
                              style: TextStyle(
                                fontSize: 12,
                                color: _activeResponseSubTab == 1
                                    ? Colors.tealAccent
                                    : Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color
                                          ?.withOpacity(0.6),
                                fontWeight: _activeResponseSubTab == 1
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeResponseSubTab = 2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _activeResponseSubTab == 2
                            ? Colors.teal.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.teal.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person,
                            color: _activeResponseSubTab == 2
                                ? Colors.tealAccent
                                : Theme.of(context).textTheme.bodyMedium?.color
                                      ?.withOpacity(0.6),
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Individual',
                              style: TextStyle(
                                fontSize: 12,
                                color: _activeResponseSubTab == 2
                                    ? Colors.tealAccent
                                    : Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color
                                          ?.withOpacity(0.6),
                                fontWeight: _activeResponseSubTab == 2
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 24),
        if (_activeResponseSubTab == 0) ...[
          _AutoScrollCards(
            survey: survey,
            participationRate: participationRate,
            totalMembers: _totalMembers,
          ),
          SizedBox(height: 16),
          StreamBuilder<List<SurveyQuestion>>(
            stream: repo.watchQuestions(survey.id),
            builder: (context, qSnapshot) {
              if (qSnapshot.connectionState == ConnectionState.waiting)
                return Center(child: CircularProgressIndicator());
              final questions = qSnapshot.data ?? [];
              if (questions.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'No questions added yet.',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withOpacity(0.54),
                      ),
                    ),
                  ),
                );
              }
              return Column(
                children: List.generate(questions.length, (index) {
                  return _ResponseTableRow(
                    question: questions[index],
                    index: index + 1,
                    repo: repo,
                  );
                }),
              );
            },
          ),
        ] else if (_activeResponseSubTab == 1) ...[
          _QuestionLevelAnalysis(surveyId: survey.id, repo: repo),
        ] else ...[
          _IndividualResponses(surveyId: survey.id, repo: repo),
        ],
      ],
    );
  }

  Widget _buildSettingsTab(Survey survey, SurveyRepository repo) {
    return _SurveySettingsForm(
      survey: survey,
      repo: repo,
      onPublish: () {
        setState(() => _activeTab = 0);
      },
    );
  }

  void _showQuestionBuilder(BuildContext context, String surveyId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => QuestionBuilderSheet(surveyId: surveyId),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.title,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.teal.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? Colors.tealAccent : Colors.grey,
            ),
            SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? Colors.tealAccent : Colors.grey,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final SurveyQuestion question;
  final int index;
  final SurveyRepository repo;

  const _QuestionCard({
    required this.question,
    required this.index,
    required this.repo,
  });

  @override
  Widget build(BuildContext context) {
    String getTypeDisplay(String type) {
      switch (type) {
        case 'description':
          return 'Description Type';
        case 'yes_no':
          return 'Yes/No';
        case 'rating':
          return 'Rating Scale (1 to 5, Lowest to Highest)';
        case 'multiple_choice':
          return 'Multiple Choice';
        default:
          return 'Text Answer (Open-ended)';
      }
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.pink.withOpacity(0.2),
              border: Border.all(color: Colors.pink.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Q$index',
              style: TextStyle(
                color: Colors.pinkAccent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 12),
          Text(
            question.question,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          if (question.type == 'multiple_choice') ...[
            StreamBuilder<List<SurveyChoice>>(
              stream: repo.watchChoices(question.id),
              builder: (context, snapshot) {
                final choices = snapshot.data ?? [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CONFIGURED CHOICES (${choices.length}):',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: choices
                          .map(
                            (c) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(color: Colors.white24),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                c.choiceText,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                );
              },
            ),
          ] else
            Text(
              getTypeDisplay(question.type),
              style: TextStyle(
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}

class _ResponseStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  const _ResponseStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.check,
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withOpacity(0.54),
                size: 14,
              ),
              SizedBox(width: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withOpacity(0.54),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResponseTableRow extends StatelessWidget {
  final SurveyQuestion question;
  final int index;
  final SurveyRepository repo;

  const _ResponseTableRow({
    required this.question,
    required this.index,
    required this.repo,
  });

  String _getTypeDisplay(String type) {
    switch (type) {
      case 'description':
        return 'Description Type';
      case 'yes_no':
        return 'Yes/No';
      case 'rating':
        return 'Rating Scale (1 to 5, Lowest to Highest)';
      case 'multiple_choice':
        return 'Multiple Choice';
      default:
        return 'Text Answer (Open-ended)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.pink.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Q$index',
                  style: TextStyle(
                    color: Colors.pinkAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  question.question,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('survey_answers')
                .where('question_id', isEqualTo: question.id)
                .snapshots(),
            builder: (context, answersSnapshot) {
              final answers = answersSnapshot.data?.docs ?? [];
              final totalAnswers = answers.length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TYPE: ${_getTypeDisplay(question.type)}',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'RESPONSES: $totalAnswers',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'INSIGHTS',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildInsights(context, answers, totalAnswers),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInsights(
    BuildContext context,
    List<QueryDocumentSnapshot> answers,
    int totalAnswers,
  ) {
    if (question.type == 'yes_no' || question.type == 'rating') {
      final choicesText = question.type == 'yes_no'
          ? ['Yes', 'No']
          : ['1', '2', '3', '4', '5'];
      final counts = <String, int>{};
      for (var a in answers) {
        final ans = a['answer'] as String? ?? '';
        counts[ans] = (counts[ans] ?? 0) + 1;
      }
      return Column(
        children: choicesText.map((choice) {
          final count = counts[choice] ?? 0;
          final pct = totalAnswers > 0
              ? (count / totalAnswers * 100).toStringAsFixed(0)
              : '0';
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    choice,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  '$count ($pct%)',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    if (question.type != 'multiple_choice') {
      return Text(
        'Text responses... ($totalAnswers)',
        style: TextStyle(
          color: Theme.of(
            context,
          ).textTheme.bodyMedium?.color?.withOpacity(0.6),
          fontSize: 12,
        ),
      );
    }

    return StreamBuilder<List<SurveyChoice>>(
      stream: repo.watchChoices(question.id),
      builder: (context, snapshot) {
        final choices = snapshot.data ?? [];
        if (choices.isEmpty)
          return Text(
            'No choices',
            style: TextStyle(
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withOpacity(0.6),
              fontSize: 12,
            ),
          );

        // Count answers for each choice
        final counts = <String, int>{};
        for (var a in answers) {
          final ans = a['answer'] as String? ?? '';
          counts[ans] = (counts[ans] ?? 0) + 1;
        }

        return Column(
          children: choices.map((c) {
            final count = counts[c.choiceText] ?? 0;
            final pct = totalAnswers > 0
                ? (count / totalAnswers * 100).toStringAsFixed(0)
                : '0';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      c.choiceText,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    '$count ($pct%)',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class QuestionBuilderSheet extends ConsumerStatefulWidget {
  final String surveyId;

  const QuestionBuilderSheet({Key? key, required this.surveyId})
    : super(key: key);

  @override
  ConsumerState<QuestionBuilderSheet> createState() =>
      _QuestionBuilderSheetState();
}

class _QuestionBuilderSheetState extends ConsumerState<QuestionBuilderSheet> {
  final _questionController = TextEditingController();
  String _selectedType = 'multiple_choice';
  final List<TextEditingController> _choiceControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.add_box, color: Colors.tealAccent),
                SizedBox(width: 8),
                Text(
                  'Add Question',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Divider(color: Colors.white10),
            SizedBox(height: 16),
            Text(
              'Question Text *',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _questionController,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Question Type *',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedType,
                  dropdownColor: Theme.of(context).scaffoldBackgroundColor,
                  isExpanded: true,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'description',
                      child: Text('Description Type'),
                    ),
                    DropdownMenuItem(value: 'yes_no', child: Text('Yes/No')),
                    DropdownMenuItem(
                      value: 'rating',
                      child: Text('Rating Scale (1 to 5, Lowest to Highest)'),
                    ),
                    DropdownMenuItem(
                      value: 'multiple_choice',
                      child: Text('Multiple Choice'),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedType = val!;
                    });
                  },
                ),
              ),
            ),
            if (_selectedType == 'multiple_choice') ...[
              SizedBox(height: 16),
              Text(
                'Choices',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              ...List.generate(_choiceControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _choiceControllers[index],
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Option ${index + 1}',
                            hintStyle: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color?.withOpacity(0.38),
                            ),
                            filled: true,
                            fillColor: Theme.of(
                              context,
                            ).scaffoldBackgroundColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Colors.white24,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Colors.white24,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.remove_circle,
                          color: Colors.redAccent,
                        ),
                        onPressed: () {
                          if (_choiceControllers.length > 2) {
                            setState(() {
                              _choiceControllers.removeAt(index);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                );
              }),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.tealAccent),
                onPressed: () {
                  setState(() {
                    _choiceControllers.add(TextEditingController());
                  });
                },
                icon: Icon(Icons.add),
                label: Text('Add another option'),
              ),
            ],
            SizedBox(height: 24),
            Divider(color: Colors.white10),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.54),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC042FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: _saveQuestion,
                  child: Text(
                    'Save Question',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _saveQuestion() async {
    if (_questionController.text.isEmpty) return;

    List<String> choices = [];
    if (_selectedType == 'multiple_choice') {
      choices = _choiceControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();
      if (choices.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Add at least two options for multiple choice.'),
          ),
        );
        return;
      }
    }

    final newQuestion = SurveyQuestion(
      id: '',
      surveyId: widget.surveyId,
      question: _questionController.text,
      type: _selectedType,
    );

    await ref.read(surveyRepositoryProvider).addQuestion(newQuestion, choices);

    if (mounted) {
      Navigator.pop(context);
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

class _AutoScrollCards extends StatefulWidget {
  final Survey survey;
  final double participationRate;
  final int totalMembers;

  const _AutoScrollCards({
    Key? key,
    required this.survey,
    required this.participationRate,
    required this.totalMembers,
  }) : super(key: key);

  @override
  State<_AutoScrollCards> createState() => _AutoScrollCardsState();
}

class _AutoScrollCardsState extends State<_AutoScrollCards> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (!mounted) return;
      if (_currentPage < 2) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> cards = [
      _ResponseStatCard(
        title: 'TOTAL RESPONDENTS',
        value: '${widget.survey.respondentsCount}',
        subtitle: 'Completed submissions',
        icon: Icons.people,
        iconColor: Colors.purpleAccent,
      ),
      _ResponseStatCard(
        title: 'PARTICIPATION RATE',
        value: '${widget.participationRate.toStringAsFixed(1)}%',
        subtitle: 'Of ${widget.totalMembers} active members',
        icon: Icons.pie_chart,
        iconColor: Colors.lightBlueAccent,
      ),
      _ResponseStatCard(
        title: 'TOTAL QUESTIONS',
        value: '${widget.survey.questionsCount}',
        subtitle: 'Live calculated items',
        icon: Icons.list,
        iconColor: Colors.greenAccent,
      ),
    ];

    return Column(
      children: [
        SizedBox(
          height: 120,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) {
              if (mounted) {
                setState(() {
                  _currentPage = page;
                });
              }
            },
            itemCount: cards.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: cards[index],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(cards.length, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              width: 8.0,
              height: 8.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index
                    ? Colors.tealAccent
                    : Colors.white24,
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _SurveySettingsForm extends StatefulWidget {
  final Survey survey;
  final SurveyRepository repo;
  final VoidCallback onPublish;

  const _SurveySettingsForm({
    Key? key,
    required this.survey,
    required this.repo,
    required this.onPublish,
  }) : super(key: key);

  @override
  State<_SurveySettingsForm> createState() => _SurveySettingsFormState();
}

class _SurveySettingsFormState extends State<_SurveySettingsForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late String _status;
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.survey.title);
    _descController = TextEditingController(text: widget.survey.description);
    _status = widget.survey.status;
    _startDate = widget.survey.startDate;
    _endDate = widget.survey.endDate;
    if (_startDate != null) {
      _startTime = TimeOfDay.fromDateTime(_startDate!);
    }
    if (_endDate != null) {
      _endTime = TimeOfDay.fromDateTime(_endDate!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    DateTime? finalStart;
    if (_startDate != null) {
      finalStart = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
        _startTime?.hour ?? 0,
        _startTime?.minute ?? 0,
      );
    }
    DateTime? finalEnd;
    if (_endDate != null) {
      finalEnd = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
        _endTime?.hour ?? 23,
        _endTime?.minute ?? 59,
      );
    }

    final updated = widget.survey.copyWith(
      title: _titleController.text,
      description: _descController.text,
      status: _status,
      startDate: finalStart,
      endDate: finalEnd,
    );

    await widget.repo.updateSurvey(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
    }
  }

  Widget _buildDateField(
    String label,
    DateTime? date,
    ValueChanged<DateTime?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (d != null) onChanged(d);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date != null
                      ? DateFormat('MM/dd/yyyy').format(date)
                      : 'Select Date',
                ),
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.white54,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField(
    String label,
    TimeOfDay? time,
    ValueChanged<TimeOfDay?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final t = await showTimePicker(
              context: context,
              initialTime: time ?? TimeOfDay.now(),
            );
            if (t != null) onChanged(t);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(time != null ? time.format(context) : 'Select Time'),
                const Icon(Icons.access_time, size: 16, color: Colors.white54),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, color: Colors.pinkAccent),
              const SizedBox(width: 8),
              const Text(
                'Survey Settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Survey Title *',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          const Text(
            'Survey Status *',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _status,
            items: const [
              DropdownMenuItem(
                value: 'draft',
                child: Text('Draft (Unpublished)'),
              ),
              DropdownMenuItem(
                value: 'active',
                child: Text('Active (Published)'),
              ),
              DropdownMenuItem(value: 'closed', child: Text('Closed')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _status = v);
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Description / Instructions',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descController,
            maxLines: 4,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  'Opening Date *',
                  _startDate,
                  (d) => setState(() => _startDate = d),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTimeField(
                  'Opening Time *',
                  _startTime,
                  (t) => setState(() => _startTime = t),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  'Closing Date *',
                  _endDate,
                  (d) => setState(() => _endDate = d),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTimeField(
                  'Closing Time *',
                  _endTime,
                  (t) => setState(() => _endTime = t),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  await widget.repo.generateMockData(widget.survey.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mock Data Generated (Jane Doe)'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.add_reaction),
                label: const Text('Generate Mock Data'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC042FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _saveChanges,
                icon: const Icon(Icons.save),
                label: const Text(
                  'Save Changes',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuestionLevelAnalysis extends StatefulWidget {
  final String surveyId;
  final SurveyRepository repo;

  const _QuestionLevelAnalysis({required this.surveyId, required this.repo});

  @override
  State<_QuestionLevelAnalysis> createState() => _QuestionLevelAnalysisState();
}

class _QuestionLevelAnalysisState extends State<_QuestionLevelAnalysis> {
  bool _isLoading = true;
  List<SurveyQuestion> _questions = [];
  List<Map<String, dynamic>> _answers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final questionsQuery = await FirebaseFirestore.instance
        .collection('survey_questions')
        .where('survey_id', isEqualTo: widget.surveyId)
        .get();
    _questions = questionsQuery.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return SurveyQuestion.fromJson(data);
    }).toList();

    final responsesQuery = await FirebaseFirestore.instance
        .collection('survey_responses')
        .where('survey_id', isEqualTo: widget.surveyId)
        .get();
    final responseIds = responsesQuery.docs.map((doc) => doc.id).toList();

    _answers = [];
    if (responseIds.isNotEmpty) {
      final answersQuery = await FirebaseFirestore.instance
          .collection('survey_answers')
          .where('response_id', whereIn: responseIds)
          .get();
      _answers = answersQuery.docs.map((doc) => doc.data()).toList();
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_questions.isEmpty)
      return const Center(child: Text('No questions available.'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _questions.map((q) => _buildQuestionStats(q)).toList(),
    );
  }

  Widget _buildQuestionStats(SurveyQuestion q) {
    final qAnswers = _answers.where((a) => a['question_id'] == q.id).toList();
    final totalAnswers = qAnswers.length;

    Widget statWidget = const SizedBox();

    if (q.type == 'description') {
      int totalWords = 0;
      for (var a in qAnswers) {
        final text = (a['answer'] as String? ?? '');
        if (text.trim().isNotEmpty) {
          totalWords += text.trim().split(RegExp(r'\s+')).length;
        }
      }
      final avg = totalAnswers > 0
          ? (totalWords / totalAnswers).toStringAsFixed(1)
          : '0';
      statWidget = Text(
        'Average Word Count: $avg words',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.tealAccent,
        ),
      );
    } else {
      final counts = <String, int>{};
      for (var a in qAnswers) {
        final ans = a['answer'] as String? ?? 'N/A';
        counts[ans] = (counts[ans] ?? 0) + 1;
      }
      final sortedKeys = counts.keys.toList()
        ..sort((a, b) => counts[b]!.compareTo(counts[a]!));

      statWidget = Column(
        children: sortedKeys.map((key) {
          final count = counts[key]!;
          final pct = totalAnswers > 0 ? count / totalAnswers : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(key, style: const TextStyle(fontSize: 12)),
                ),
                Expanded(
                  flex: 5,
                  child: Stack(
                    children: [
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: pct,
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.tealAccent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    ' $count (${(pct * 100).toStringAsFixed(0)}%)',
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            q.question,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            '$totalAnswers responses',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 12),
          statWidget,
        ],
      ),
    );
  }
}

class _IndividualResponses extends StatefulWidget {
  final String surveyId;
  final SurveyRepository repo;

  const _IndividualResponses({required this.surveyId, required this.repo});

  @override
  State<_IndividualResponses> createState() => _IndividualResponsesState();
}

class _IndividualResponsesState extends State<_IndividualResponses> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _responses = [];
  Map<String, dynamic>? _selectedResponse;
  List<SurveyQuestion> _questions = [];
  List<Map<String, dynamic>> _answers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final responsesQuery = await FirebaseFirestore.instance
        .collection('survey_responses')
        .where('survey_id', isEqualTo: widget.surveyId)
        .get();
    _responses = responsesQuery.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();

    final questionsQuery = await FirebaseFirestore.instance
        .collection('survey_questions')
        .where('survey_id', isEqualTo: widget.surveyId)
        .get();
    _questions = questionsQuery.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return SurveyQuestion.fromJson(data);
    }).toList();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAnswers(String responseId) async {
    final answersQuery = await FirebaseFirestore.instance
        .collection('survey_answers')
        .where('response_id', isEqualTo: responseId)
        .get();
    setState(() {
      _answers = answersQuery.docs.map((doc) => doc.data()).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_responses.isEmpty)
      return const Center(child: Text('No individual responses yet.'));

    if (_selectedResponse == null) {
      return Column(
        children: _responses.map((resp) {
          final submitted = resp['submitted_at'] as Timestamp?;
          final dateStr = submitted != null
              ? DateFormat('MMM dd, yyyy').format(submitted.toDate())
              : 'Unknown';
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              child: Icon(Icons.person),
              backgroundColor: Colors.teal,
            ),
            title: Text(
              resp['member_name'] ?? 'Unknown Member',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Submitted on $dateStr'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              setState(() {
                _selectedResponse = resp;
              });
              _loadAnswers(resp['id']);
            },
          );
        }).toList(),
      );
    } else {
      final submitted = _selectedResponse!['submitted_at'] as Timestamp?;
      final dateStr = submitted != null
          ? DateFormat('MMM dd, yyyy h:mm a').format(submitted.toDate())
          : 'Unknown';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                padding: EdgeInsets.zero,
                onPressed: () => setState(() => _selectedResponse = null),
              ),
              Expanded(
                child: Text(
                  _selectedResponse!['member_name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 48.0, bottom: 16.0),
            child: Text(
              'Submitted: $dateStr',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          ..._questions.map((q) {
            final a = _answers.firstWhere(
              (ans) => ans['question_id'] == q.id,
              orElse: () => {},
            );
            final ansText = a['answer'] as String? ?? 'No Answer';
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q.question,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ansText,
                    style: const TextStyle(color: Colors.tealAccent),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      );
    }
  }
}
