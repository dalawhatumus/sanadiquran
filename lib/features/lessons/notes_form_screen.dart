import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../backend/backend.dart';
import '../../backend/sessions.dart';
import '../../core/theme.dart';
import '../../core/strings.dart';
import '../../widgets/ui.dart';
import '../quran/quran_data.dart';
import 'lessons_ui.dart';

/// 34 · Notes on a lesson. Every part is optional; Save works as soon as
/// anything is filled in. Can be opened right after the call or later from
/// the student's page.
class NotesFormScreen extends ConsumerStatefulWidget {
  const NotesFormScreen({super.key, this.lessonId});

  final String? lessonId;

  @override
  ConsumerState<NotesFormScreen> createState() => _NotesFormScreenState();
}

class _NotesFormScreenState extends ConsumerState<NotesFormScreen> {
  final _note = TextEditingController();
  bool _ready = false;
  Portion? _recited;
  int? _grade;
  final _practise = <int>{};
  Portion? _next;
  bool _nextTouched = false;
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Lesson? get _lesson {
    final all = ref.read(lessonsProvider).value ?? const <Lesson>[];
    final id = widget.lessonId;
    return id == null ? all.firstOrNull : all.where((l) => l.id == id).firstOrNull;
  }

  /// Starts from saved notes, or from where this student was asked to go
  /// next by this teacher.
  void _init(QuranData q) {
    if (_ready) return;
    _ready = true;
    final l = _lesson;
    final saved = l?.notes;
    if (saved != null && !saved.isEmpty) {
      _recited = saved.recited;
      _grade = saved.grade;
      _practise.addAll(saved.practise);
      _next = saved.next;
      _nextTouched = saved.next != null;
      _note.text = saved.note;
      return;
    }
    final all = ref.read(lessonsProvider).value ?? const <Lesson>[];
    final before = all.where((x) => x.studentId == l?.studentId && x.id != l?.id && x.notes?.next != null).firstOrNull;
    _recited = before?.notes?.next;
    _next = _suggestNext(q, _recited);
  }

  /// The ten ayahs after [p] (into the next surah at the end of one).
  Portion? _suggestNext(QuranData q, Portion? p) {
    if (p == null) return null;
    final count = q.sura(p.sura).count;
    if (p.to < count) return Portion(p.sura, p.to + 1, (p.to + 10).clamp(1, count));
    if (p.sura >= 114) return null;
    final n = q.sura(p.sura + 1).count;
    return Portion(p.sura + 1, 1, n < 10 ? n : 10);
  }

  LessonNotes get _notes => LessonNotes(
    recited: _recited,
    grade: _grade,
    practise: _practise.toList()..sort(),
    next: _next,
    note: _note.text,
  );

