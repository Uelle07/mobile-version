import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/kpi_providers.dart';

class AdminHomeTab extends ConsumerWidget {
  const AdminHomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalMembers = ref.watch(totalMembersCountProvider);
    final activeSurveys = ref.watch(activeSurveysCountProvider);
    final newAccounts = ref.watch(newAccountsTodayCountProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overview',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            children: [
              _buildKpiCard('Total Members', totalMembers, Icons.people, Colors.blue),
              _buildKpiCard('New Today', newAccounts, Icons.person_add, Colors.green),
              _buildKpiCard('Active Surveys', activeSurveys, Icons.poll, Colors.orange),
              _buildKpiCard('Recent Updates', const AsyncValue.data(0), Icons.update, Colors.purple), // Placeholder
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Recent Registrations',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // TODO: Implement Recent Registrations List
          const Center(child: Text('Recent Registrations List Here')),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, AsyncValue<int> countValue, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const Spacer(),
                countValue.when(
                  data: (count) => Text(
                    '$count',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  loading: () => const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (error, stack) => const Icon(Icons.error, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
