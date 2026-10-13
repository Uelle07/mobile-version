import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cooperative_member_app/core/models/survey.dart';
import '../providers/survey_provider.dart';
import '../repositories/survey_repository.dart';

class SurveyListTab extends ConsumerStatefulWidget {
  const SurveyListTab({super.key});

  @override
  ConsumerState<SurveyListTab> createState() => _SurveyListTabState();
}

class _SurveyListTabState extends ConsumerState<SurveyListTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'all';
  String _selectedTimeline = 'all';

  bool get _hasActiveFilter =>
      _selectedStatus != 'all' || _selectedTimeline != 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool matchesFilter(Survey survey) {
    final query = _searchController.text.trim().toLowerCase();
    final status = survey.status.toLowerCase().trim();
    final code = survey.id.length >= 8
        ? survey.id.substring(0, 8).toLowerCase()
        : survey.id.toLowerCase();

    // 1. Search Match
    final matchesSearch = query.isEmpty ||
        survey.title.toLowerCase().contains(query) ||
        survey.description.toLowerCase().contains(query) ||
        status.contains(query) ||
        code.contains(query);

    // 2. Status Match (Note: 'closed' matches both 'closed' and 'inactive')
    final isClosedOrInactive = (status == 'closed' || status == 'inactive');
    final matchesStatus = (_selectedStatus == 'all') ||
        ((_selectedStatus == 'closed' || _selectedStatus == 'inactive') &&
            isClosedOrInactive) ||
        (status == _selectedStatus);

    // 3. Timeline Match
    final now = DateTime.now();
    final start = survey.startDate ?? now;
    final end = survey.endDate ?? now;
    String timelineState = 'currently_open';
    if (start.isAfter(now)) {
      timelineState = 'upcoming';
    } else if (end.isBefore(now)) {
      timelineState = 'ended';
    }
    final matchesTimeline =
        (_selectedTimeline == 'all') || (timelineState == _selectedTimeline);

    return matchesSearch && matchesStatus && matchesTimeline;
  }

  @override
  Widget build(BuildContext context) {
    final surveysAsync = ref.watch(surveysProvider);

    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).scaffoldBackgroundColor, // Web-like dark background
      body: surveysAsync.when(
        data: (surveys) {
          // Calculate Stats
          final totalSurveys = surveys.length;
          final activeSurveys = surveys
              .where((s) => s.status.toLowerCase().trim() == 'active')
              .length;
          final draftSurveys = surveys.where((s) {
            final st = s.status.toLowerCase().trim();
            return st == 'draft' || st == 'closed' || st == 'inactive';
          }).length;
          final totalRespondents = surveys.fold<int>(
            0,
            (sum, s) => sum + s.respondentsCount,
          );

          // Combined Filter (Search + Status + Timeline)
          final filteredSurveys = surveys.where(matchesFilter).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 16),
                _buildStatsCards(
                  total: totalSurveys,
                  active: activeSurveys,
                  respondents: totalRespondents,
                  drafts: draftSurveys,
                ),
                const SizedBox(height: 16),
                _buildSearchBar(),
                if (_hasActiveFilter) ...[
                  const SizedBox(height: 10),
                  _buildActiveFilterIndicatorRow(),
                ],
                const SizedBox(height: 12),
                _buildMainTable(
                  filteredSurveys,
                  ref,
                  context,
                  totalSurveysCount: totalSurveys,
                ),
                const SizedBox(height: 24),
                _buildLivePreviewSection(
                  filteredSurveys,
                  totalSurveysCount: totalSurveys,
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            'Error: $err',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Cooperative Member Survey',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Manage member feedback surveys',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.75),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC042FF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () => _showCreateSurveyModal(context),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 16),
              SizedBox(width: 4),
              Text(
                'Create New Survey',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards({
    required int total,
    required int active,
    required int respondents,
    required int drafts,
  }) {
    return _StatsCarousel(
      total: total,
      active: active,
      respondents: respondents,
      drafts: drafts,
    );
  }

  Widget _buildSearchBar() {
    const cyanAccent = Color(0xFF00C2A8);
    final hasFilter = _hasActiveFilter;

    final Widget searchTextField = Container(
      decoration: BoxDecoration(
        color: const Color(0xFF162032),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: TextField(
        controller: _searchController,
        maxLength: 100,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
          fontSize: 14,
        ),
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          counterText: '',
          hintText: 'Search surveys by title...',
          hintStyle: TextStyle(
            color: (Theme.of(context).textTheme.bodyMedium?.color ??
                    Colors.white)
                .withValues(alpha: 0.45),
            fontSize: 13.5,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: (Theme.of(context).textTheme.bodyMedium?.color ??
                    Colors.white)
                .withValues(alpha: 0.5),
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  tooltip: 'Clear search',
                  icon: Icon(
                    Icons.clear,
                    size: 18,
                    color: (Theme.of(context).textTheme.bodyMedium?.color ??
                            Colors.white)
                        .withValues(alpha: 0.65),
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );

    final Widget filterIconButton = SizedBox(
      width: 48,
      height: 48,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _showFilterBottomSheet(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: hasFilter
                  ? cyanAccent.withValues(alpha: 0.15)
                  : const Color(0xFF162032),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasFilter
                    ? cyanAccent
                    : Colors.white.withValues(alpha: 0.15),
                width: hasFilter ? 1.5 : 1.0,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.filter_list,
                  color: hasFilter
                      ? cyanAccent
                      : (Theme.of(context).textTheme.bodyLarge?.color ??
                              Colors.white)
                          .withValues(alpha: 0.85),
                  size: 22,
                ),
                if (hasFilter)
                  Positioned(
                    top: 9,
                    right: 9,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: cyanAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: cyanAccent.withValues(alpha: 0.6),
                            blurRadius: 4,
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    return Row(
      children: [
        Expanded(child: searchTextField),
        const SizedBox(width: 10),
        filterIconButton,
      ],
    );
  }

  String _statusFilterLabel(String status) {
    switch (status) {
      case 'active':
        return 'Status: Active';
      case 'draft':
        return 'Status: Draft';
      case 'closed':
      case 'inactive':
        return 'Status: Closed / Inactive';
      default:
        return 'All Surveys';
    }
  }

  String _timelineFilterLabel(String timeline) {
    switch (timeline) {
      case 'currently_open':
        return 'Schedule: Currently Open';
      case 'upcoming':
        return 'Schedule: Upcoming';
      case 'ended':
        return 'Schedule: Ended';
      default:
        return 'All Timelines';
    }
  }

  Widget _buildActiveFilterIndicatorRow() {
    const cyanAccent = Color(0xFF00C2A8);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (_selectedStatus != 'all')
          _buildActiveFilterBadge(
            label: _statusFilterLabel(_selectedStatus),
            onRemove: () => setState(() => _selectedStatus = 'all'),
          ),
        if (_selectedTimeline != 'all')
          _buildActiveFilterBadge(
            label: _timelineFilterLabel(_selectedTimeline),
            onRemove: () => setState(() => _selectedTimeline = 'all'),
          ),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            setState(() {
              _selectedStatus = 'all';
              _selectedTimeline = 'all';
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Text(
              'Reset All',
              style: TextStyle(
                color: cyanAccent.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveFilterBadge({
    required String label,
    required VoidCallback onRemove,
  }) {
    const cyanAccent = Color(0xFF00C2A8);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cyanAccent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cyanAccent.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.filter_alt_outlined, size: 13, color: cyanAccent),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: cyanAccent,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: cyanAccent),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    String tempStatus = _selectedStatus;
    String tempTimeline = _selectedTimeline;
    const cyanAccent = Color(0xFF00C2A8);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0B132B), Color(0xFF1C2541)],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 24,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag handle pill
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.24),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Header: Slider/Filter icon + "Filter Options" + Close (x) button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: cyanAccent.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: cyanAccent.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.tune_rounded,
                                      color: cyanAccent,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Flexible(
                                    child: Text(
                                      'Filter Options',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Close',
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white70,
                                size: 22,
                              ),
                              onPressed: () => Navigator.pop(sheetContext),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Divider(
                          color: Colors.white.withValues(alpha: 0.1),
                          height: 1,
                        ),
                        const SizedBox(height: 16),

                        // Group 1: Survey Status (statusFilter)
                        Row(
                          children: [
                            const Icon(
                              Icons.layers_outlined,
                              size: 16,
                              color: cyanAccent,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'SURVEY STATUS',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildFilterOptionTile(
                          title: 'All Surveys',
                          subtitle: 'Default — Show all survey statuses',
                          icon: Icons.all_inbox_rounded,
                          isSelected: tempStatus == 'all',
                          onTap: () => setModalState(() => tempStatus = 'all'),
                        ),
                        _buildFilterOptionTile(
                          title: 'Active',
                          subtitle: 'Open to members',
                          icon: Icons.check_circle_outline_rounded,
                          isSelected: tempStatus == 'active',
                          onTap: () =>
                              setModalState(() => tempStatus = 'active'),
                        ),
                        _buildFilterOptionTile(
                          title: 'Draft',
                          subtitle: 'Unpublished',
                          icon: Icons.edit_note_rounded,
                          isSelected: tempStatus == 'draft',
                          onTap: () =>
                              setModalState(() => tempStatus = 'draft'),
                        ),
                        _buildFilterOptionTile(
                          title: 'Closed / Inactive',
                          subtitle: 'Closed or inactive surveys',
                          icon: Icons.lock_outline_rounded,
                          isSelected:
                              tempStatus == 'closed' || tempStatus == 'inactive',
                          onTap: () =>
                              setModalState(() => tempStatus = 'closed'),
                        ),

                        const SizedBox(height: 16),

                        // Group 2: Schedule / Timeline Window (timelineFilter)
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 16,
                              color: cyanAccent,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'SCHEDULE / TIMELINE WINDOW',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildFilterOptionTile(
                          title: 'All Timelines',
                          subtitle: 'Default — Any schedule window',
                          icon: Icons.calendar_month_rounded,
                          isSelected: tempTimeline == 'all',
                          onTap: () =>
                              setModalState(() => tempTimeline = 'all'),
                        ),
                        _buildFilterOptionTile(
                          title: 'Currently Open (Within Schedule)',
                          subtitle: 'Active window (startDate <= now <= endDate)',
                          icon: Icons.event_available_rounded,
                          isSelected: tempTimeline == 'currently_open',
                          onTap: () => setModalState(
                            () => tempTimeline = 'currently_open',
                          ),
                        ),
                        _buildFilterOptionTile(
                          title: 'Upcoming / Scheduled',
                          subtitle: 'Scheduled for future (startDate > now)',
                          icon: Icons.upcoming_rounded,
                          isSelected: tempTimeline == 'upcoming',
                          onTap: () =>
                              setModalState(() => tempTimeline = 'upcoming'),
                        ),
                        _buildFilterOptionTile(
                          title: 'Ended / Expired',
                          subtitle: 'Past closing date (endDate < now)',
                          icon: Icons.event_busy_rounded,
                          isSelected: tempTimeline == 'ended',
                          onTap: () =>
                              setModalState(() => tempTimeline = 'ended'),
                        ),

                        const SizedBox(height: 20),

                        // Footer Action Buttons: Reset + Apply Filters
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.25),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {
                                  setModalState(() {
                                    tempStatus = 'all';
                                    tempTimeline = 'all';
                                  });
                                  setState(() {
                                    _selectedStatus = 'all';
                                    _selectedTimeline = 'all';
                                  });
                                },
                                child: const Text(
                                  'Reset',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: cyanAccent,
                                  foregroundColor: const Color(0xFF0B132B),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _selectedStatus = tempStatus;
                                    _selectedTimeline = tempTimeline;
                                  });
                                  Navigator.pop(sheetContext);
                                },
                                child: const Text(
                                  'Apply Filters',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const cyanAccent = Color(0xFF00C2A8);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? cyanAccent.withValues(alpha: 0.15)
                  : const Color(0xFF162032).withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? cyanAccent
                    : Colors.white.withValues(alpha: 0.12),
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: isSelected ? cyanAccent : Colors.white70,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isSelected ? cyanAccent : Colors.white,
                          fontSize: 13.5,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.58),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  size: 19,
                  color: isSelected ? cyanAccent : Colors.white38,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyFilterResultCard({required int totalSurveysCount}) {
    final isFiltering =
        _searchController.text.trim().isNotEmpty || _hasActiveFilter;
    const cyanAccent = Color(0xFF00C2A8);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFiltering
                ? Icons.search_off_rounded
                : Icons.assignment_late_outlined,
            size: 38,
            color: cyanAccent,
          ),
          const SizedBox(height: 10),
          Text(
            isFiltering && totalSurveysCount > 0
                ? 'No Matching Surveys Found'
                : 'No surveys found.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isFiltering && totalSurveysCount > 0
                ? 'No surveys match your current search query or selected filter options.'
                : 'Create a new survey to begin collecting feedback from members.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              fontSize: 12.5,
            ),
          ),
          if (isFiltering) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: cyanAccent,
                side: const BorderSide(color: cyanAccent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedStatus = 'all';
                  _selectedTimeline = 'all';
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text(
                'Reset Search & Filters',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMainTable(
    List<Survey> surveys,
    WidgetRef ref,
    BuildContext context, {
    int totalSurveysCount = 0,
  }) {
    if (surveys.isEmpty) {
      return _buildEmptyFilterResultCard(totalSurveysCount: totalSurveysCount);
    }
    return Column(
      children: surveys
          .map(
            (s) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          s.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusChip(s.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildSchedule(s.startDate, s.endDate),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _buildBadge(
                              Icons.list,
                              '${s.questionsCount}',
                              Colors.blue,
                            ),
                            _buildBadge(
                              Icons.people,
                              '${s.respondentsCount}',
                              Colors.purple,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ActionButton(
                            icon: Icons.list_alt,
                            color: Colors.teal,
                            onTap: () => context.push(
                              '/admin/surveys/${s.id}?tab=questions',
                            ),
                          ),
                          _ActionButton(
                            icon: Icons.bar_chart,
                            color: Colors.blue,
                            onTap: () => context.push(
                              '/admin/surveys/${s.id}?tab=responses',
                            ),
                          ),
                          _ActionButton(
                            icon: Icons.edit,
                            color: Colors.purple,
                            onTap: () => _showEditSurveyModal(context, ref, s),
                          ),
                          _ActionButton(
                            icon: Icons.delete,
                            color: Colors.red,
                            onTap: () =>
                                _showDeleteSurveyModal(context, ref, s),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildLivePreviewSection(
    List<Survey> surveys, {
    int totalSurveysCount = 0,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.visibility, color: Colors.pinkAccent, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Survey Live Preview',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Real-time overview of active and draft surveys with live schedule status, respondent counts, and questionnaire details',
          style: TextStyle(
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        _buildSearchBar(), // Reusing search bar style for layout mirroring
        const SizedBox(height: 12),
        if (surveys.isEmpty)
          _buildEmptyFilterResultCard(totalSurveysCount: totalSurveysCount)
        else
          Column(
            children: surveys
                .map(
                  (s) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                s.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusChip(s.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildSchedule(s.startDate, s.endDate),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _buildBadge(
                              Icons.list,
                              '${s.questionsCount} Questions',
                              Colors.teal,
                            ),
                            _buildBadge(
                              Icons.people,
                              '${s.respondentsCount} Submissions',
                              Colors.purpleAccent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    final normalized = status.toLowerCase().trim();
    Color color;
    if (normalized == 'active') {
      color = Colors.greenAccent;
    } else if (normalized == 'closed' || normalized == 'inactive') {
      color = Colors.redAccent;
    } else {
      color = Colors.orangeAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status.capitalize(),
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedule(DateTime? start, DateTime? end) {
    if (start == null) return const Text('No schedule');
    final df = DateFormat('MMM dd, yyyy, h:mm a');
    return Row(
      children: [
        const Icon(Icons.calendar_month, color: Colors.pinkAccent, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                df.format(start),
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
              if (end != null)
                Text(
                  'to ${df.format(end)}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.54),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(value, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  void _showCreateSurveyModal(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Create Survey',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: titleController,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.54),
                  ),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: descController,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.54),
                  ),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isEmpty) return;
                  final repo = ref.read(surveyRepositoryProvider);
                  await repo.createSurvey(
                    Survey(
                      id: '',
                      title: titleController.text,
                      description: descController.text,
                    ),
                  );
                  if (context.mounted) Navigator.pop(context);
                },
                child: Text('Create'),
              ),
              SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteSurveyModal(
    BuildContext context,
    WidgetRef ref,
    Survey survey,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text(
                      'Delete Survey',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Divider(color: Colors.white10),
                SizedBox(height: 16),
                Text(
                  'Are you sure you want to permanently delete "${survey.title}"?',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error, color: Colors.redAccent, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This will remove all associated questions, choices, and submitted member responses. This action cannot be undone.',
                          style: TextStyle(
                            color: Colors.redAccent.shade200,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                Divider(color: Colors.white10),
                SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.white10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE040FB), Color(0xFFB000FF)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purpleAccent.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () {
                          ref
                              .read(surveyRepositoryProvider)
                              .deleteSurvey(survey.id);
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.delete, size: 18),
                        label: Text(
                          'Yes, Delete Survey',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditSurveyModal(
    BuildContext context,
    WidgetRef ref,
    Survey survey,
  ) {
    final titleController = TextEditingController(text: survey.title);
    final descController = TextEditingController(text: survey.description);
    String status = survey.status;

    // Default dates if null for UI logic
    DateTime startDate = survey.startDate ?? DateTime.now();
    DateTime endDate =
        survey.endDate ?? DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.white10),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.edit_square, color: Colors.pinkAccent),
                          SizedBox(width: 8),
                          Text(
                            'Edit Survey Details',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Divider(color: Colors.white10),
                      SizedBox(height: 16),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Survey Title *',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: titleController,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Colors.pinkAccent,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Colors.pinkAccent,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Survey Status *',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: status,
                                dropdownColor: Theme.of(
                                  context,
                                ).colorScheme.surface,
                                isExpanded: true,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                ),
                                icon: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'active',
                                    child: Text('Active'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'draft',
                                    child: Text('Draft'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'closed',
                                    child: Text('Closed'),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setModalState(() => status = val);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Description / Instructions',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: descController,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                            maxLines: 4,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Colors.pinkAccent,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Colors.pinkAccent,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Opening Date *',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: startDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (d != null) {
                                setModalState(
                                  () => startDate = DateTime(
                                    d.year,
                                    d.month,
                                    d.day,
                                    startDate.hour,
                                    startDate.minute,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.pinkAccent),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('MM/dd/yyyy').format(startDate),
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  Icon(
                                    Icons.calendar_month,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withOpacity(0.54),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Closing Date *',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: endDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (d != null) {
                                setModalState(
                                  () => endDate = DateTime(
                                    d.year,
                                    d.month,
                                    d.day,
                                    endDate.hour,
                                    endDate.minute,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.pinkAccent),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('MM/dd/yyyy').format(endDate),
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  Icon(
                                    Icons.calendar_month,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withOpacity(0.54),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Opening Time *',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(startDate),
                              );
                              if (t != null) {
                                setModalState(
                                  () => startDate = DateTime(
                                    startDate.year,
                                    startDate.month,
                                    startDate.day,
                                    t.hour,
                                    t.minute,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.pinkAccent),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat(
                                      'h:mm a',
                                    ).format(startDate).toLowerCase(),
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  Icon(
                                    Icons.access_time,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withOpacity(0.54),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Closing Time *',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(endDate),
                              );
                              if (t != null) {
                                setModalState(
                                  () => endDate = DateTime(
                                    endDate.year,
                                    endDate.month,
                                    endDate.day,
                                    t.hour,
                                    t.minute,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.pinkAccent),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat(
                                      'h:mm a',
                                    ).format(endDate).toLowerCase(),
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  Icon(
                                    Icons.access_time,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withOpacity(0.54),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 24),
                      Divider(color: Colors.white10),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white38,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE040FB), Color(0xFFB000FF)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purpleAccent.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              onPressed: () async {
                                if (titleController.text.isEmpty) return;
                                final updated = survey.copyWith(
                                  title: titleController.text,
                                  description: descController.text,
                                  status: status,
                                  startDate: startDate,
                                  endDate: endDate,
                                );
                                await ref
                                    .read(surveyRepositoryProvider)
                                    .updateSurvey(updated);
                                if (context.mounted) Navigator.pop(context);
                              },
                              icon: Icon(Icons.save, size: 18),
                              label: Text(
                                'Save Changes',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _StatsCarousel extends StatefulWidget {
  final int total;
  final int active;
  final int respondents;
  final int drafts;

  const _StatsCarousel({
    required this.total,
    required this.active,
    required this.respondents,
    required this.drafts,
  });

  @override
  State<_StatsCarousel> createState() => _StatsCarouselState();
}

class _StatsCarouselState extends State<_StatsCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (Timer timer) {
      if (!mounted) return;
      if (_currentPage < 3) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 125,
          child: PageView(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            children: [
              _StatCard(
                title: 'TOTAL SURVEYS',
                value: widget.total.toString(),
                subtitle: 'All registered surveys',
                icon: Icons.bar_chart,
                iconColor: Colors.blue,
                borderColor: Colors.blue.withValues(alpha: 0.5),
              ),
              _StatCard(
                title: 'ACTIVE SURVEYS',
                value: widget.active.toString(),
                subtitle: 'Open to members',
                icon: Icons.podcasts,
                iconColor: Colors.greenAccent,
                borderColor: Colors.greenAccent.withValues(alpha: 0.5),
              ),
              _StatCard(
                title: 'TOTAL RESPONDENTS',
                value: widget.respondents.toString(),
                subtitle: 'Unique submissions',
                icon: Icons.people,
                iconColor: Colors.purpleAccent,
                borderColor: Colors.purpleAccent.withValues(alpha: 0.5),
              ),
              _StatCard(
                title: 'DRAFT / INACTIVE',
                value: widget.drafts.toString(),
                subtitle: 'Unpublished / Closed',
                icon: Icons.insert_drive_file,
                iconColor: Colors.orangeAccent,
                borderColor: Colors.orangeAccent.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: _currentPage == index ? 24 : 8,
              decoration: BoxDecoration(
                color: _currentPage == index ? Colors.white : Colors.white38,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color borderColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withOpacity(0.54),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.list, size: 12, color: iconColor),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.54),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
