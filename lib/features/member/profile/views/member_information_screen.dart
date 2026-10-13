import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
      appBar: SpaceAppBar(
        title: const Text('Member Information'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded),
            tooltip: 'Update Information',
            onPressed: () {
              GoRouter.of(context).go('/member/update-info');
            },
          ),
        ],
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
          _buildProfileHeaderCard(context, member, primaryColor),
          if (member.signatureUrl != null && member.signatureUrl!.isNotEmpty) ...[
            const SizedBox(height: 16),
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
          const SizedBox(height: 24),
          ElevatedButton.icon(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08);
    final String displayName = '${member.firstName} ${member.lastName}'.trim();
    final String registeredDate = member.registeredAt != null
        ? DateFormat.yMMMMd().format(member.registeredAt!)
        : 'N/A';
    final bool isActive = member.status.toLowerCase() == 'active';
    final Color statusColor = isActive ? Colors.teal : Colors.grey;

    return _buildInfoCard(
      context,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.5),
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                          color: statusColor,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          member.status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Divider(height: 24),
        _buildInfoRow(
          _buildInfoItem(
            context,
            'ACCOUNT NUMBER',
            member.accountNumber,
            Icons.badge_outlined,
            primaryColor,
          ),
          _buildInfoItem(
            context,
            'DATE REGISTERED',
            registeredDate,
            Icons.calendar_today_outlined,
            primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSignatureCard(BuildContext context, Member member, Color primaryColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08);

    return _buildInfoCard(
      context,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _buildInfoItem(
                context,
                'SIGNATURE',
                'Official E-Signature',
                Icons.draw_outlined,
                primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 130,
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: _buildImage(context, member.signatureUrl, fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImage(BuildContext context, String? url, {BoxFit fit = BoxFit.cover}) {
    if (url == null || url.isEmpty) {
      return const Icon(Icons.person, color: Colors.white54, size: 40);
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: fit,
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
        fit: fit,
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
        fit: fit,
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
