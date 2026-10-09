import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/member_provider.dart';

class MemberListTab extends ConsumerStatefulWidget {
  const MemberListTab({super.key});

  @override
  ConsumerState<MemberListTab> createState() => _MemberListTabState();
}

class _MemberListTabState extends ConsumerState<MemberListTab> {
  String _searchQuery = '';
  String _accountStatusFilter = 'All Registered Records';
  String _timelineFilter = 'All Registered Timeline';

  bool _matchesTimeline(DateTime? date, String filter) {
    if (filter == 'All Registered Timeline') return true;
    if (date == null) return false;
    
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    switch (filter) {
      case 'Most Recent (within 30-day span)':
      case 'Past 30 Days Span':
        return difference <= 30;
      case 'Past 1st Quarter Span':
        return difference <= 90;
      case 'Past 2nd Quarter Span':
        return difference <= 180;
      case 'Past 3rd Quarter Span':
        return difference <= 270;
      case 'Past 4th Quarter Span':
      case 'Past 1 Year Span':
        return difference <= 365;
      default:
        return true;
    }
  }

  bool _matchesStatus(String status, String filter) {
    if (filter == 'All Registered Records') return true;
    if (filter == 'Active Accounts Only') return status.toLowerCase() == 'active';
    if (filter == 'Inactive Accounts Only') return status.toLowerCase() != 'active';
    return true;
  }

  void _showFilterDialog(BuildContext context) {
    String tempStatusFilter = _accountStatusFilter;
    String tempTimelineFilter = _timelineFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 24.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.tune),
                          SizedBox(width: 8),
                          Text(
                            'Filter Options',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.layers, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Account Status / Scope:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: tempStatusFilter,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items: [
                      'All Registered Records',
                      'Active Accounts Only',
                      'Inactive Accounts Only',
                    ].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setModalState(() {
                          tempStatusFilter = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  const Row(
                    children: [
                      Icon(Icons.calendar_today, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Timeline Added:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: tempTimelineFilter,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items: [
                      'All Registered Timeline',
                      'Most Recent (within 30-day span)',
                      'Past 30 Days Span',
                      'Past 1st Quarter Span',
                      'Past 2nd Quarter Span',
                      'Past 3rd Quarter Span',
                      'Past 4th Quarter Span',
                      'Past 1 Year Span',
                    ].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setModalState(() {
                          tempTimelineFilter = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _accountStatusFilter = tempStatusFilter;
                          _timelineFilter = tempTimelineFilter;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Apply',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/admin/add-member'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add),
      ),
      body: membersAsync.when(
        data: (members) {
          final filteredMembers = members.where((m) {
            final query = _searchQuery.toLowerCase();
            final fullName = '${m.firstName} ${m.lastName}'.toLowerCase();
            final matchesSearch = fullName.contains(query) || 
                                  m.accountNumber.toLowerCase().contains(query);
            final matchesStatus = _matchesStatus(m.status, _accountStatusFilter);
            final matchesTimeline = _matchesTimeline(m.registeredAt, _timelineFilter);
            return matchesSearch && matchesStatus && matchesTimeline;
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cooperative Members',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage and view registered cooperative members',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSearchBar(context, theme, colorScheme),
                  ],
                ),
              ),
              Expanded(
                child: filteredMembers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.3,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No members found.',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 88),
                        itemCount: filteredMembers.length,
                        itemBuilder: (context, index) {
                          final member = filteredMembers[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                context.go(
                                  '/admin/member-details/${member.id}',
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Hero(
                                      tag: 'member_avatar_${member.id}',
                                      child: Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: colorScheme.primary.withValues(
                                            alpha: 0.15,
                                          ),
                                        ),
                                        child: ClipOval(
                                          child: _buildProfileImage(
                                            context,
                                            member.photoUrl,
                                            colorScheme,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${member.firstName} ${member.lastName}',
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: colorScheme.onSurface,
                                                ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.badge,
                                                size: 14,
                                                color: colorScheme.primary
                                                    .withValues(alpha: 0.7),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                member.accountNumber,
                                                style: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: colorScheme
                                                          .onSurface
                                                          .withValues(
                                                            alpha: 0.7,
                                                          ),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withValues(
                                          alpha: 0.1,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.arrow_forward_ios,
                                        color: colorScheme.primary,
                                        size: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Error: $error',
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.onSurface.withValues(alpha: 0.1),
              ),
            ),
            child: TextField(
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search members by name...',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          child: IconButton(
            icon: Icon(Icons.filter_list, color: colorScheme.onSurface),
            onPressed: () => _showFilterDialog(context),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileImage(
    BuildContext context,
    String? photoUrl,
    ColorScheme colorScheme,
  ) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return Icon(Icons.person, color: colorScheme.primary, size: 30);
    }
    if (photoUrl.startsWith('http')) {
      return Image.network(
        photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.person, color: colorScheme.primary, size: 30),
      );
    }
    if (photoUrl.toLowerCase().endsWith('.jpg') ||
        photoUrl.toLowerCase().endsWith('.png') ||
        photoUrl.toLowerCase().endsWith('.jpeg') ||
        photoUrl.toLowerCase().endsWith('.gif') ||
        photoUrl.toLowerCase().endsWith('.webp')) {
      String baseUrl =
          'http://localhost/cooperative-member-information-system/uploads/';
      if (!kIsWeb && Theme.of(context).platform == TargetPlatform.android) {
        baseUrl =
            'http://10.0.2.2/cooperative-member-information-system/uploads/';
      }
      return Image.network(
        '$baseUrl$photoUrl',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.person, color: colorScheme.primary, size: 30),
      );
    }
    try {
      final base64String = photoUrl.contains(',')
          ? photoUrl.split(',').last.replaceAll(RegExp(r'\s+'), '')
          : photoUrl.replaceAll(RegExp(r'\s+'), '');
      return Image.memory(
        base64Decode(base64String),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.person, color: colorScheme.primary, size: 30),
      );
    } catch (e) {
      return Icon(Icons.person, color: colorScheme.primary, size: 30);
    }
  }
}
