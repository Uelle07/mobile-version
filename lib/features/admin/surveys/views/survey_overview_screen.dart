import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cooperative_member_app/core/models/survey.dart';
import 'package:cooperative_member_app/features/admin/surveys/repositories/survey_repository.dart';
import 'package:go_router/go_router.dart';

class SurveyOverviewScreen extends ConsumerStatefulWidget {
  const SurveyOverviewScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SurveyOverviewScreen> createState() => _SurveyOverviewScreenState();
}

class _SurveyOverviewScreenState extends ConsumerState<SurveyOverviewScreen> {
  
  @override
  Widget build(BuildContext context) {
    final surveyRepo = ref.watch(surveyRepositoryProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Survey Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateSurveyModal,
          ),
        ],
      ),
      body: StreamBuilder<List<Survey>>(
        stream: surveyRepo.watchSurveys(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final surveys = snapshot.data ?? [];

          if (surveys.isEmpty) {
            return const Center(child: Text('No surveys found. Create one!'));
          }

          return ListView.builder(
            itemCount: surveys.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final survey = surveys[index];
              return SurveyCard(survey: survey, repository: surveyRepo);
            },
          );
        },
      ),
    );
  }
  
  void _showCreateSurveyModal() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16, right: 16, top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Create Survey', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isEmpty) return;
                  final repo = ref.read(surveyRepositoryProvider);
                  await repo.createSurvey(Survey(
                    id: '', // Firestore auto-generates
                    title: titleController.text,
                    description: descController.text,
                  ));
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Create'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class SurveyCard extends StatefulWidget {
  final Survey survey;
  final SurveyRepository repository;

  const SurveyCard({Key? key, required this.survey, required this.repository}) : super(key: key);

  @override
  State<SurveyCard> createState() => _SurveyCardState();
}

class _SurveyCardState extends State<SurveyCard> {
  @override
  void initState() {
    super.initState();
    // Auto-healing counts in background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.repository.healSurveyCounts(
        widget.survey.id, 
        widget.survey.questionsCount, 
        widget.survey.respondentsCount
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final survey = widget.survey;
    final DateFormat formatter = DateFormat('MMM dd, yyyy');
    
    String schedule = 'No schedule set';
    if (survey.startDate != null && survey.endDate != null) {
      schedule = '${formatter.format(survey.startDate!)} - ${formatter.format(survey.endDate!)}';
    } else if (survey.startDate != null) {
      schedule = 'Starts ${formatter.format(survey.startDate!)}';
    }

    Color statusColor;
    switch (survey.status) {
      case 'active':
        statusColor = Colors.green;
        break;
      case 'closed':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    survey.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    survey.status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(survey.description, style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(schedule, style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Questions', survey.questionsCount),
                _buildStat('Respondents', survey.respondentsCount),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('Delete', style: TextStyle(color: Colors.red)),
                  onPressed: () => _confirmDelete(context),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Manage Questions'),
                  onPressed: () {
                    context.push('/admin/surveys/${survey.id}'); // Assumes GoRouter setup
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, int value) {
    return Column(
      children: [
        Text(value.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Survey'),
        content: const Text('Are you sure you want to delete this survey? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              widget.repository.deleteSurvey(widget.survey.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
