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
              color: Colors.white,
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
    final String displayName = '${member.firstName} ${member.lastName}';
    final String accNumber = member.accountNumber.isNotEmpty ? member.accountNumber : 'UNKNOWN';
    final String? photoUrl = member.photoUrl;
    final bool isVerified = member.isVerified;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF13172E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
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
                      color: const Color(0xFF0F172A),
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
                          return const Icon(Icons.person, color: Colors.white54, size: 30);
                        }
                        if (photoUrl.startsWith('data:image')) {
                          try {
                            final base64String = photoUrl.split(',').last;
                            return Image.memory(
                              base64Decode(base64String),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white54, size: 30),
                            );
                          } catch (_) {
                            return const Icon(Icons.person, color: Colors.white54, size: 30);
                          }
                        }
                        return Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white54, size: 30),
                        );
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
                        border: Border.all(color: const Color(0xFF13172E), width: 2),
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
                          Text(
                            'ACCT NO. $accNumber',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Welcome Name
                    Text(
                      'Welcome, $displayName!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                        Text(
                          isVerified ? 'Verified Member' : 'Unverified Member',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF13172E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
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
