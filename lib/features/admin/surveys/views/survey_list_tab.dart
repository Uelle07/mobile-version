import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cooperative_member_app/core/models/survey.dart';
import '../providers/survey_provider.dart';
import '../repositories/survey_repository.dart';

class SurveyListTab extends ConsumerStatefulWidget {
  const SurveyListTab({super.key});

  @override
  ConsumerState<SurveyListTab> createState() => _SurveyListTabState();
}

class _SurveyListTabState extends ConsumerState<SurveyListTab> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final surveysAsync = ref.watch(surveysProvider);

    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).scaffoldBackgroundColor, // Web-like dark background
      body: surveysAsync.when(
        data: (surveys) {
          // Calculate Stats
          final totalSurveys = surveys.length;
          final activeSurveys = surveys
              .where((s) => s.status == 'active')
              .length;
          final draftSurveys = surveys
              .where((s) => s.status == 'draft' || s.status == 'closed')
              .length;
          final totalRespondents = surveys.fold<int>(
            0,
            (sum, s) => sum + s.respondentsCount,
          );

          // Filter
          final filteredSurveys = surveys
              .where(
                (s) =>
                    s.title.toLowerCase().contains(_searchQuery.toLowerCase()),
              )
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                SizedBox(height: 24),
                _buildStatsCards(
                  total: totalSurveys,
                  active: activeSurveys,
                  respondents: totalRespondents,
                  drafts: draftSurveys,
                ),
                SizedBox(height: 24),
                _buildSearchBar(),
                SizedBox(height: 16),
                _buildMainTable(filteredSurveys, ref, context),
                SizedBox(height: 32),
                _buildLivePreviewSection(filteredSurveys),
              ],
            ),
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            'Error: $err',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cooperative Member Survey',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),
              Text(
                'Manage and analyze member feedback surveys',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        SizedBox(width: 16),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC042FF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onPressed: () => _showCreateSurveyModal(context),
          icon: Icon(Icons.add, size: 18),
          label: Text('Create New Survey'),
        ),
      ],
    );
  }

  Widget _buildStatsCards({
    required int total,
    required int active,
    required int respondents,
    required int drafts,
  }) {
    return _StatsCarousel(
      total: total,
      active: active,
      respondents: respondents,
      drafts: drafts,
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: TextField(
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search surveys by title...',
                hintStyle: TextStyle(
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withOpacity(0.38),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withOpacity(0.38),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
          ),
          child: IconButton(
            icon: Icon(
              Icons.filter_list,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildMainTable(
    List<Survey> surveys,
    WidgetRef ref,
    BuildContext context,
  ) {
    if (surveys.isEmpty) {
      return Center(
        child: Text(
          'No surveys found.',
          style: TextStyle(
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withOpacity(0.54),
          ),
        ),
      );
    }
    return Column(
      children: surveys
          .map(
            (s) => Container(
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          s.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildStatusChip(s.status),
                    ],
                  ),
                  SizedBox(height: 12),
                  _buildSchedule(s.startDate, s.endDate),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildBadge(
                            Icons.list,
                            '${s.questionsCount}',
                            Colors.blue,
                          ),
                          SizedBox(width: 8),
                          _buildBadge(
                            Icons.people,
                            '${s.respondentsCount}',
                            Colors.purple,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ActionButton(
                            icon: Icons.list_alt,
                            color: Colors.teal,
                            onTap: () => context.push(
                              '/admin/surveys/${s.id}?tab=questions',
                            ),
                          ),
                          _ActionButton(
                            icon: Icons.bar_chart,
                            color: Colors.blue,
                            onTap: () => context.push(
                              '/admin/surveys/${s.id}?tab=responses',
                            ),
                          ),
                          _ActionButton(
                            icon: Icons.edit,
                            color: Colors.purple,
                            onTap: () => _showEditSurveyModal(context, ref, s),
                          ),
                          _ActionButton(
                            icon: Icons.delete,
                            color: Colors.red,
                            onTap: () =>
                                _showDeleteSurveyModal(context, ref, s),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildLivePreviewSection(List<Survey> surveys) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.visibility, color: Colors.pinkAccent),
            SizedBox(width: 8),
            Text(
              'Survey Live Preview',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          'Real-time overview of active and draft surveys with live schedule status, respondent counts, and questionnaire details',
          style: TextStyle(
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
        SizedBox(height: 16),
        _buildSearchBar(), // Reusing search bar style for layout mirroring
        SizedBox(height: 16),
        if (surveys.isEmpty)
          Center(
            child: Text(
              'No surveys found.',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withOpacity(0.54),
              ),
            ),
          )
        else
          Column(
            children: surveys
                .map(
                  (s) => Container(
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
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [_buildStatusChip(s.status)],
                        ),
                        SizedBox(height: 8),
                        Text(
                          s.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 12),
                        _buildSchedule(s.startDate, s.endDate),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _buildBadge(
                              Icons.list,
                              '${s.questionsCount} Questions',
                              Colors.teal,
                            ),
                            SizedBox(width: 12),
                            _buildBadge(
                              Icons.people,
                              '${s.respondentsCount} Submissions',
                              Colors.purpleAccent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    if (status == 'active')
      color = Colors.greenAccent;
    else if (status == 'closed')
      color = Colors.redAccent;
    else
      color = Colors.orangeAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 12, color: color),
          SizedBox(width: 4),
          Text(
            status.capitalize(),
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedule(DateTime? start, DateTime? end) {
    if (start == null) return Text('No schedule');
    final df = DateFormat('MMM dd, yyyy, h:mm a');
    return Row(
      children: [
        Icon(Icons.calendar_month, color: Colors.pinkAccent, size: 16),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(df.format(start), style: TextStyle(fontSize: 12)),
            if (end != null)
              Text(
                'to ${df.format(end)}',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withOpacity(0.54),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBadge(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(value, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  void _showCreateSurveyModal(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Create Survey',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: titleController,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.54),
                  ),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: descController,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.54),
                  ),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isEmpty) return;
                  final repo = ref.read(surveyRepositoryProvider);
                  await repo.createSurvey(
                    Survey(
                      id: '',
                      title: titleController.text,
                      description: descController.text,
                    ),
                  );
                  if (context.mounted) Navigator.pop(context);
                },
                child: Text('Create'),
              ),
              SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteSurveyModal(
    BuildContext context,
    WidgetRef ref,
    Survey survey,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text(
                      'Delete Survey',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Divider(color: Colors.white10),
                SizedBox(height: 16),
                Text(
                  'Are you sure you want to permanently delete "${survey.title}"?',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error, color: Colors.redAccent, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This will remove all associated questions, choices, and submitted member responses. This action cannot be undone.',
                          style: TextStyle(
                            color: Colors.redAccent.shade200,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                Divider(color: Colors.white10),
                SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.white10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE040FB), Color(0xFFB000FF)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purpleAccent.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () {
                          ref
                              .read(surveyRepositoryProvider)
                              .deleteSurvey(survey.id);
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.delete, size: 18),
                        label: Text(
                          'Yes, Delete Survey',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditSurveyModal(
    BuildContext context,
    WidgetRef ref,
    Survey survey,
  ) {
    final titleController = TextEditingController(text: survey.title);
    final descController = TextEditingController(text: survey.description);
    String status = survey.status;

    // Default dates if null for UI logic
    DateTime startDate = survey.startDate ?? DateTime.now();
    DateTime endDate =
        survey.endDate ?? DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.white10),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.edit_square, color: Colors.pinkAccent),
                          SizedBox(width: 8),
                          Text(
                            'Edit Survey Details',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Divider(color: Colors.white10),
                      SizedBox(height: 16),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Survey Title *',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: titleController,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Colors.pinkAccent,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Colors.pinkAccent,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Survey Status *',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: status,
                                dropdownColor: Theme.of(
                                  context,
                                ).colorScheme.surface,
                                isExpanded: true,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                ),
                                icon: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'active',
                                    child: Text('Active'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'draft',
                                    child: Text('Draft'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'closed',
                                    child: Text('Closed'),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setModalState(() => status = val);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Description / Instructions',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: descController,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                            maxLines: 4,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Colors.pinkAccent,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Colors.pinkAccent,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Opening Date *',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: startDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (d != null) {
                                setModalState(
                                  () => startDate = DateTime(
                                    d.year,
                                    d.month,
                                    d.day,
                                    startDate.hour,
                                    startDate.minute,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.pinkAccent),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('MM/dd/yyyy').format(startDate),
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  Icon(
                                    Icons.calendar_month,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withOpacity(0.54),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Closing Date *',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: endDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (d != null) {
                                setModalState(
                                  () => endDate = DateTime(
                                    d.year,
                                    d.month,
                                    d.day,
                                    endDate.hour,
                                    endDate.minute,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.pinkAccent),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('MM/dd/yyyy').format(endDate),
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  Icon(
                                    Icons.calendar_month,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withOpacity(0.54),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Opening Time *',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(startDate),
                              );
                              if (t != null) {
                                setModalState(
                                  () => startDate = DateTime(
                                    startDate.year,
                                    startDate.month,
                                    startDate.day,
                                    t.hour,
                                    t.minute,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.pinkAccent),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat(
                                      'h:mm a',
                                    ).format(startDate).toLowerCase(),
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  Icon(
                                    Icons.access_time,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withOpacity(0.54),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Closing Time *',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(endDate),
                              );
                              if (t != null) {
                                setModalState(
                                  () => endDate = DateTime(
                                    endDate.year,
                                    endDate.month,
                                    endDate.day,
                                    t.hour,
                                    t.minute,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.pinkAccent),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat(
                                      'h:mm a',
                                    ).format(endDate).toLowerCase(),
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  Icon(
                                    Icons.access_time,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withOpacity(0.54),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 24),
                      Divider(color: Colors.white10),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white38,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE040FB), Color(0xFFB000FF)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purpleAccent.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              onPressed: () async {
                                if (titleController.text.isEmpty) return;
                                final updated = survey.copyWith(
                                  title: titleController.text,
                                  description: descController.text,
                                  status: status,
                                  startDate: startDate,
                                  endDate: endDate,
                                );
                                await ref
                                    .read(surveyRepositoryProvider)
                                    .updateSurvey(updated);
                                if (context.mounted) Navigator.pop(context);
                              },
                              icon: Icon(Icons.save, size: 18),
                              label: Text(
                                'Save Changes',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _StatsCarousel extends StatefulWidget {
  final int total;
  final int active;
  final int respondents;
  final int drafts;

  const _StatsCarousel({
    required this.total,
    required this.active,
    required this.respondents,
    required this.drafts,
  });

  @override
  State<_StatsCarousel> createState() => _StatsCarouselState();
}

class _StatsCarouselState extends State<_StatsCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (Timer timer) {
      if (!mounted) return;
      if (_currentPage < 3) {
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
    return Column(
      children: [
        SizedBox(
          height: 125,
          child: PageView(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            children: [
              _StatCard(
                title: 'TOTAL SURVEYS',
                value: widget.total.toString(),
                subtitle: 'All registered surveys',
                icon: Icons.bar_chart,
                iconColor: Colors.blue,
                borderColor: Colors.blue.withValues(alpha: 0.5),
              ),
              _StatCard(
                title: 'ACTIVE SURVEYS',
                value: widget.active.toString(),
                subtitle: 'Open to members',
                icon: Icons.podcasts,
                iconColor: Colors.greenAccent,
                borderColor: Colors.greenAccent.withValues(alpha: 0.5),
              ),
              _StatCard(
                title: 'TOTAL RESPONDENTS',
                value: widget.respondents.toString(),
                subtitle: 'Unique submissions',
                icon: Icons.people,
                iconColor: Colors.purpleAccent,
                borderColor: Colors.purpleAccent.withValues(alpha: 0.5),
              ),
              _StatCard(
                title: 'DRAFT / INACTIVE',
                value: widget.drafts.toString(),
                subtitle: 'Unpublished / Closed',
                icon: Icons.insert_drive_file,
                iconColor: Colors.orangeAccent,
                borderColor: Colors.orangeAccent.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: _currentPage == index ? 24 : 8,
              decoration: BoxDecoration(
                color: _currentPage == index ? Colors.white : Colors.white38,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color borderColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withOpacity(0.54),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.list, size: 12, color: iconColor),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.54),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
