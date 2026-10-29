part of 'call_screens.dart';

/// 24 · Call ended (student), with an optional rating.
class StudentCallEndedScreen extends ConsumerStatefulWidget {
  const StudentCallEndedScreen({super.key, required this.seconds});

  final int seconds;

  @override
  ConsumerState<StudentCallEndedScreen> createState() => _StudentCallEndedScreenState();
}

class _StudentCallEndedScreenState extends ConsumerState<StudentCallEndedScreen> {
  int? _rating;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    const faces = [Icons.sentiment_dissatisfied_rounded, Icons.sentiment_neutral_rounded, Icons.check_circle_rounded];
    final minutes = (widget.seconds / 60).ceil().clamp(1, 999);
    final (name, _, _) = _other(s, ref.watch(callControllerProvider));
    return StepScaffold(
      center: true,
      content: [
        const Center(child: Illustration(size: 112, child: Icon(Icons.check_rounded))),
        const SizedBox(height: 18),
        WordSafeText(s.sEndTitle, style: tt.headlineMedium, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(s.sEndSubName(minutes, name), style: tt.bodyLarge, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: t.tint, borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, size: 20, color: t.primary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    s.savedToProgress,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.heading),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        SCard(
          child: Column(
            children: [
              Text(_rating == null ? s.rateQ : s.thanks, style: tt.titleSmall, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(
                      child: Semantics(
                        selected: _rating == i,
                        button: true,
                        child: Material(
                          color: _rating == i ? t.primary : t.bg,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              setState(() => _rating = i);
                              final id = ref.read(callControllerProvider).callId;
                              if (id != null) ref.read(backendProvider).rateLesson(id, i).catchError((_) {});
                            },
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 88),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(faces[i], size: 34, color: _rating == i ? t.onPrimary : t.primary),
                                  const SizedBox(height: 4),
                                  WordSafeText(
                                    s.faces[i],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: _rating == i ? t.onPrimary : t.text,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
      bottom: [
        BigButton(
          label: s.done,
          icon: Icons.check_rounded,
          onPressed: () {
            ref.read(callControllerProvider.notifier).reset();
            context.go(Routes.studentHome);
          },
        ),
        LinkButton(
          label: s.reportProblem,
          onPressed: () => contactSanadi(context, subject: 'Sanadi call problem'),
        ),
      ],
    );
  }
}

/// 34 · Call ended (teacher): Done, with optional notes.
class TeacherCallEndedScreen extends ConsumerWidget {
  const TeacherCallEndedScreen({super.key, required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final minutes = (seconds / 60).ceil().clamp(1, 999);
    final (name, _, _) = _other(s, ref.watch(callControllerProvider));
    return StepScaffold(
      center: true,
      content: [
        const Center(child: Illustration(size: 112, child: Icon(Icons.check_rounded))),
        const SizedBox(height: 18),
        WordSafeText(s.tEndTitle, style: tt.headlineMedium, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(s.tEndSubName(minutes, name), style: tt.bodyLarge, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: t.tint, borderRadius: BorderRadius.circular(20)),
            child: Text(
              s.tEndSaved,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.heading),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(s.jazakTeach, style: tt.bodyMedium, textAlign: TextAlign.center),
      ],
      bottom: [
        BigButton(
          label: s.done,
          icon: Icons.check_rounded,
          onPressed: () {
            ref.read(callControllerProvider.notifier).reset();
            context.go(Routes.teacherHome);
          },
        ),
        BigButton(
          label: s.addNotes,
          icon: Icons.edit_note_rounded,
          kind: ButtonKind.outline,
          onPressed: () {
            final id = ref.read(callControllerProvider).callId;
            context.push(id == null ? Routes.notesForm : Routes.notesFormFor(id));
          },
        ),
        LinkButton(
          label: s.reportProblem,
          onPressed: () => contactSanadi(context, subject: 'Sanadi call problem'),
        ),
      ],
    );
  }
}
