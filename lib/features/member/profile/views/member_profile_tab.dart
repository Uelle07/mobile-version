import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MemberProfileTab extends ConsumerStatefulWidget {
  const MemberProfileTab({super.key});

  @override
  ConsumerState<MemberProfileTab> createState() => _MemberProfileTabState();
}

class _MemberProfileTabState extends ConsumerState<MemberProfileTab> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            labelColor: Color(0xFF4A0072),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Personal Info'),
              Tab(text: 'Contact'),
              Tab(text: 'Employment'),
              Tab(text: 'Family'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildPersonalInfo(),
                const Center(child: Text('Contact details')),
                const Center(child: Text('Employment details')),
                const Center(child: Text('Family details')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('First Name', style: TextStyle(fontWeight: FontWeight.bold)),
        const Text('John'),
        const Divider(),
        const Text('Last Name', style: TextStyle(fontWeight: FontWeight.bold)),
        const Text('Doe'),
        const Divider(),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            // TODO: Edit info
          },
          child: const Text('Edit Information'),
        ),
      ],
    );
  }
}
