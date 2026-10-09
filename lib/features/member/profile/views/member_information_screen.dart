import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/member.dart';
import '../../dashboard/providers/current_member_provider.dart';

class MemberInformationScreen extends ConsumerWidget {
  const MemberInformationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsyncValue = ref.watch(currentMemberProvider);
    final primaryColor = Theme.of(context).primaryColor;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Member Information', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: memberAsyncValue.when(
        data: (member) {
          if (member == null) {
            return const Center(child: Text('Member not found', style: TextStyle(color: Colors.white)));
          }
          return _buildContent(context, member, primaryColor);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Member member, Color primaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProfileHeaderCard(context, member, primaryColor),
          const SizedBox(height: 24),
          _buildSectionTitle('Personal Information', Icons.badge_outlined, primaryColor),
          const SizedBox(height: 12),
          _buildInfoCard(
            children: [
              _buildInfoRow(
                _buildInfoItem('DATE OF BIRTH & AGE', _formatDob(member.dateOfBirth), Icons.cake_outlined, primaryColor),
                _buildInfoItem('NATIONALITY', member.nationality ?? 'N/A', Icons.flag_outlined, primaryColor),
              ),
              const Divider(color: Colors.white12, height: 24),
              _buildInfoRow(
                _buildInfoItem('SEX', member.gender ?? 'N/A', Icons.wc_outlined, primaryColor),
                _buildInfoItem('CIVIL STATUS', member.civilStatus ?? 'N/A', Icons.favorite_border, primaryColor),
              ),
              const Divider(color: Colors.white12, height: 24),
              _buildInfoRow(
                _buildInfoItem('CONTACT NUMBER', member.phone ?? 'N/A', Icons.phone_outlined, primaryColor),
                _buildInfoItem('ACCOUNT USERNAME', member.accountNumber, Icons.person_outline, primaryColor),
              ),
              const Divider(color: Colors.white12, height: 24),
              _buildInfoItem('FULL HOME ADDRESS', member.homeAddress ?? 'N/A', Icons.location_on_outlined, primaryColor, isFullWidth: true),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Employment & Business Information', Icons.work_outline, primaryColor),
          const SizedBox(height: 12),
          _buildInfoCard(
            children: [
              _buildInfoItem('OCCUPATION / PROFESSION', member.occupation ?? 'N/A', Icons.person_outline, primaryColor, isFullWidth: true),
              const Divider(color: Colors.white12, height: 24),
              _buildInfoItem('EMPLOYER / BUSINESS NAME', member.employerName ?? 'N/A', Icons.business_outlined, primaryColor, isFullWidth: true),
              const Divider(color: Colors.white12, height: 24),
              _buildInfoItem('EMPLOYER / BUSINESS ADDRESS', member.employerAddress ?? 'N/A', Icons.map_outlined, primaryColor, isFullWidth: true),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Parents Information', Icons.family_restroom_outlined, primaryColor),
          const SizedBox(height: 12),
          _buildInfoCard(
            children: [
              _buildInfoItem('FATHER\'S FULL NAME', member.fatherName ?? 'N/A', Icons.man_outlined, primaryColor, isFullWidth: true),
              const Divider(color: Colors.white12, height: 24),
              _buildInfoItem('MOTHER\'S FULL NAME', member.motherName ?? 'N/A', Icons.woman_outlined, primaryColor, isFullWidth: true),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Character References', Icons.people_outline, primaryColor),
          const SizedBox(height: 12),
          _buildInfoCard(
            children: [
              _buildInfoRow(
                _buildInfoItem('REFERENCE MEMBER 1', 'N/A', Icons.person_outline, primaryColor),
                _buildInfoItem('REFERENCE MEMBER 2', 'N/A', Icons.person_outline, primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _formatDob(String? dob) {
    if (dob == null || dob.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dob);
      final formatted = DateFormat.yMMMMd().format(date);
      final age = DateTime.now().year - date.year;
      return '$formatted ($age Years Old)';
    } catch (_) {
      return dob;
    }
  }

  Widget _buildProfileHeaderCard(BuildContext context, Member member, Color primaryColor) {
    final String displayName = '${member.firstName} ${member.lastName}';
    final String registeredDate = member.registeredAt != null
        ? DateFormat.yMMMMd().format(member.registeredAt!)
        : 'N/A';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF13172E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.15),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _buildImage(member.photoUrl),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Account No: ${member.accountNumber}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    Text(
                      'Registered: $registeredDate',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildBadge(Icons.badge, 'Account: ${member.accountNumber}', Colors.blue),
                        _buildBadge(Icons.check_circle, 'Account Status: ${member.status}', Colors.green),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (member.signatureUrl != null && member.signatureUrl!.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'SIGNATURE',
                style: TextStyle(
                  color: Colors.pinkAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 120,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImage(member.signatureUrl),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String? url) {
    if (url == null || url.isEmpty) {
      return const Icon(Icons.person, color: Colors.white54, size: 40);
    }
    if (url.startsWith('data:image')) {
      try {
        final base64String = url.split(',').last;
        return Image.memory(
          base64Decode(base64String),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.white54),
        );
      } catch (_) {
        return const Icon(Icons.error, color: Colors.white54);
      }
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.white54),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color primaryColor) {
    return Row(
      children: [
        Icon(icon, color: Colors.pinkAccent, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF13172E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(Widget left, Widget right) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 16),
        Expanded(child: right),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, Color primaryColor, {bool isFullWidth = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.pinkAccent, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.pinkAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
