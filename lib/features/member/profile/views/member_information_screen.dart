import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/member.dart';
import '../../../../core/widgets/space_app_bar.dart';
import '../../dashboard/providers/current_member_provider.dart';

class MemberInformationScreen extends ConsumerWidget {
  const MemberInformationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsyncValue = ref.watch(currentMemberProvider);
    final primaryColor = Theme.of(context).primaryColor;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const SpaceAppBar(
        title: Text('Member Information'),
      ),
      body: memberAsyncValue.when(
        data: (member) {
          if (member == null) {
            return Center(
              child: Text(
                'Member not found',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            );
          }
          return _buildContent(context, ref, member, primaryColor);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  String _extractReferenceName(dynamic refObj) {
    if (refObj == null) return '';
    if (refObj is Map) {
      return (refObj['name'] ?? refObj['reference_member_name'] ?? '').toString();
    }
    if (refObj is String) {
      try {
        final decoded = jsonDecode(refObj);
        if (decoded is Map) {
          return (decoded['name'] ?? decoded['reference_member_name'] ?? '').toString();
        }
      } catch (_) {}
      return refObj;
    }
    return '';
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Member member, Color primaryColor) {
    final refs = (member.references ?? [])
        .map((e) => _extractReferenceName(e))
        .where((e) => e.isNotEmpty)
        .toList();
    final ref1 = refs.isNotEmpty ? refs[0] : 'N/A';
    final ref2 = refs.length > 1 ? refs[1] : 'N/A';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            verticalDirection: VerticalDirection.up,
            children: [
              _buildProfileHeaderCard(context, member, primaryColor),
              Transform.translate(
                offset: const Offset(0, 1.5),
                child: _buildStatusTab(context, member, primaryColor),
              ),
            ],
          ),
          if (member.signatureUrl != null && member.signatureUrl!.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSignatureCard(context, member, primaryColor),
          ],
          const SizedBox(height: 24),
          _buildSectionTitle('Personal Information', Icons.badge_outlined, primaryColor, context),
          const SizedBox(height: 12),
          _buildInfoCard(
            context,
            children: [
              _buildInfoRow(
                _buildInfoItem(context, 'DATE OF BIRTH & AGE', _formatDob(member.dateOfBirth), Icons.cake_outlined, primaryColor),
                _buildInfoItem(context, 'NATIONALITY', member.nationality ?? 'N/A', Icons.flag_outlined, primaryColor),
              ),
              const Divider(height: 24),
              _buildInfoRow(
                _buildInfoItem(context, 'SEX', member.gender ?? 'N/A', Icons.wc_outlined, primaryColor),
                _buildInfoItem(context, 'CIVIL STATUS', member.civilStatus ?? 'N/A', Icons.favorite_border, primaryColor),
              ),
              const Divider(height: 24),
              _buildInfoRow(
                _buildInfoItem(context, 'CONTACT NUMBER', member.phone ?? 'N/A', Icons.phone_outlined, primaryColor),
                _buildInfoItem(context, 'ACCOUNT USERNAME', member.accountNumber, Icons.person_outline, primaryColor),
              ),
              const Divider(height: 24),
              _buildInfoItem(context, 'FULL HOME ADDRESS', member.homeAddress ?? 'N/A', Icons.location_on_outlined, primaryColor, isFullWidth: true),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Employment & Business Information', Icons.work_outline, primaryColor, context),
          const SizedBox(height: 12),
          _buildInfoCard(
            context,
            children: [
              _buildInfoItem(context, 'OCCUPATION / PROFESSION', member.occupation ?? 'N/A', Icons.person_outline, primaryColor, isFullWidth: true),
              const Divider(height: 24),
              _buildInfoItem(context, 'EMPLOYER / BUSINESS NAME', member.employerName ?? 'N/A', Icons.business_outlined, primaryColor, isFullWidth: true),
              const Divider(height: 24),
              _buildInfoItem(context, 'EMPLOYER / BUSINESS ADDRESS', member.employerAddress ?? 'N/A', Icons.map_outlined, primaryColor, isFullWidth: true),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Parents Information', Icons.family_restroom_outlined, primaryColor, context),
          const SizedBox(height: 12),
          _buildInfoCard(
            context,
            children: [
              _buildInfoItem(context, 'FATHER\'S FULL NAME', member.fatherName ?? 'N/A', Icons.man_outlined, primaryColor, isFullWidth: true),
              const Divider(height: 24),
              _buildInfoItem(context, 'MOTHER\'S FULL NAME', member.motherName ?? 'N/A', Icons.woman_outlined, primaryColor, isFullWidth: true),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Character References', Icons.people_outline, primaryColor, context),
          const SizedBox(height: 12),
          _buildInfoCard(
            context,
            children: [
              _buildInfoRow(
                _buildInfoItem(context, 'REFERENCE MEMBER 1', ref1, Icons.person_outline, primaryColor),
                _buildInfoItem(context, 'REFERENCE MEMBER 2', ref2, Icons.person_outline, primaryColor),
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

  Widget _buildStatusTab(BuildContext context, Member member, Color primaryColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF13172E) : Colors.white;
    Color statusColor = member.status.toLowerCase() == 'active' ? Colors.teal : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(
          top: BorderSide(color: primaryColor.withValues(alpha: isDark ? 0.5 : 0.3), width: 1.5),
          left: BorderSide(color: primaryColor.withValues(alpha: isDark ? 0.5 : 0.3), width: 1.5),
          right: BorderSide(color: primaryColor.withValues(alpha: isDark ? 0.5 : 0.3), width: 1.5),
          bottom: BorderSide.none,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: statusColor, size: 16),
          const SizedBox(width: 8),
          Text(
            member.status.toUpperCase(),
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeaderCard(BuildContext context, Member member, Color primaryColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF13172E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final String displayName = '${member.firstName} ${member.lastName}'.trim();
    final String registeredDate = member.registeredAt != null
        ? DateFormat.yMMMMd().format(member.registeredAt!)
        : 'N/A';

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border.all(color: primaryColor.withValues(alpha: isDark ? 0.5 : 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? primaryColor.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Row(
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
              child: _buildImage(context, member.photoUrl),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildBadge(Icons.badge, 'Account: ${member.accountNumber}', Colors.blue),
                    const SizedBox(height: 8),
                    _buildBadge(Icons.calendar_today, 'Registered: $registeredDate', Colors.orange),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureCard(BuildContext context, Member member, Color primaryColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF13172E) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withValues(alpha: isDark ? 0.5 : 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? primaryColor.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SIGNATURE',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Official E-Signature',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          Container(
            width: 120,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildImage(context, member.signatureUrl),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context, String? url) {
    if (url == null || url.isEmpty) {
      return const Icon(Icons.person, color: Colors.white54, size: 40);
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.white54),
      );
    }
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.endsWith('.jpg') ||
        lowerUrl.endsWith('.png') ||
        lowerUrl.endsWith('.jpeg') ||
        lowerUrl.endsWith('.gif') ||
        lowerUrl.endsWith('.webp')) {
      // It's a filename from the PHP backend.
      // Use 10.0.2.2 for Android emulator to access the host machine's localhost.
      String baseUrl = 'http://localhost/cooperative-member-information-system/uploads/';
      try {
        if (Theme.of(context).platform == TargetPlatform.android) {
          baseUrl = 'http://10.0.2.2/cooperative-member-information-system/uploads/';
        }
      } catch (_) {}
      
      return Image.network(
        '$baseUrl$url',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.white54),
      );
    }
    
    // Fallback to base64 parsing
    try {
      final base64String = url.contains(',')
          ? url.split(',').last.replaceAll(RegExp(r'\s+'), '')
          : url.replaceAll(RegExp(r'\s+'), '');
      return Image.memory(
        base64Decode(base64String),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.white54),
      );
    } catch (_) {
      return const Icon(Icons.error, color: Colors.white54);
    }
  }

  Widget _buildSectionTitle(String title, IconData icon, Color primaryColor, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Row(
      children: [
        Icon(icon, color: primaryColor, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, {required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF13172E) : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
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

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color primaryColor, {
    bool isFullWidth = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: primaryColor, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: primaryColor,
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
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
