import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings.dart';
import 'backend.dart';

/// A person in the admin's user list.
class UserEntry {
  const UserEntry({
    required this.uid,
    required this.name,
    this.role,
    this.gender,
    this.paused = false,
    this.avatar,
    this.ageGroup,
    this.nationality,
    this.phone,
    this.whatsapp = false,
  });

  final String uid;
  final String name;
  final UserRole? role;
  final Gender? gender;
  final String? avatar;
  final String? ageGroup;
  final String? nationality;
  final String? phone;

  /// Asked to join Sanadi's WhatsApp community.
  final bool whatsapp;

  /// An admin has paused this account.
  final bool paused;

  UserEntry copyWithPaused(bool paused) => UserEntry(
    uid: uid,
    name: name,
    role: role,
    gender: gender,
    paused: paused,
    avatar: avatar,
    ageGroup: ageGroup,
    nationality: nationality,
    phone: phone,
    whatsapp: whatsapp,
  );
}

/// A short message from the admins, shown on the home screen. Written in
/// the admin portal, in English and/or Arabic, for everyone or one role.
class Announcement {
  const Announcement({required this.id, this.textEn = '', this.textAr = '', this.audience = 'all', this.until});

  final String id;
  final String textEn;
  final String textAr;

  /// 'all', 'student' or 'teacher'.
  final String audience;

  /// Shown until then (null: until an admin removes it).
  final DateTime? until;

  /// The text in the person's language, or the other one if that's empty.
  String text({required bool ar}) => ar ? (textAr.isNotEmpty ? textAr : textEn) : (textEn.isNotEmpty ? textEn : textAr);

  /// Whether it is for this person, now.
  bool showsTo(UserRole? role, DateTime now) =>
      (audience == 'all' || audience == role?.name) && (until == null || until!.isAfter(now));
}

/// The admin's overview. A value is null when it couldn't be counted.
class AdminStats {
  const AdminStats({
    this.students,
    this.teachers,
    this.teachersOn,
    this.pendingApplications,
    this.openReports,
    this.lessonsWeek,
    this.minutesWeek,
  });

  final int? students;

  /// Approved teachers.
  final int? teachers;

  /// Teachers with "available" switched on.
  final int? teachersOn;
  final int? pendingApplications;
  final int? openReports;

  /// Lessons and minutes taught in the last 7 days.
  final int? lessonsWeek;
  final int? minutesWeek;
}

/// Pausing accounts and the admin's overview. Pausing is enforced by the
/// server rules: a paused person can't send messages, start or take calls,
/// or switch on "available".
abstract interface class AdminApi {
  /// Whether this user's own account is paused, live.
  Stream<bool> paused();

  /// Everyone with a profile, by name, with whether they are paused
  /// (admins only).
  Stream<List<UserEntry>> users();

  /// Pauses or restores an account (admins only). Pausing also switches the
  /// person's "available" off.
  Future<void> setPaused(String uid, {required bool paused, String reason = ''});

  /// Counts for the overview (admins only).
  Future<AdminStats> stats();

  /// Notes that this person opened the app now (and that they joined now, if
  /// that was never noted), for the admins' overview.
  Future<void> markActive();

  /// The admins' announcements, newest first.
  Stream<List<Announcement>> announcements();
}

final pausedProvider = StreamProvider<bool>((ref) => ref.watch(backendProvider).paused());
final usersProvider = StreamProvider<List<UserEntry>>((ref) => ref.watch(backendProvider).users());
final announcementsProvider = StreamProvider<List<Announcement>>((ref) => ref.watch(backendProvider).announcements());

/// Marks this person active, at most once a day (read by the home tabs).
final markActiveProvider = FutureProvider<void>((ref) async {
  final prefs = ref.read(sharedPreferencesProvider);
  final today = DateTime.now().toIso8601String().substring(0, 10);
  if (prefs.getString(_kActiveDay) == today) return;
  await ref.read(backendProvider).markActive();
  await prefs.setString(_kActiveDay, today);
});
const _kActiveDay = 'lastActiveDay';

/// Demo mode: a few sample people; pausing is kept in memory.
mixin DemoAdmin implements AdminApi {
  final _pausedIds = <String>{};
  final _adminChanges = StreamController<void>.broadcast();

  static const _people = [
    UserEntry(
      uid: 'demo',
      name: 'Fatima',
      role: UserRole.student,
      gender: Gender.female,
      ageGroup: '25-34',
      nationality: 'SA',
      phone: '+966500000001',
      whatsapp: true,
    ),
    UserEntry(
      uid: 'demo-teacher',
      name: 'Aisha Rahman',
      role: UserRole.teacher,
      gender: Gender.female,
      ageGroup: '35-44',
      nationality: 'EG',
      phone: '+201000000002',
    ),
    UserEntry(uid: 'demo-student-2', name: 'Ahmad', role: UserRole.student, gender: Gender.male),
  ];

  List<UserEntry> _list() => [for (final p in _people) p.copyWithPaused(_pausedIds.contains(p.uid))];

  @override
  Stream<bool> paused() => Stream.value(false);

  @override
  Stream<List<UserEntry>> users() async* {
    yield _list();
    await for (final _ in _adminChanges.stream) {
      yield _list();
    }
  }

  @override
  Future<void> setPaused(String uid, {required bool paused, String reason = ''}) async {
    paused ? _pausedIds.add(uid) : _pausedIds.remove(uid);
    _adminChanges.add(null);
  }

  @override
  Future<AdminStats> stats() async => const AdminStats(
    students: 2,
    teachers: 1,
    teachersOn: 1,
    pendingApplications: 0,
    openReports: 0,
    lessonsWeek: 2,
    minutesWeek: 33,
  );

  @override
  Future<void> markActive() async {}

  @override
  Stream<List<Announcement>> announcements() => Stream.value(const []);
}

/// Sorts people by name, ignoring case.
List<T> byName<T>(List<T> list, String Function(T) name) =>
    list..sort((a, b) => name(a).toLowerCase().compareTo(name(b).toLowerCase()));
