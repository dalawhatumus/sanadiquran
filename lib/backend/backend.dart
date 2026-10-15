import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings.dart';
import 'admin.dart';
import 'calls.dart';
import 'chat.dart';
import 'photos.dart';
import 'sessions.dart';
import 'teachers.dart';

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
  const SavedProfile({
    this.name = '',
    this.role,
    this.gender,
    this.avatar,
    this.teacherStatus = TeacherStatus.none,
    this.ageGroup,
    this.nationality,
    this.phone,
    this.whatsapp = false,
  });

  final String name;
  final UserRole? role;
  final Gender? gender;
  final String? avatar;
  final TeacherStatus teacherStatus;
  final String? ageGroup;
  final String? nationality;
  final String? phone;
  final bool whatsapp;

  /// Fills the local settings from the saved profile.
  AppSettings applyTo(AppSettings s) => s.copyWith(
    signedIn: true,
    name: name.isEmpty ? null : name,
    role: role,
    gender: gender,
    avatar: avatar,
    teacherStatus: teacherStatus,
    ageGroup: ageGroup,
    nationality: nationality,
    phone: phone,
    whatsapp: whatsapp,
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
    this.sampleSec = 0,
  });

  /// Length of the recorded sample (0 if none was sent).
  final int sampleSec;

  final String uid;
  final String name;
  final Gender? gender;

  /// Answers in English, in the order they were asked (question → answer).
  final Map<String, String> answers;
  final DateTime? submitted;
}

/// Everything that needs the internet. [DemoBackend] stands in until
/// Firebase is configured, so the app can still be tried end to end.
abstract class Backend implements ChatApi, CallApi, LessonApi, AdminApi, TeacherDirectoryApi, PhotoApi {
  /// True when connected to the real server.
  bool get live;

  /// Opens the Google account picker and signs in.
  /// Throws [SignInCancelled] if the user closes it.
  Future<SignedInUser> signIn();

  Future<void> signOut();

  /// Saves the profile online (name, role, gender, picture, language, and
  /// the details asked when signing up).
  Future<void> saveProfile(AppSettings s);

  /// Sends a teacher application for review.
  Future<void> submitApplication({
    required String name,
    required Gender? gender,
    required Map<String, String> answers,
    Uint8List? sample,
    int sampleSec = 0,
  });

  /// Why an application was turned down (empty if no reason was given).
  Stream<String> applicationReason();

  /// The recitation sample sent with an application (admins).
  Future<Uint8List?> applicationSample(String uid);

  /// Marks a report as dealt with (admins).
  Future<void> resolveReport(String id);

  /// Deletes this user's account and personal data, then signs out.
  /// Throws [SignInCancelled] if a fresh Google sign-in was needed and
  /// the user closed it.
  Future<void> deleteAccount();

  /// Where this user's teacher application stands, live.
  Stream<TeacherStatus> teacherStatus();

  /// An approved teacher's "I'm available" switch, with the name and
  /// picture students see in the teacher list.
  Future<void> setAvailable({required bool on, required Gender? gender, String name = '', String? avatar});

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
class DemoBackend with DemoChat, DemoCalls, DemoLessons, DemoAdmin, DemoTeachers, DemoPhotos implements Backend {
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
    Uint8List? sample,
    int sampleSec = 0,
  }) async {}

  @override
  Stream<String> applicationReason() => Stream.value('');

  @override
  Future<Uint8List?> applicationSample(String uid) async => null;

  @override
  Future<void> resolveReport(String id) async {}

  @override
  Future<void> deleteAccount() async {}

  @override
  Stream<TeacherStatus> teacherStatus() => const Stream.empty();

  @override
  Future<void> setAvailable({required bool on, required Gender? gender, String name = '', String? avatar}) async {}

  @override
  Stream<int> availableTeachers(Gender? gender) => gender == null
      ? Stream.value(1)
      : teachers(gender).map((list) => list.where((t) => t.state == TeacherState.available).length);

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

final applicationReasonProvider = StreamProvider<String>((ref) => ref.watch(backendProvider).applicationReason());

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

  ref.listen(
    settingsProvider.select(
      (s) => (s.signedIn, s.name, s.role, s.gender, s.avatar, s.locale, s.ageGroup, s.nationality, s.phone, s.whatsapp),
    ),
    (_, next) {
      final s = ref.read(settingsProvider);
      if (s.signedIn && s.role != null) unawaited(backend.saveProfile(s).catchError((_) {}));
    },
    fireImmediately: true,
  );

  final status = backend.teacherStatus().listen((st) {
    final s = ref.read(settingsProvider);
    if (s.signedIn && s.teacherStatus != st) settings.update((x) => x.copyWith(teacherStatus: st));
  }, onError: (_) {});
  ref.onDispose(status.cancel);

  ref.listen(
    settingsProvider.select((s) => (s.signedIn, s.role, s.teacherStatus, s.available, s.gender, s.name, s.avatar)),
    (prev, next) {
      bool teaching((bool, UserRole?, TeacherStatus, bool, Gender?, String, String?)? x) =>
          x != null && x.$1 && x.$2 == UserRole.teacher && x.$3 == TeacherStatus.approved;
      if (teaching(next)) {
        unawaited(
          backend
              .setAvailable(on: next.$4, gender: next.$5, name: next.$6, avatar: next.$7)
              .then((_) => backend.setLessonsToday(lessonsToday(ref.read(lessonsProvider).value, backend.myUid)))
              .catchError((_) {}),
        );
      } else if (teaching(prev)) {
        unawaited(backend.setAvailable(on: false, gender: prev!.$5, name: prev.$6, avatar: prev.$7).catchError((_) {}));
      }
    },
    fireImmediately: true,
  );

  // An approved teacher's lesson count for today, for sharing out calls.
  ref.listen(lessonsProvider, (prev, next) {
    final s = ref.read(settingsProvider);
    if (!s.signedIn || s.role != UserRole.teacher || s.teacherStatus != TeacherStatus.approved) return;
    final before = lessonsToday(prev?.value, backend.myUid);
    final now = lessonsToday(next.value, backend.myUid);
    if (prev?.value == null || before != now) unawaited(backend.setLessonsToday(now).catchError((_) {}));
  });
});

/// Lessons [uid] gave as a teacher today.
int lessonsToday(List<Lesson>? lessons, String? uid) {
  final now = DateTime.now();
  return (lessons ?? const <Lesson>[])
      .where((l) => l.teacherId == uid && l.at.year == now.year && l.at.month == now.month && l.at.day == now.day)
      .length;
}
