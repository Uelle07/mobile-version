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

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/login',
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
        ],
      ),
    ],
  );
}
