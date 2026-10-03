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
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final surveysAsync = ref.watch(surveysProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF131524), // Web-like dark background
      body: surveysAsync.when(
        data: (surveys) {
          // Calculate Stats
          final totalSurveys = surveys.length;
          final activeSurveys = surveys.where((s) => s.status == 'active').length;
          final draftSurveys = surveys.where((s) => s.status == 'draft' || s.status == 'closed').length;
          final totalRespondents = surveys.fold<int>(0, (sum, s) => sum + s.respondentsCount);

          // Filter
          final filteredSurveys = surveys.where((s) => 
            s.title.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildStatsCards(
                  total: totalSurveys, 
                  active: activeSurveys, 
                  respondents: totalRespondents, 
                  drafts: draftSurveys
                ),
                const SizedBox(height: 24),
                _buildSearchBar(),
                const SizedBox(height: 16),
                _buildMainTable(filteredSurveys, ref, context),
                const SizedBox(height: 32),
                _buildLivePreviewSection(filteredSurveys),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Cooperative Survey Management', 
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)
            ),
            SizedBox(height: 4),
            Text('Create, monitor, and analyze member feedback surveys', 
              style: TextStyle(color: Colors.grey, fontSize: 14)
            ),
          ],
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC042FF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onPressed: () => _showCreateSurveyModal(context),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Create New Survey'),
        )
      ],
    );
  }

  Widget _buildStatsCards({required int total, required int active, required int respondents, required int drafts}) {
    return _StatsCarousel(
      total: total,
      active: active,
      respondents: respondents,
      drafts: drafts,
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E213A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10)
            ),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: const InputDecoration(
                hintText: 'Search surveys by title...',
                hintStyle: TextStyle(color: Colors.white38),
                prefixIcon: Icon(Icons.search, color: Colors.white38),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E213A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10)
          ),
          child: IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () {},
          ),
        )
      ],
    );
  }

  Widget _buildMainTable(List<Survey> surveys, WidgetRef ref, BuildContext context) {
    if (surveys.isEmpty) {
      return const Center(child: Text('No surveys found.', style: TextStyle(color: Colors.white54)));
    }
    return Column(
      children: surveys.map((s) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E213A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    s.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusChip(s.status),
              ],
            ),
            const SizedBox(height: 12),
            _buildSchedule(s.startDate, s.endDate),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildBadge(Icons.list, '${s.questionsCount}', Colors.blue),
                    const SizedBox(width: 8),
                    _buildBadge(Icons.people, '${s.respondentsCount}', Colors.purple),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ActionButton(icon: Icons.list_alt, color: Colors.teal, onTap: () => context.push('/admin/surveys/${s.id}')),
                    _ActionButton(icon: Icons.bar_chart, color: Colors.blue, onTap: () {}),
                    _ActionButton(icon: Icons.edit, color: Colors.purple, onTap: () {}),
                    _ActionButton(icon: Icons.delete, color: Colors.red, onTap: () {
                       ref.read(surveyRepositoryProvider).deleteSurvey(s.id);
                    }),
                  ],
                ),
              ],
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildLivePreviewSection(List<Survey> surveys) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.visibility, color: Colors.pinkAccent),
            SizedBox(width: 8),
            Text('Survey Live Preview', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        const Text('Real-time overview of active and draft surveys with live schedule status, respondent counts, and questionnaire details', 
          style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 16),
        _buildSearchBar(), // Reusing search bar style for layout mirroring
        const SizedBox(height: 16),
        if (surveys.isEmpty)
          const Center(child: Text('No surveys found.', style: TextStyle(color: Colors.white54)))
        else
          Column(
            children: surveys.map((s) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E213A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Code: ${s.id.length > 8 ? s.id.substring(0, 8) : s.id}', 
                        style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold, fontSize: 12)
                      ),
                      _buildStatusChip(s.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  _buildSchedule(s.startDate, s.endDate),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _buildBadge(Icons.list, '${s.questionsCount} Questions', Colors.teal),
                      const SizedBox(width: 12),
                      _buildBadge(Icons.people, '${s.respondentsCount} Submissions', Colors.purpleAccent),
                    ],
                  ),
                ],
              ),
            )).toList(),
          ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    if (status == 'active') color = Colors.greenAccent;
    else if (status == 'closed') color = Colors.redAccent;
    else color = Colors.orangeAccent;

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
          Text(status.capitalize(), style: TextStyle(color: color, fontSize: 12)),
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(df.format(start), style: const TextStyle(fontSize: 12)),
            if (end != null) Text('to ${df.format(end)}', style: const TextStyle(fontSize: 10, color: Colors.white54)),
          ],
        )
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
          const SizedBox(width: 4),
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
      backgroundColor: const Color(0xFF1E213A),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16, right: 16, top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Create Survey', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Title', labelStyle: TextStyle(color: Colors.white54), border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Description', labelStyle: TextStyle(color: Colors.white54), border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isEmpty) return;
                  final repo = ref.read(surveyRepositoryProvider);
                  await repo.createSurvey(Survey(
                    id: '', 
                    title: titleController.text,
                    description: descController.text,
                  ));
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Create'),
              ),
              const SizedBox(height: 24),
            ],
          ),
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
        const SizedBox(height: 12),
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
        color: const Color(0xFF1E213A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(color: borderColor.withValues(alpha: 0.2), blurRadius: 8, spreadRadius: 1)
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.list, size: 12, color: iconColor),
              const SizedBox(width: 4),
              Expanded(child: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 10))),
            ],
          )
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.color, required this.onTap});

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
