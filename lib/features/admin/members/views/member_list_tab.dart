import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/member_provider.dart';

class MemberListTab extends ConsumerWidget {
  const MemberListTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(membersProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/admin/add-member'),
        child: const Icon(Icons.add),
      ),
      body: membersAsync.when(
        data: (members) {
          if (members.isEmpty) {
            return const Center(child: Text('No members found.'));
          }
          return ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: member.photoUrl != null ? NetworkImage(member.photoUrl!) : null,
                  child: member.photoUrl == null ? const Icon(Icons.person) : null,
                ),
                title: Text('${member.firstName} ${member.lastName}'),
                subtitle: Text(member.accountNumber),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Navigate to member details
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
