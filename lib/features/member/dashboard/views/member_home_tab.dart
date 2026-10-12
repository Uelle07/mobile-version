import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/member.dart';
import '../providers/current_member_provider.dart';

class MemberHomeTab extends ConsumerWidget {
  const MemberHomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsyncValue = ref.watch(currentMemberProvider);
    final primaryColor = Theme.of(context).primaryColor;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Banner
          memberAsyncValue.when(
            data: (member) {
              if (member == null) {
                return const Center(child: Text('Member data not found.', style: TextStyle(color: Colors.white)));
              }
              return _buildWelcomeBanner(context, primaryColor, member);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
          ),
          
          const SizedBox(height: 32),
          
          Text(
            'What would you like to do?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF0F172A),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Action Cards (Vertical List for Mobile)
          _buildActionCard(
            context: context,
            icon: Icons.person_search_rounded,
            title: 'View My Information',
            description: 'See your personal, contact, and family details on file.',
            actionText: 'View Details',
            primaryColor: primaryColor,
            onTap: () {
              GoRouter.of(context).go('/member/information');
            },
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            context: context,
            icon: Icons.edit_note_rounded,
            title: 'Update My Information',
            description: 'Edit personal, contact, spouse, and children information.',
            actionText: 'Update Now',
            primaryColor: primaryColor,
            onTap: () {},
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            context: context,
            icon: Icons.camera_alt_rounded,
            title: 'Upload Photo',
            description: 'Upload or replace your passport-size photo.',
            actionText: 'Upload',
            primaryColor: primaryColor,
            onTap: () {
              GoRouter.of(context).go('/member/upload-photo');
            },
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            context: context,
            icon: Icons.bar_chart_rounded,
            title: 'Cooperative Surveys',
            description: 'Participate in active cooperative surveys and share feedback.',
            actionText: 'Take Survey',
            primaryColor: primaryColor,
            onTap: () {},
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            context: context,
            icon: Icons.key_rounded,
            title: 'Change Password',
            description: 'Update your account security password.',
            actionText: 'Change Password',
            primaryColor: primaryColor,
            onTap: () {},
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner(BuildContext context, Color primaryColor, Member member) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF13172E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.white70 : Colors.black54;
    final String displayName = '${member.firstName} ${member.lastName}'.trim();
    final String accNumber = member.accountNumber.isNotEmpty ? member.accountNumber : 'UNKNOWN';
    final String? photoUrl = member.photoUrl;
    final bool isVerified = member.isVerified;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withValues(alpha: isDark ? 0.5 : 0.3),
          width: 1.5,
        ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar with glow and status indicator
              Stack(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      border: Border.all(color: primaryColor, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Builder(builder: (context) {
                        if (photoUrl == null || photoUrl.isEmpty) {
                          return Icon(Icons.person, color: isDark ? Colors.white54 : Colors.grey, size: 30);
                        }
                        if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
                          return Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(Icons.person, color: isDark ? Colors.white54 : Colors.grey, size: 30),
                          );
                        }
                        final lowerUrl = photoUrl.toLowerCase();
                        if (lowerUrl.endsWith('.jpg') ||
                            lowerUrl.endsWith('.png') ||
                            lowerUrl.endsWith('.jpeg') ||
                            lowerUrl.endsWith('.gif') ||
                            lowerUrl.endsWith('.webp')) {
                          // It's a filename from the PHP backend.
                          String baseUrl = 'http://localhost/cooperative-member-information-system/uploads/';
                          try {
                            if (Theme.of(context).platform == TargetPlatform.android) {
                              baseUrl = 'http://10.0.2.2/cooperative-member-information-system/uploads/';
                            }
                          } catch (_) {}
                          
                          return Image.network(
                            '$baseUrl$photoUrl',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(Icons.person, color: isDark ? Colors.white54 : Colors.grey, size: 30),
                          );
                        }
                        
                        // Fallback to base64 parsing
                        try {
                          final base64String = photoUrl.contains(',')
                              ? photoUrl.split(',').last.replaceAll(RegExp(r'\s+'), '')
                              : photoUrl.replaceAll(RegExp(r'\s+'), '');
                          return Image.memory(
                            base64Decode(base64String),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(Icons.person, color: isDark ? Colors.white54 : Colors.grey, size: 30),
                          );
                        } catch (_) {
                          return Icon(Icons.person, color: isDark ? Colors.white54 : Colors.grey, size: 30);
                        }
                      }),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: cardBg, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Account Number Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.badge, color: primaryColor, size: 12),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'ACCT NO. $accNumber',
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Welcome Name
                    Text(
                      'Welcome, $displayName!',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Verified Badge
                    Row(
                      children: [
                        Icon(
                          isVerified ? Icons.shield : Icons.shield_outlined,
                          color: isVerified ? Colors.green : Colors.grey,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            isVerified ? 'Verified Member' : 'Unverified Member',
                            style: TextStyle(
                              color: subtextColor,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required String actionText,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF13172E) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final descColor = isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black54;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
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
          children: [
            Row(
              children: [
                // Icon Container
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: primaryColor, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: titleColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                color: descColor,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  actionText,
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward, color: primaryColor, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
