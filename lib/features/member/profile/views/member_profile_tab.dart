import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/member.dart';
import '../../dashboard/providers/current_member_provider.dart';

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
    final memberAsync = ref.watch(currentMemberProvider);

    return memberAsync.when(
      data: (member) {
        if (member == null) {
          return const Center(child: Text('Member record not found.'));
        }
        return _buildTabController(context, member, primaryColor, isDark);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildTabController(
    BuildContext context,
    Member member,
    Color primaryColor,
    bool isDark,
  ) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
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
                _buildPersonalInfo(context, member, primaryColor, isDark),
                _buildContactInfo(context, member, primaryColor, isDark),
                _buildEmploymentInfo(context, member, primaryColor, isDark),
                _buildFamilyInfo(context, member, primaryColor, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.isNotEmpty ? value : 'N/A',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const Divider(height: 20),
      ],
    );
  }

  Widget _buildUpdateButton(BuildContext context, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 20.0),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          GoRouter.of(context).go('/member/update-info');
        },
        icon: const Icon(Icons.edit_note_rounded, size: 20),
        label: const Text(
          'Update My Information',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildPersonalInfo(
    BuildContext context,
    Member member,
    Color primaryColor,
    bool isDark,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTile('First Name', member.firstName, isDark),
        _buildTile('Middle Name', member.middleName ?? '', isDark),
        _buildTile('Last Name', member.lastName, isDark),
        _buildTile('Date of Birth', member.dateOfBirth ?? '', isDark),
        _buildTile('Sex', member.gender ?? '', isDark),
        _buildTile('Civil Status', member.civilStatus ?? '', isDark),
        _buildTile('Nationality', member.nationality ?? '', isDark),
        _buildUpdateButton(context, primaryColor),
      ],
    );
  }

  Widget _buildContactInfo(
    BuildContext context,
    Member member,
    Color primaryColor,
    bool isDark,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTile('Account Number', member.accountNumber, isDark),
        _buildTile('Contact Number', member.phone ?? '', isDark),
        _buildTile('Email Address', member.email ?? '', isDark),
        _buildTile('Home Address', member.homeAddress ?? '', isDark),
        _buildUpdateButton(context, primaryColor),
      ],
    );
  }

  Widget _buildEmploymentInfo(
    BuildContext context,
    Member member,
    Color primaryColor,
    bool isDark,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTile('Occupation / Profession', member.occupation ?? '', isDark),
        _buildTile('Employer / Business Name', member.employerName ?? '', isDark),
        _buildTile('Employer Address', member.employerAddress ?? '', isDark),
        _buildUpdateButton(context, primaryColor),
      ],
    );
  }

  Widget _buildFamilyInfo(
    BuildContext context,
    Member member,
    Color primaryColor,
    bool isDark,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTile('Father\'s Name', member.fatherName ?? '', isDark),
        _buildTile('Mother\'s Name', member.motherName ?? '', isDark),
        if (member.civilStatus == 'Married') ...[
          _buildTile('Spouse Name', member.spouseName ?? '', isDark),
          _buildTile('Spouse Occupation', member.spouseOccupation ?? '', isDark),
          _buildTile('Spouse Employer', member.spouseEmployer ?? '', isDark),
        ],
        _buildUpdateButton(context, primaryColor),
      ],
    );
  }
}

