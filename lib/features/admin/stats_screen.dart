import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../backend/admin.dart';
import '../../backend/backend.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';

/// The admin's overview: counts of teachers, students, lessons and what is
/// waiting. Counted on opening and on "Refresh" (each count is one cheap
/// server read, so nothing is watched live).
class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  late Future<AdminStats> _stats = ref.read(backendProvider).stats();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final tt = Theme.of(context).textTheme;
    return StepScaffold(
      showBack: true,
      content: [
        WordSafeText(s.overviewTitle, style: tt.headlineMedium),
        const SizedBox(height: 16),
        FutureBuilder<AdminStats>(
          future: _stats,
          builder: (context, snap) {
            if (snap.hasError) return WarnBanner(icon: Icons.error_rounded, text: s.decisionFailed);
            final st = snap.data;
            if (st == null) return const Center(child: CircularProgressIndicator());
            return Column(
              children: [
                for (final (icon, label, value) in [
                  (Icons.person_rounded, s.statStudents, st.students),
                  (Icons.school_rounded, s.statTeachers, st.teachers),
                  (Icons.check_circle_rounded, s.statTeachersOn, st.teachersOn),
                  (Icons.how_to_reg_rounded, s.statPending, st.pendingApplications),
                  (Icons.flag_rounded, s.statReports, st.openReports),
                  (Icons.menu_book_rounded, s.statLessons, st.lessonsWeek),
                  (Icons.schedule_rounded, s.statMinutes, st.minutesWeek),
                ]) ...[
                  _StatRow(icon: icon, label: label, value: value == null ? '—' : s.n(value)),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
        ),
      ],
      bottom: [
        BigButton(
          label: s.refresh,
          icon: Icons.refresh_rounded,
          kind: ButtonKind.outline,
          onPressed: () {
            final next = ref.read(backendProvider).stats();
            setState(() {
              _stats = next;
            });
          },
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    return SCard(
      child: Row(
        children: [
          TintBox(child: Icon(icon, color: t.primary)),
          const SizedBox(width: 12),
          Expanded(child: WordSafeText(label, style: tt.bodyLarge)),
          const SizedBox(width: 8),
          Text(value, style: tt.headlineSmall!.copyWith(color: t.heading)),
        ],
      ),
    );
  }
}
