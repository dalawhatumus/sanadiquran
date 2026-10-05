import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/athkar/athkar_screen.dart';
import '../features/messages/messages_screen.dart';
import '../features/onboarding/language_screen.dart';
import '../features/onboarding/role_screen.dart';
import '../features/onboarding/welcome_screen.dart';
import '../features/quran/quran_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/home_shell.dart';
import '../features/student/student_home_screen.dart';
import '../features/teacher/students_screen.dart';
import '../features/teacher/teacher_home_screen.dart';
import 'settings.dart';

abstract final class Routes {
  static const language = '/language';
  static const welcome = '/welcome';
  static const role = '/role';
  static const settings = '/settings';

  static const studentHome = '/s/home';
  static const studentQuran = '/s/quran';
  static const studentAthkar = '/s/athkar';
  static const studentMessages = '/s/messages';

  static const teacherHome = '/t/home';
  static const teacherStudents = '/t/students';
  static const teacherQuran = '/t/quran';
  static const teacherMessages = '/t/messages';

  static String homeFor(UserRole role) =>
      role == UserRole.student ? studentHome : teacherHome;
}

final routerProvider = Provider<GoRouter>((ref) {
  // Re-run redirects whenever language or role changes.
  final refresh = ValueNotifier<int>(0);
  ref.listen(settingsProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.language,
    refreshListenable: refresh,
    redirect: (context, state) {
      final settings = ref.read(settingsProvider);
      final path = state.matchedLocation;

      if (settings.locale == null) {
        return path == Routes.language ? null : Routes.language;
      }
      final role = settings.role;
      if (role == null) {
        const onboarding = {Routes.language, Routes.welcome, Routes.role};
        return onboarding.contains(path) && path != Routes.language
            ? null
            : Routes.welcome;
      }
      final inOtherShell = role == UserRole.student
          ? path.startsWith('/t/')
          : path.startsWith('/s/');
      if (path == Routes.language ||
          path == Routes.welcome ||
          path == Routes.role ||
          inOtherShell) {
        return Routes.homeFor(role);
      }
      return null;
    },
    routes: [
      GoRoute(path: Routes.language, builder: (_, _) => const LanguageScreen()),
      GoRoute(path: Routes.welcome, builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: Routes.role, builder: (_, _) => const RoleScreen()),
      GoRoute(path: Routes.settings, builder: (_, _) => const SettingsScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            HomeShell(shell: shell, tabs: studentTabs),
        branches: [
          _branch(Routes.studentHome, const StudentHomeScreen()),
          _branch(Routes.studentQuran, const QuranScreen()),
          _branch(Routes.studentAthkar, const AthkarScreen()),
          _branch(Routes.studentMessages, const MessagesScreen()),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            HomeShell(shell: shell, tabs: teacherTabs),
        branches: [
          _branch(Routes.teacherHome, const TeacherHomeScreen()),
          _branch(Routes.teacherStudents, const StudentsScreen()),
          _branch(Routes.teacherQuran, const QuranScreen()),
          _branch(Routes.teacherMessages, const MessagesScreen()),
        ],
      ),
    ],
  );
});

StatefulShellBranch _branch(String path, Widget screen) => StatefulShellBranch(
      routes: [GoRoute(path: path, builder: (_, _) => screen)],
    );
