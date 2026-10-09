import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/applications_screen.dart';
import '../features/admin/connect_screen.dart';
import '../features/athkar/athkar_menu_screen.dart';
import '../features/athkar/dhikr_screen.dart';
import '../features/call/call_screens.dart';
import '../features/messages/chat_screen.dart';
import '../features/messages/messages_screen.dart';
import '../features/onboarding/application_screens.dart';
import '../features/onboarding/language_screen.dart';
import '../features/onboarding/permission_screens.dart';
import '../features/onboarding/profile_screens.dart';
import '../features/onboarding/splash_screen.dart';
import '../features/onboarding/tour_screen.dart';
import '../features/onboarding/welcome_screen.dart';
import '../features/quran/mushaf_screen.dart';
import '../features/quran/surah_index_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/home_shell.dart';
import '../features/student/progress_screens.dart';
import '../features/student/student_home_screen.dart';
import '../features/teacher/students_screen.dart';
import '../features/teacher/teacher_home_screen.dart';
import 'settings.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const language = '/language';
  static const welcome = '/welcome';
  static const role = '/role';
  static const gender = '/gender';
  static const name = '/name';
  static const permMic = '/perm/mic';
  static const permNotif = '/perm/notif';
  static const permFullScreen = '/perm/fullscreen';
  static const tour = '/tour';
  static const apply = '/apply';
  static const applySent = '/apply/sent';

  static const studentHome = '/s/home';
  static const studentQuran = '/s/quran';
  static const studentAthkar = '/s/athkar';
  static const studentMessages = '/s/messages';

  static const teacherHome = '/t/home';
  static const teacherStudents = '/t/students';
  static const teacherQuran = '/t/quran';
  static const teacherMessages = '/t/messages';

  static const settings = '/settings';
  static const progress = '/progress';
  static const teacherNotes = '/notes';
  static const connecting = '/call/connecting';
  static const inCall = '/call/live';
  static const studentEnded = '/call/ended';
  static const incoming = '/call/incoming';
  static const teacherEnded = '/call/teacher-ended';
  static const notesForm = '/call/notes';
  static const mushaf = '/mushaf';
  static const athkar = '/athkar';
  static const admin = '/admin';
  static const adminConnect = '/admin/connect';
  static const adminReports = '/admin/reports';

  static String chat(String conversationId) => '/chat/$conversationId';

  static String homeFor(UserRole role) => role == UserRole.student ? studentHome : teacherHome;
  static String athkarFor(UserRole? role) => role == UserRole.teacher ? athkar : studentAthkar;

  static String mushafAt({int? sura, int? ayah, int? page}) {
    final q = [
      if (sura != null) 'sura=$sura',
      if (ayah != null) 'ayah=$ayah',
      if (page != null) 'page=$page',
    ].join('&');
    return q.isEmpty ? mushaf : '$mushaf?$q';
  }
}

