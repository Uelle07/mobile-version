import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';
import 'views/member_home_tab.dart';
import '../profile/views/member_profile_tab.dart';
import '../surveys/views/member_survey_list_tab.dart';
import '../../settings/views/settings_tab.dart';
import 'package:cooperative_member_app/core/widgets/space_app_bar.dart';

class MemberDashboardScreen extends ConsumerStatefulWidget {
  const MemberDashboardScreen({super.key});

  @override
  ConsumerState<MemberDashboardScreen> createState() =>
      _MemberDashboardScreenState();
}

class _MemberDashboardScreenState extends ConsumerState<MemberDashboardScreen> {
  int _currentIndex = 0;

  List<Widget> get _tabs => const [
    MemberHomeTab(),
    MemberProfileTab(),
    MemberSurveyListTab(),
    SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs;
    final safeIndex = _currentIndex.clamp(0, tabs.length - 1);

    return Scaffold(
      appBar: SpaceAppBar(
        title: const Text('Member Portal'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Log Out'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ref.read(authControllerProvider.notifier).signOut();
                      },
                      child: const Text('Log Out'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: tabs[safeIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.poll), label: 'Surveys'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
