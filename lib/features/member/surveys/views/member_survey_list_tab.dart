import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../admin/surveys/providers/survey_provider.dart';
import 'member_survey_details_screen.dart';

class MemberSurveyListTab extends ConsumerWidget {
  const MemberSurveyListTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surveysAsync = ref.watch(surveysProvider);

    return surveysAsync.when(
      data: (surveys) {
        final activeSurveys = surveys
            .where((s) => s.status == 'active' || s.status == 'published')
            .toList();

        if (activeSurveys.isEmpty) {
          return const Center(child: Text('No active surveys available.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activeSurveys.length,
          itemBuilder: (context, index) {
            final survey = activeSurveys[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(
                  survey.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(survey.description),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).primaryColor,
                ),
                onTap: () {
                  // TODO: Navigate to answer survey screen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => MemberSurveyDetailsScreen(survey: survey),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
