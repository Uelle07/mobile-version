import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/models/user_role.dart';
import '../../screens/login_screen.dart';
import '../../screens/register_screen.dart';
import '../../features/admin/dashboard/admin_dashboard_screen.dart';
import '../../features/admin/members/views/add_member_screen.dart';
import '../../features/admin/members/views/member_details_screen.dart';
import '../../features/admin/surveys/views/survey_overview_screen.dart';
import '../../features/admin/surveys/views/survey_details_screen.dart';
import '../../features/member/dashboard/member_dashboard_screen.dart';
import '../../features/member/profile/views/photo_upload_screen.dart';
import '../../features/member/profile/views/member_information_screen.dart';
import '../../features/member/profile/views/member_update_info_screen.dart';
import '../../features/member/profile/views/change_password_screen.dart';
import '../../features/member/surveys/views/member_survey_details_screen.dart';
import '../../features/member/surveys/views/member_survey_list_tab.dart';
import '../../features/member/surveys/views/member_survey_success_screen.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/login',
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.amber,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Page Not Found',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  state.error?.toString() ??
                      'The requested page could not be found.',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.go('/member'),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Return to Dashboard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    redirect: (context, state) {
      if (authState.isLoading || authState.hasError) return null;

      final authData = authState.value;
      final isAuth = authData?.user != null;
      final isLoginRoute = state.matchedLocation == '/login';
      final isRegisterRoute = state.matchedLocation == '/register';

      if (!isAuth) {
        return (isLoginRoute || isRegisterRoute) ? null : '/login';
      }

      if (isLoginRoute || isRegisterRoute) {
        if (authData?.role == UserRole.admin) return '/admin';
        if (authData?.role == UserRole.member) return '/member';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
        routes: [
          GoRoute(
            path: 'add-member',
            builder: (context, state) => const AddMemberScreen(),
          ),
          GoRoute(
            path: 'member-details/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return MemberDetailsScreen(memberId: id);
            },
          ),
          GoRoute(
            path: 'surveys',
            builder: (context, state) => const SurveyOverviewScreen(),
          ),
          GoRoute(
            path: 'surveys/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              final tab = state.uri.queryParameters['tab'];
              return SurveyDetailsScreen(surveyId: id, initialTab: tab);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/member',
        builder: (context, state) => const MemberDashboardScreen(),
        routes: [
          GoRoute(
            path: 'upload-photo',
            builder: (context, state) => const PhotoUploadScreen(),
          ),
          GoRoute(
            path: 'information',
            builder: (context, state) => const MemberInformationScreen(),
          ),
          GoRoute(
            path: 'update-info',
            builder: (context, state) => const MemberUpdateInfoScreen(),
          ),
          GoRoute(
            path: 'surveys',
            builder: (context, state) => const MemberSurveysScreen(),
          ),
          GoRoute(
            path: 'take-survey/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return MemberSurveyDetailsScreen(surveyId: id);
            },
          ),
          GoRoute(
            path: 'survey-success/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return MemberSurveySuccessScreen(surveyId: id);
            },
          ),
          GoRoute(
            path: 'change-password',
            builder: (context, state) => const ChangePasswordScreen(),
          ),
        ],
      ),
    ],
  );
}
