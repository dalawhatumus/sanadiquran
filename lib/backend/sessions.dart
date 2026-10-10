import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings.dart';
import 'backend.dart';

/// A portion of the Quran: ayahs [from]–[to] of surah [sura].
class Portion {
  const Portion(this.sura, this.from, this.to);

  final int sura;
  final int from;
  final int to;

  Map<String, Object> toMap() => {'sura': sura, 'from': from, 'to': to};

  static Portion? fromMap(Object? m) {
    if (m is! Map) return null;
    final sura = (m['sura'] as num?)?.toInt();
    final from = (m['from'] as num?)?.toInt();
    final to = (m['to'] as num?)?.toInt();
    if (sura == null || from == null || to == null) return null;
    return Portion(sura, from, to);
  }

  @override
  bool operator ==(Object other) => other is Portion && other.sura == sura && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(sura, from, to);
}

/// The teacher's optional notes on a lesson. Every part is optional.
class LessonNotes {
  const LessonNotes({this.recited, this.grade, this.practise = const [], this.next, this.note = ''});

  final Portion? recited;

  /// 0 needs practice, 1 good, 2 excellent.
  final int? grade;

  /// Ayah numbers (in [recited]'s surah) to practise.
  final List<int> practise;
  final Portion? next;
  final String note;

  bool get isEmpty => recited == null && grade == null && practise.isEmpty && next == null && note.trim().isEmpty;

  Map<String, Object?> toMap() => {
    'recited': recited?.toMap(),
    'grade': grade,
    'practise': practise,
    'next': next?.toMap(),
    'note': note.trim(),
  };

  static LessonNotes? fromMap(Object? m) {
    if (m is! Map) return null;
    return LessonNotes(
      recited: Portion.fromMap(m['recited']),
      grade: (m['grade'] as num?)?.toInt(),
      practise: [for (final a in (m['practise'] as List?) ?? const []) (a as num).toInt()],
      next: Portion.fromMap(m['next']),
      note: (m['note'] as String?) ?? '',
    );
  }
}

/// One lesson (a call that connected), kept for both people's history.
class Lesson {
  const Lesson({
    required this.id,
    required this.studentId,
    required this.teacherId,
    required this.studentName,
    required this.teacherName,
    this.studentAvatar,
    this.teacherAvatar,
    required this.at,
    this.durationSec = 0,
    this.notes,
    this.rating,
  });

  final String id;
  final String studentId;
  final String teacherId;
  final String studentName;
  final String teacherName;
  final String? studentAvatar;
  final String? teacherAvatar;
  final DateTime at;
  final int durationSec;
  final LessonNotes? notes;

  /// The student's optional rating: 0 not good, 1 OK, 2 good.
  final int? rating;

  int get minutes => (durationSec / 60).ceil();
}

/// Lesson history: saved when a call ends, notes from the teacher (any time
/// later too), and the student's rating.
abstract interface class LessonApi {
  /// This user's lessons (as student or teacher), newest first.
  Stream<List<Lesson>> lessons();

  /// Saves a finished call as a lesson (does nothing if already saved).
  Future<void> recordLesson({
    required String callId,
    required String studentId,
    required String teacherId,
    required String studentName,
    required String teacherName,
    String? studentAvatar,
    String? teacherAvatar,
    required Gender gender,
    required DateTime startedAt,
    required int durationSec,
  });

  /// The teacher's notes (replacing any earlier ones).
  Future<void> saveNotes(String lessonId, LessonNotes notes);

  /// The student's rating.
  Future<void> rateLesson(String lessonId, int rating);
}

final lessonsProvider = StreamProvider<List<Lesson>>((ref) => ref.watch(backendProvider).lessons());

/// A lesson by id, from the loaded history.
final lessonProvider = Provider.family<Lesson?, String>(
  (ref, id) => (ref.watch(lessonsProvider).value ?? const <Lesson>[]).where((l) => l.id == id).firstOrNull,
);

/// The student's next portion: from the newest lesson whose notes set one.
final nextPortionProvider = Provider<Portion?>((ref) {
  for (final l in ref.watch(lessonsProvider).value ?? const <Lesson>[]) {
    final next = l.notes?.next;
    if (next != null) return next;
  }
  return null;
});

/// Demo mode: two sample lessons (the newest with notes), so the progress
/// screens can be tried without a server; new lessons are kept in memory.
mixin DemoLessons implements LessonApi {
  final _changes = StreamController<void>.broadcast();
  late final _lessons = <Lesson>[
    Lesson(
      id: 'demo-lesson-2',
      studentId: 'demo',
      teacherId: 'demo-teacher',
      studentName: 'Fatima',
      teacherName: 'Aisha Rahman',
      teacherAvatar: 'ft2',
      at: DateTime.now().subtract(const Duration(hours: 3)),
      durationSec: 18 * 60,
      notes: const LessonNotes(
        recited: Portion(67, 1, 10),
        grade: 1,
        practise: [3, 7],
        next: Portion(67, 11, 20),
        note: 'Beautiful recitation, ma sha Allah. Take care with the madd in ayah 3, and revise ayah 7 twice a day.',
      ),
    ),
    Lesson(
      id: 'demo-lesson-1',
      studentId: 'demo',
      teacherId: 'demo-teacher',
      studentName: 'Fatima',
      teacherName: 'Aisha Rahman',
      teacherAvatar: 'ft2',
      at: DateTime.now().subtract(const Duration(days: 3)),
      durationSec: 15 * 60,
      notes: const LessonNotes(recited: Portion(112, 1, 4), grade: 2),
    ),
  ];

  @override
  Stream<List<Lesson>> lessons() async* {
    yield List.of(_lessons);
    await for (final _ in _changes.stream) {
      yield List.of(_lessons);
    }
  }

  @override
  Future<void> recordLesson({
    required String callId,
    required String studentId,
    required String teacherId,
    required String studentName,
    required String teacherName,
    String? studentAvatar,
    String? teacherAvatar,
    required Gender gender,
    required DateTime startedAt,
    required int durationSec,
  }) async {
    if (_lessons.any((l) => l.id == callId)) return;
    _lessons.insert(
      0,
      Lesson(
        id: callId,
        studentId: studentId,
        teacherId: teacherId,
        studentName: studentName,
        teacherName: teacherName,
        studentAvatar: studentAvatar,
        teacherAvatar: teacherAvatar,
        at: startedAt,
        durationSec: durationSec,
      ),
    );
    _changes.add(null);
  }

  Lesson _with(Lesson l, {LessonNotes? notes, int? rating}) => Lesson(
    id: l.id,
    studentId: l.studentId,
    teacherId: l.teacherId,
    studentName: l.studentName,
    teacherName: l.teacherName,
    studentAvatar: l.studentAvatar,
    teacherAvatar: l.teacherAvatar,
    at: l.at,
    durationSec: l.durationSec,
    notes: notes ?? l.notes,
    rating: rating ?? l.rating,
  );

  @override
  Future<void> saveNotes(String lessonId, LessonNotes notes) async {
    final i = _lessons.indexWhere((l) => l.id == lessonId);
    if (i < 0) return;
    _lessons[i] = _with(_lessons[i], notes: notes);
    _changes.add(null);
  }

  @override
  Future<void> rateLesson(String lessonId, int rating) async {
    final i = _lessons.indexWhere((l) => l.id == lessonId);
    if (i < 0) return;
    _lessons[i] = _with(_lessons[i], rating: rating);
    _changes.add(null);
  }
}
