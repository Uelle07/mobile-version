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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            labelColor: primaryColor,
            indicatorColor: primaryColor,
            unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
            tabs: const [
              Tab(text: 'Personal Info'),
              Tab(text: 'Contact'),
              Tab(text: 'Employment'),
              Tab(text: 'Family'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildPersonalInfo(context, primaryColor, isDark),
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

  Widget _buildPersonalInfo(
    BuildContext context,
    Color primaryColor,
    bool isDark,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('First Name', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('John'),
        const Divider(),
        const SizedBox(height: 8),
        const Text('Last Name', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Doe'),
        const Divider(),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor:
                ThemeData.estimateBrightnessForColor(primaryColor) ==
                        Brightness.dark
                    ? Colors.white
                    : const Color(0xFF0F172A),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            // Edit info
          },
          child: const Text('Edit Information'),
        ),
      ],
    );
  }
}
