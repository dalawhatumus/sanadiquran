import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings.dart';
import 'backend.dart';

/// A person in the admin's user list.
class UserEntry {
  const UserEntry({required this.uid, required this.name, this.role, this.gender, this.paused = false});

  final String uid;
  final String name;
  final UserRole? role;
  final Gender? gender;

  /// An admin has paused this account.
  final bool paused;
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
}

final pausedProvider = StreamProvider<bool>((ref) => ref.watch(backendProvider).paused());
final usersProvider = StreamProvider<List<UserEntry>>((ref) => ref.watch(backendProvider).users());

/// Demo mode: a few sample people; pausing is kept in memory.
mixin DemoAdmin implements AdminApi {
  final _pausedIds = <String>{};
  final _adminChanges = StreamController<void>.broadcast();

  static const _people = [
    UserEntry(uid: 'demo', name: 'Fatima', role: UserRole.student, gender: Gender.female),
    UserEntry(uid: 'demo-teacher', name: 'Aisha Rahman', role: UserRole.teacher, gender: Gender.female),
    UserEntry(uid: 'demo-student-2', name: 'Ahmad', role: UserRole.student, gender: Gender.male),
  ];

  List<UserEntry> _list() => [
    for (final p in _people)
      UserEntry(uid: p.uid, name: p.name, role: p.role, gender: p.gender, paused: _pausedIds.contains(p.uid)),
  ];

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
}

/// Sorts people by name, ignoring case.
List<T> byName<T>(List<T> list, String Function(T) name) =>
    list..sort((a, b) => name(a).toLowerCase().compareTo(name(b).toLowerCase()));