  Future<void> _save() async {
    final s = S.of(context);
    final l = _lesson;
    if (l == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(backendProvider).saveNotes(l.id, _notes);
      if (!mounted) return;
      toast(context, s.notesSaved);
      context.pop();
    } catch (_) {
      if (mounted) toast(context, s.notesNotSaved);
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _choose(QuranData q, {required bool next}) async {
    final sura = await pickSurah(context, q);
    if (sura == null || !mounted) return;
    final count = q.sura(sura).count;
    final p = Portion(sura, 1, count < 10 ? count : 10);
    setState(() {
      if (next) {
        _next = p;
        _nextTouched = true;
      } else {
        _recited = p;
        _practise.clear();
        if (!_nextTouched) _next = _suggestNext(q, p);
      }
    });
  }

  void _setRange(QuranData q, Portion p, {required bool next}) => setState(() {
    if (next) {
      _next = p;
      _nextTouched = true;
    } else {
      _recited = p;
      _practise.removeWhere((a) => a < p.from || a > p.to);
      if (!_nextTouched) _next = _suggestNext(q, p);
    }
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final q = ref.watch(quranProvider).value;
    ref.watch(lessonsProvider);
    final l = _lesson;
    if (q == null || l == null) {
      return const StepScaffold(showBack: true, center: true, content: [Center(child: CircularProgressIndicator())]);
    }
    _init(q);
    final recited = _recited;
    final hasAny = !_notes.isEmpty;

    return StepScaffold(
      showBack: true,
      content: [
        WordSafeText(s.notesForName(l.studentName), style: tt.headlineSmall),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_rounded, color: t.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(s.allOptional, style: tt.bodyMedium)),
          ],
        ),
        const SizedBox(height: 18),
        WordSafeText(s.portionL, style: tt.titleMedium),
        const SizedBox(height: 8),
        _PortionEditor(
          q: q,
          portion: recited,
          onPick: () => _choose(q, next: false),
          onChange: (p) => _setRange(q, p, next: false),
        ),
        const SizedBox(height: 18),
        WordSafeText(s.gradeL, style: tt.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 2; i >= 0; i--)
              PickChip(
                label: s.grades[i],
                selected: _grade == i,
                onTap: () => setState(() => _grade = _grade == i ? null : i),
              ),
          ],
        ),
        if (recited != null) ...[
          const SizedBox(height: 18),
          WordSafeText(s.mistakesL, style: tt.titleMedium),
          const SizedBox(height: 8),
          for (var a = recited.from; a <= recited.to; a++)
            if (q.ayah(recited.sura, a) case final ayah?)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SCard(
                  color: _practise.contains(a) ? t.tint : t.surface,
                  border: _practise.contains(a) ? t.primary : null,
                  onTap: () => setState(() => _practise.contains(a) ? _practise.remove(a) : _practise.add(a)),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _practise.contains(a) ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                        color: _practise.contains(a) ? t.primary : t.muted,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          ayah.text,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(fontFamily: SanadiFonts.quran, fontSize: 22, color: t.text, height: 2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
        const SizedBox(height: 10),
        WordSafeText(s.nextL, style: tt.titleMedium),
        const SizedBox(height: 8),
        _PortionEditor(
          q: q,
          portion: _next,
          onPick: () => _choose(q, next: true),
          onChange: (p) => _setRange(q, p, next: true),
        ),
        const SizedBox(height: 18),
        WordSafeText(s.noteToName(l.studentName), style: tt.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _note,
          minLines: 3,
          maxLines: 6,
          maxLength: 2000,
          onChanged: (_) => setState(() {}),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: t.text),
          decoration: InputDecoration(hintText: s.typeNote, counterText: ''),
        ),
      ],
      bottom: [
        BigButton(
          label: s.saveNotes,
          icon: Icons.check_rounded,
          busy: _saving,
          onPressed: hasAny && !_saving ? _save : null,
        ),
        BigButton(label: s.cancel, kind: ButtonKind.outline, onPressed: () => context.pop()),
      ],
    );
  }
}

/// A surah (tap to choose) and from / to ayah steppers.
class _PortionEditor extends StatelessWidget {
  const _PortionEditor({required this.q, required this.portion, required this.onPick, required this.onChange});

  final QuranData q;
  final Portion? portion;
  final VoidCallback onPick;
  final ValueChanged<Portion> onChange;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final p = portion;
    if (p == null) {
      return BigButton(
        label: s.chooseSurah,
        icon: Icons.menu_book_rounded,
        kind: ButtonKind.outline,
        onPressed: onPick,
      );
    }
    final count = q.sura(p.sura).count;
    return SCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: WordSafeText(
                  '${q.sura(p.sura).name(s.ar)} (${s.n(p.sura)})',
                  style: nameFont(context, tt.titleSmall!.copyWith(color: t.heading)),
                ),
              ),
              LinkButton(label: s.change, onPressed: onPick),
            ],
          ),
          const SizedBox(height: 10),
          _Stepper(
            label: s.fromAyah,
            value: p.from,
            min: 1,
            max: p.to,
            onChanged: (v) => onChange(Portion(p.sura, v, p.to)),
          ),
          const SizedBox(height: 12),
          _Stepper(
            label: s.toAyah,
            value: p.to,
            min: p.from,
            max: count,
            onChanged: (v) => onChange(Portion(p.sura, p.from, v)),
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    Widget btn(IconData icon, int delta, String tip) => IconButton.filledTonal(
      tooltip: tip,
      onPressed: (value + delta) < min || (value + delta) > max ? null : () => onChanged(value + delta),
      icon: Icon(icon, size: 28),
      style: IconButton.styleFrom(
        minimumSize: const Size(kMinTap, kMinTap),
        backgroundColor: t.tint,
        foregroundColor: t.primary,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Row(
          children: [
            btn(Icons.remove_rounded, -1, '$label −'),
            Expanded(
              child: Semantics(
                label: '$label ${s.n(value)}',
                excludeSemantics: true,
                child: Text(
                  s.n(value),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: t.heading),
                ),
              ),
            ),
            btn(Icons.add_rounded, 1, '$label +'),
          ],
        ),
      ],
    );
  }
}
