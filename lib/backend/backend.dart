import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings.dart';
import 'calls.dart';
import 'chat.dart';
import 'sessions.dart';

/// What the server knows about a user who just signed in.
class SignedInUser {
  const SignedInUser({required this.uid, this.googleName, this.profile});

  final String uid;

  /// The name on their Google account, offered on the name screen.
  final String? googleName;

  /// Their saved profile when they have used Sanadi before (for example on
  /// another phone), or null for a new user.
  final SavedProfile? profile;
}

/// The parts of a profile kept online.
class SavedProfile {
  const SavedProfile({this.name = '', this.role, this.gender, this.avatar, this.teacherStatus = TeacherStatus.none});

  final String name;
  final UserRole? role;
  final Gender? gender;
  final String? avatar;
  final TeacherStatus teacherStatus;

  /// Fills the local settings from the saved profile.
  AppSettings applyTo(AppSettings s) => s.copyWith(
    signedIn: true,
    name: name.isEmpty ? null : name,
    role: role,
    gender: gender,
    avatar: avatar,
    teacherStatus: teacherStatus,
    // They have seen the tour before.
    tourDone: role != null ? true : null,
  );
}

/// The user closed the Google account picker.
class SignInCancelled implements Exception {
  const SignInCancelled();
}

/// A teacher application waiting for an admin's decision.
class TeacherApplication {
  const TeacherApplication({
    required this.uid,
    required this.name,
    required this.gender,
    required this.answers,
    this.submitted,
  });

  final String uid;
  final String name;
  final Gender? gender;

  /// Answers in English, in the order they were asked (question → answer).
  final Map<String, String> answers;
  final DateTime? submitted;
}

/// Everything that needs the internet. [DemoBackend] stands in until
/// Firebase is configured, so the app can still be tried end to end.
abstract class Backend implements ChatApi, CallApi, LessonApi {
  /// True when connected to the real server.
  bool get live;

  /// Opens the Google account picker and signs in.
  /// Throws [SignInCancelled] if the user closes it.
  Future<SignedInUser> signIn();

  Future<void> signOut();

  /// Saves the profile online (name, role, gender, picture, language).
  Future<void> saveProfile(AppSettings s);

  /// Sends a teacher application for review.
  Future<void> submitApplication({required String name, required Gender? gender, required Map<String, String> answers});

  /// Where this user's teacher application stands, live.
  Stream<TeacherStatus> teacherStatus();

  /// An approved teacher's "I'm available" switch.
  Future<void> setAvailable({required bool on, required Gender? gender});

  /// How many teachers of this gender are available now.
  Stream<int> availableTeachers(Gender? gender);

  /// Whether this user may review teacher applications.
  Stream<bool> isAdmin();

  /// Applications waiting for review, oldest first (admins only).
  Stream<List<TeacherApplication>> pendingApplications();

  /// Approves or turns down an application (admins only).
  Future<void> decide(String uid, {required bool approve, String reason = ''});
}

/// Overridden in main() with the Firebase backend when it is configured.
final backendProvider = Provider<Backend>((ref) => DemoBackend());

/// Works without a server: sign-in just continues, and the testing tools in
/// Settings stand in for an admin.
class DemoBackend with DemoChat, DemoCalls, DemoLessons implements Backend {
  @override
  bool get live => false;

  @override
  Future<SignedInUser> signIn() async => const SignedInUser(uid: 'demo');

  @override
  Future<void> signOut() async {}

  @override
  Future<void> saveProfile(AppSettings s) async {}

  @override
  Future<void> submitApplication({
    required String name,
    required Gender? gender,
    required Map<String, String> answers,
  }) async {}

  @override
  Stream<TeacherStatus> teacherStatus() => const Stream.empty();

  @override
  Future<void> setAvailable({required bool on, required Gender? gender}) async {}

  @override
  Stream<int> availableTeachers(Gender? gender) => Stream.value(3);

  @override
  Stream<bool> isAdmin() => Stream.value(false);

  @override
  Stream<List<TeacherApplication>> pendingApplications() => Stream.value(const []);

  @override
  Future<void> decide(String uid, {required bool approve, String reason = ''}) async {}
}

/// Name from Google, offered on the name screen (not saved until confirmed).
class SuggestedNameNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String name) => state = name;
}

final suggestedNameProvider = NotifierProvider<SuggestedNameNotifier, String>(SuggestedNameNotifier.new);

final availableTeachersProvider = StreamProvider.family<int, Gender?>(
  (ref, gender) => ref.watch(backendProvider).availableTeachers(gender),
);

final isAdminProvider = StreamProvider<bool>((ref) => ref.watch(backendProvider).isAdmin());

final pendingApplicationsProvider = StreamProvider<List<TeacherApplication>>(
  (ref) => ref.watch(backendProvider).pendingApplications(),
);

/// Keeps the server and this phone in step while the app runs: saves the
/// profile when it changes, follows the teacher's application status, and
/// publishes the "I'm available" switch. Watched once, by the app.
final backendSyncProvider = Provider<void>((ref) {
  final backend = ref.watch(backendProvider);
  if (!backend.live) return;
  final settings = ref.read(settingsProvider.notifier);

  ref.listen(settingsProvider.select((s) => (s.signedIn, s.name, s.role, s.gender, s.avatar, s.locale)), (_, next) {
    final s = ref.read(settingsProvider);
    if (s.signedIn && s.role != null) unawaited(backend.saveProfile(s).catchError((_) {}));
  }, fireImmediately: true);

  final status = backend.teacherStatus().listen((st) {
    final s = ref.read(settingsProvider);
    if (s.signedIn && s.teacherStatus != st) settings.update((x) => x.copyWith(teacherStatus: st));
  }, onError: (_) {});
  ref.onDispose(status.cancel);

  ref.listen(settingsProvider.select((s) => (s.signedIn, s.role, s.teacherStatus, s.available, s.gender)), (
    prev,
    next,
  ) {
    bool teaching((bool, UserRole?, TeacherStatus, bool, Gender?)? x) =>
        x != null && x.$1 && x.$2 == UserRole.teacher && x.$3 == TeacherStatus.approved;
    if (teaching(next)) {
      unawaited(backend.setAvailable(on: next.$4, gender: next.$5).catchError((_) {}));
    } else if (teaching(prev)) {
      unawaited(backend.setAvailable(on: false, gender: prev!.$5).catchError((_) {}));
    }
  }, fireImmediately: true);
});