/// The first onboarding step the user hasn't finished, or their home.
String nextStep(AppSettings s) {
  if (s.locale == null) return Routes.language;
  if (!s.signedIn) return Routes.welcome;
  if (s.role == null) return Routes.role;
  if (s.gender == null) return Routes.gender;
  if (s.name.trim().isEmpty) return Routes.name;
  if (!s.permissionsDone) return Routes.permMic;
  if (s.role == UserRole.student && !s.tourDone) return Routes.tour;
  if (s.role == UserRole.teacher && s.teacherStatus == TeacherStatus.none) return '${Routes.apply}/1';
  return Routes.homeFor(s.role!);
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.splash,
    redirect: (context, state) {
      final s = ref.read(settingsProvider);
      final path = state.matchedLocation;
      final inShell = path.startsWith('/s/') || path.startsWith('/t/');
      if (!inShell) return null;
      final step = nextStep(s);
      final done = step == Routes.studentHome || step == Routes.teacherHome;
      if (!done) return step;
      final wrongShell = s.role == UserRole.student ? path.startsWith('/t/') : path.startsWith('/s/');
      return wrongShell ? Routes.homeFor(s.role!) : null;
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.language, builder: (_, _) => const LanguageScreen()),
      GoRoute(path: Routes.welcome, builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: Routes.role, builder: (_, _) => const RoleScreen()),
      GoRoute(path: Routes.gender, builder: (_, _) => const GenderScreen()),
      GoRoute(path: Routes.name, builder: (_, _) => const NameScreen()),
      GoRoute(
        path: '/perm/:kind',
        builder: (_, st) => PermissionScreen(kind: PermKind.fromPath(st.pathParameters['kind']!)),
      ),
      GoRoute(
        path: '/perm-denied/:kind',
        builder: (_, st) => PermissionDeniedScreen(kind: PermKind.fromPath(st.pathParameters['kind']!)),
      ),
      GoRoute(path: Routes.tour, builder: (_, _) => const TourScreen()),
      GoRoute(path: Routes.applySent, builder: (_, _) => const ApplicationSentScreen()),
      GoRoute(
        path: '${Routes.apply}/:step',
        builder: (_, st) => ApplicationScreen(step: int.tryParse(st.pathParameters['step']!) ?? 1),
      ),
      GoRoute(path: Routes.settings, builder: (_, _) => const SettingsScreen()),
      GoRoute(path: Routes.admin, builder: (_, _) => const ApplicationsScreen()),
      GoRoute(path: Routes.adminConnect, builder: (_, _) => const ConnectScreen()),
      GoRoute(path: Routes.adminReports, builder: (_, _) => const ReportsScreen()),
      GoRoute(
        path: '/chat/:id',
        builder: (_, st) =>
            ChatScreen(key: ValueKey(st.pathParameters['id']), conversationId: st.pathParameters['id']!),
      ),
      GoRoute(path: Routes.progress, builder: (_, _) => const ProgressScreen()),
      GoRoute(path: Routes.teacherNotes, builder: (_, _) => const TeacherNotesScreen()),
      GoRoute(
        path: Routes.connecting,
        builder: (_, st) => ConnectingScreen(teacherId: st.uri.queryParameters['teacher']),
      ),
      GoRoute(
        path: Routes.inCall,
        builder: (_, st) => InCallScreen(asTeacher: st.uri.queryParameters['teacher'] == '1'),
      ),
      GoRoute(
        path: Routes.studentEnded,
        builder: (_, st) => StudentCallEndedScreen(seconds: int.tryParse(st.uri.queryParameters['s'] ?? '') ?? 0),
      ),
      GoRoute(
        path: Routes.incoming,
        builder: (_, st) => IncomingCallScreen(callId: st.uri.queryParameters['id']),
      ),
      GoRoute(
        path: Routes.teacherEnded,
        builder: (_, st) => TeacherCallEndedScreen(seconds: int.tryParse(st.uri.queryParameters['s'] ?? '') ?? 0),
      ),
      GoRoute(path: Routes.notesForm, builder: (_, _) => const NotesFormScreen()),
      GoRoute(
        path: Routes.mushaf,
        builder: (_, st) {
          final q = st.uri.queryParameters;
          return MushafScreen(
            sura: int.tryParse(q['sura'] ?? ''),
            ayah: int.tryParse(q['ayah'] ?? ''),
            page: int.tryParse(q['page'] ?? ''),
          );
        },
      ),
      GoRoute(path: Routes.athkar, builder: (_, _) => const AthkarMenuScreen(standalone: true)),
      GoRoute(
        path: '${Routes.athkar}/:set',
        builder: (_, st) => DhikrScreen(key: ValueKey(st.pathParameters['set']), setId: st.pathParameters['set']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell, teacher: false),
        branches: [
          _branch(Routes.studentHome, const StudentHomeScreen()),
          _branch(Routes.studentQuran, const SurahIndexScreen()),
          _branch(Routes.studentAthkar, const AthkarMenuScreen()),
          _branch(Routes.studentMessages, const MessagesScreen()),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell, teacher: true),
        branches: [
          _branch(Routes.teacherHome, const TeacherHomeScreen()),
          _branch(Routes.teacherStudents, const StudentsScreen()),
          _branch(Routes.teacherQuran, const SurahIndexScreen()),
          _branch(Routes.teacherMessages, const MessagesScreen()),
        ],
      ),
    ],
  );
});

StatefulShellBranch _branch(String path, Widget screen) => StatefulShellBranch(
  routes: [GoRoute(path: path, builder: (_, _) => screen)],
);
