import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cooperative_member_app/core/models/survey.dart';
import 'package:cooperative_member_app/features/admin/surveys/repositories/survey_repository.dart';

class SurveyDetailsScreen extends ConsumerStatefulWidget {
  final String surveyId;

  const SurveyDetailsScreen({Key? key, required this.surveyId}) : super(key: key);

  @override
  ConsumerState<SurveyDetailsScreen> createState() => _SurveyDetailsScreenState();
}

class _SurveyDetailsScreenState extends ConsumerState<SurveyDetailsScreen> {
  int _totalMembers = 0;

  @override
  void initState() {
    super.initState();
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

    return StreamBuilder<Survey>(
      stream: repo.watchSurvey(widget.surveyId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(child: Text(snapshot.error?.toString() ?? 'Survey not found')),
          );
        }

        final survey = snapshot.data!;
        final participationRate = _totalMembers == 0 
            ? 0.0 
            : (survey.respondentsCount / _totalMembers) * 100;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Survey Builder'),
            actions: [
              if (survey.status == 'draft')
                TextButton(
                  onPressed: () => _publishSurvey(survey),
                  child: const Text('PUBLISH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              else
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text('PUBLISHED', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))),
                )
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showQuestionBuilder(context, survey.id),
            child: const Icon(Icons.add),
          ),
          body: Column(
            children: [
              // Statistics Header
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(label: 'Questions', value: '${survey.questionsCount}'),
                    _StatItem(label: 'Respondents', value: '${survey.respondentsCount}'),
                    _StatItem(label: 'Participation', value: '${participationRate.toStringAsFixed(1)}%'),
                  ],
                ),
              ),
              const Divider(height: 1),
              
              // Questions List
              Expanded(
                child: StreamBuilder<List<SurveyQuestion>>(
                  stream: repo.watchQuestions(survey.id),
                  builder: (context, qSnapshot) {
                    if (qSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final questions = qSnapshot.data ?? [];
                    if (questions.isEmpty) {
                      return const Center(child: Text('No questions added yet.'));
                    }

                    return ListView.builder(
                      itemCount: questions.length,
                      padding: const EdgeInsets.only(bottom: 80), // space for fab
                      itemBuilder: (context, index) {
                        final q = questions[index];
                        return QuestionTile(surveyId: survey.id, question: q, repository: repo);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _publishSurvey(Survey survey) {
    if (survey.questionsCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot publish a survey with 0 questions.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publish Survey'),
        content: const Text('Once published, members can start responding. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(surveyRepositoryProvider).publishSurvey(survey.id);
              Navigator.pop(context);
            },
            child: const Text('Publish'),
          ),
        ],
      ),
    );
  }

  void _showQuestionBuilder(BuildContext context, String surveyId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => QuestionBuilderSheet(surveyId: surveyId),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}

class QuestionTile extends StatelessWidget {
  final String surveyId;
  final SurveyQuestion question;
  final SurveyRepository repository;

  const QuestionTile({
    Key? key,
    required this.surveyId,
    required this.question,
    required this.repository,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Text(question.question),
        subtitle: Text('Type: ${question.type}'),
        children: [
          if (question.type == 'multiple_choice')
            StreamBuilder<List<SurveyChoice>>(
              stream: repository.watchChoices(question.id),
              builder: (context, cSnapshot) {
                if (!cSnapshot.hasData) return const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator());
                final choices = cSnapshot.data!;
                return Column(
                  children: choices.map((c) => ListTile(
                    leading: const Icon(Icons.radio_button_unchecked, size: 16),
                    title: Text(c.choiceText),
                  )).toList(),
                );
              },
            ),
          ButtonBar(
            children: [
              TextButton.icon(
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('Delete', style: TextStyle(color: Colors.red)),
                onPressed: () {
                  repository.deleteQuestion(surveyId, question.id);
                },
              ),
            ],
          )
        ],
      ),
    );
  }
}

class QuestionBuilderSheet extends ConsumerStatefulWidget {
  final String surveyId;

  const QuestionBuilderSheet({Key? key, required this.surveyId}) : super(key: key);

  @override
  ConsumerState<QuestionBuilderSheet> createState() => _QuestionBuilderSheetState();
}

class _QuestionBuilderSheetState extends ConsumerState<QuestionBuilderSheet> {
  final _questionController = TextEditingController();
  String _selectedType = 'text';
  final List<TextEditingController> _choiceControllers = [TextEditingController(), TextEditingController()];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Add Question', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _questionController,
            decoration: const InputDecoration(labelText: 'Question Text', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: const InputDecoration(labelText: 'Question Type', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'text', child: Text('Text Answer')),
              DropdownMenuItem(value: 'multiple_choice', child: Text('Multiple Choice')),
            ],
            onChanged: (val) {
              setState(() {
                _selectedType = val!;
              });
            },
          ),
          if (_selectedType == 'multiple_choice') ...[
            const SizedBox(height: 16),
            const Align(alignment: Alignment.centerLeft, child: Text('Choices', style: TextStyle(fontWeight: FontWeight.bold))),
            ...List.generate(_choiceControllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _choiceControllers[index],
                        decoration: InputDecoration(hintText: 'Option ${index + 1}'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () {
                        if (_choiceControllers.length > 2) {
                          setState(() {
                            _choiceControllers.removeAt(index);
                          });
                        }
                      },
                    )
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _choiceControllers.add(TextEditingController());
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Add another option'),
            )
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saveQuestion,
            child: const Text('Save Question'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _saveQuestion() async {
    if (_questionController.text.isEmpty) return;

    List<String> choices = [];
    if (_selectedType == 'multiple_choice') {
      choices = _choiceControllers.map((c) => c.text.trim()).where((text) => text.isNotEmpty).toList();
      if (choices.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least two options for multiple choice.')));
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
