import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings.dart';
import 'backend.dart';

/// Where a teacher is right now.
enum TeacherState {
  /// Switched on, with the app open, and not in a lesson.
  available,

  /// In a lesson.
  busy,

  /// Switched off, or the app isn't open.
  away,
}

/// A teacher as students see them: first name and picture only.
class TeacherEntry {
  const TeacherEntry({required this.uid, required this.name, this.avatar, this.state = TeacherState.away});

  final String uid;
  final String name;
  final String? avatar;
  final TeacherState state;
}

/// The teachers a student can call, and "Alert me when a teacher is free".
abstract interface class TeacherDirectoryApi {
  /// Approved teachers of this gender: available first, then in a lesson,
  /// then away, each by name. Live.
  Stream<List<TeacherEntry>> teachers(Gender gender);

  /// A student asks to be alerted when a teacher is free, until [until]
  /// (null: no longer waiting). Teachers see how many are waiting.
  Future<void> setWaiting({required Gender gender, DateTime? until});

  /// How many students of this gender are waiting for a teacher (for a
  /// teacher's home). Live.
  Stream<int> waitingStudents(Gender gender);
}

final teachersProvider = StreamProvider.family<List<TeacherEntry>, Gender>(
  (ref, gender) => ref.watch(backendProvider).teachers(gender),
);

final waitingStudentsProvider = StreamProvider.family<int, Gender>(
  (ref, gender) => ref.watch(backendProvider).waitingStudents(gender),
);

/// Orders teachers: available, in a lesson, away; then by name.
List<TeacherEntry> sortTeachers(Iterable<TeacherEntry> list) => list.toList()
  ..sort((a, b) {
    final byState = a.state.index.compareTo(b.state.index);
    return byState != 0 ? byState : a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });

/// Teachers the student marked with a heart (kept on this phone).
class FavoriteTeachers extends Notifier<Set<String>> {
  static const _key = 'favoriteTeachers';

  @override
  Set<String> build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const {};
    try {
      return {for (final x in jsonDecode(raw) as List) '$x'};
    } catch (_) {
      return const {};
    }
  }

  void toggle(String uid) {
    state = state.contains(uid) ? ({...state}..remove(uid)) : {...state, uid};
    ref.read(sharedPreferencesProvider).setString(_key, jsonEncode(state.toList()));
  }

  void clear() {
    state = const {};
    ref.read(sharedPreferencesProvider).remove(_key);
  }
}

final favoriteTeachersProvider = NotifierProvider<FavoriteTeachers, Set<String>>(FavoriteTeachers.new);

/// Demo mode: three sample teachers (one available, one in a lesson, one
/// away), and nobody waiting.
mixin DemoTeachers implements TeacherDirectoryApi {
  @override
  Stream<List<TeacherEntry>> teachers(Gender gender) => Stream.value(
    gender == Gender.female
        ? const [
            TeacherEntry(uid: 'demo-teacher', name: 'Aisha Rahman', avatar: 'ft2', state: TeacherState.available),
            TeacherEntry(uid: 'demo-teacher-2', name: 'Khadijah Noor', avatar: 'ft1', state: TeacherState.busy),
            TeacherEntry(uid: 'demo-teacher-3', name: 'Maryam Saleh', state: TeacherState.away),
          ]
        : const [
            TeacherEntry(uid: 'demo-teacher', name: 'Yusuf Ali', avatar: 'mt2', state: TeacherState.available),
            TeacherEntry(uid: 'demo-teacher-2', name: 'Ibrahim Khan', avatar: 'mt1', state: TeacherState.busy),
            TeacherEntry(uid: 'demo-teacher-3', name: 'Hamza Omar', state: TeacherState.away),
          ],
  );

  @override
  Future<void> setWaiting({required Gender gender, DateTime? until}) async {}

  @override
  Stream<int> waitingStudents(Gender gender) => Stream.value(0);
}
