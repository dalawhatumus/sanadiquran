import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../backend/backend.dart';
import '../../backend/chat.dart';
import '../../core/settings.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';

/// Admins open a chat between a student and an approved teacher of the same
/// gender. (From the calls update on, a first lesson does this by itself.)
class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  late final Future<(List<PersonSummary>, List<PersonSummary>)> _people = () async {
    final b = ref.read(backendProvider);
    return (await b.students(), await b.approvedTeachers());
  }();
  PersonSummary? _student;
  PersonSummary? _teacher;
  bool _busy = false;

  Future<void> _connect() async {
    final s = S.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(backendProvider).connect(_student!, _teacher!);
      if (mounted) {
        toast(context, s.connectedDone);
        setState(() {
          _student = null;
          _teacher = null;
        });
      }
    } catch (_) {
      if (mounted) toast(context, s.decisionFailed);
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final tt = Theme.of(context).textTheme;
    return StepScaffold(
      showBack: true,
      content: [
        WordSafeText(s.connectTitle, style: tt.headlineMedium),
        const SizedBox(height: 6),
        Text(s.connectHelp, style: tt.bodyMedium),
        const SizedBox(height: 16),
        FutureBuilder(
          future: _people,
          builder: (context, snap) {
            if (snap.hasError) return WarnBanner(icon: Icons.error_rounded, text: s.decisionFailed);
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final (students, teachers) = snap.data!;
            final sameGender = [
              for (final t in teachers)
                if (_student != null && t.gender == _student!.gender) t,
            ];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WordSafeText(s.studentL, style: tt.titleLarge),
                const SizedBox(height: 8),
                if (students.isEmpty) Text(s.noOneYet, style: tt.bodyMedium),
                for (final p in students) ...[
                  _PersonChoice(
                    p: p,
                    selected: _student?.uid == p.uid,
                    onTap: () => setState(() {
                      _student = p;
                      if (_teacher?.gender != p.gender) _teacher = null;
                    }),
                  ),
                  const SizedBox(height: 8),
                ],
                if (_student != null) ...[
                  const SizedBox(height: 12),
                  WordSafeText(s.teacherL, style: tt.titleLarge),
                  const SizedBox(height: 8),
                  if (sameGender.isEmpty) Text(s.noOneYet, style: tt.bodyMedium),
                  for (final p in sameGender) ...[
                    _PersonChoice(p: p, selected: _teacher?.uid == p.uid, onTap: () => setState(() => _teacher = p)),
                    const SizedBox(height: 8),
                  ],
                ],
              ],
            );
          },
        ),
      ],
      bottom: [
        BigButton(
          label: s.connect,
          icon: Icons.link_rounded,
          busy: _busy,
          onPressed: _student != null && _teacher != null && !_busy ? _connect : null,
        ),
      ],
    );
  }
}

class _PersonChoice extends StatelessWidget {
  const _PersonChoice({required this.p, required this.selected, required this.onTap});

  final PersonSummary p;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ChoiceCard(
      title: p.name.isEmpty ? '—' : p.name,
      subtitle: p.gender == null ? null : (p.gender == Gender.female ? s.sister : s.brother),
      selected: selected,
      onTap: onTap,
    );
  }
}

/// Reports sent by users, newest first.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final reports = ref.watch(reportsProvider);
    final list = reports.value ?? const <UserReport>[];
    const reasons = {'words': 0, 'respect': 1, 'personal': 2, 'other': 3};
    return StepScaffold(
      showBack: true,
      content: [
        WordSafeText(s.reportsTitle, style: tt.headlineMedium),
        const SizedBox(height: 16),
        if (reports.hasError)
          WarnBanner(icon: Icons.error_rounded, text: s.decisionFailed)
        else if (reports.isLoading && list.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (list.isEmpty)
          SCard(
            child: Row(
              children: [
                Icon(Icons.inbox_rounded, color: t.muted, size: 32),
                const SizedBox(width: 12),
                Expanded(child: Text(s.noReports, style: tt.bodyLarge)),
              ],
            ),
          )
        else
          for (final r in list) ...[
            SCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WordSafeText(s.reportedBy(r.reporterName, r.reportedName), style: tt.titleMedium),
                  const SizedBox(height: 4),
                  Text(s.reportReasons[reasons[r.reason] ?? 3], style: tt.bodyMedium!.copyWith(color: t.warn)),
                  if (r.details.isNotEmpty) ...[const SizedBox(height: 6), Text(r.details, style: tt.bodyMedium)],
                  if (r.at != null) ...[
                    const SizedBox(height: 6),
                    Text(s.n(MaterialLocalizations.of(context).formatMediumDate(r.at!)), style: tt.bodySmall),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}
