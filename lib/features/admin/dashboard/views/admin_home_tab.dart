import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/member.dart';
import '../../members/providers/member_provider.dart';
import '../providers/kpi_providers.dart';

class AdminHomeTab extends ConsumerWidget {
  const AdminHomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalMembers = ref.watch(totalMembersCountProvider);
    final activeSurveys = ref.watch(activeSurveysCountProvider);
    final newAccounts = ref.watch(newAccountsTodayCountProvider);
    final recentUpdates = ref.watch(recentUpdatesCountProvider);
    final membersAsync = ref.watch(membersProvider);

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
              _buildKpiCard(
                context,
                'Total Members',
                totalMembers,
                Icons.people,
                Colors.blue,
              ),
              _buildKpiCard(
                context,
                'New Today',
                newAccounts,
                Icons.person_add,
                Colors.green,
              ),
              _buildKpiCard(
                context,
                'Active Surveys',
                activeSurveys,
                Icons.poll,
                Colors.orange,
              ),
              _buildKpiCard(
                context,
                'Recent Updates',
                recentUpdates,
                Icons.update,
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Recent Registrations',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildRecentRegistrationsList(context, membersAsync),
        ],
      ),
    );
  }

  Widget _buildRecentRegistrationsList(
    BuildContext context,
    AsyncValue<List<Member>> membersAsync,
  ) {
    return membersAsync.when(
      data: (members) {
        if (members.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: Text('No registered members found.')),
            ),
          );
        }

        final sorted = List<Member>.from(members)
          ..sort((a, b) {
            final aDate =
                a.registeredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate =
                b.registeredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });

        final recent = sorted.take(5).toList();
        final dateFormat = DateFormat('MMM dd, yyyy');

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recent.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final member = recent[index];
            final fullName = '${member.firstName} ${member.lastName}'.trim();
            final regDate = member.registeredAt != null
                ? dateFormat.format(member.registeredAt!)
                : 'Recently joined';
            final isActive = member.status.toLowerCase() == 'active';

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                onTap: () => context.push('/admin/members/${member.id}'),
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.15),
                  child: Text(
                    fullName.isNotEmpty ? fullName[0].toUpperCase() : 'M',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                title: Text(
                  fullName.isNotEmpty ? fullName : 'Unnamed Member',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('Acct: ${member.accountNumber} • $regDate'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (isActive ? Colors.green : Colors.grey).withValues(
                      alpha: 0.15,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    member.status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, _) => Center(
        child: Text(
          'Failed to load recent registrations: $err',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context,
    String title,
    AsyncValue<int> countValue,
    IconData icon,
    Color color,
  ) {
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
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  loading: () => const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (error, stack) =>
                      const Icon(Icons.error, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
