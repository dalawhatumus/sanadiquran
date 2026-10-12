import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../backend/teachers.dart';
import '../../core/connectivity.dart';
import '../../core/router.dart';
import '../../core/settings.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';
import '../messages/messages_screen.dart';

/// Calls [teacher] (or, if they can't answer, another free teacher), after
/// checking the internet.
Future<void> callTeacher(BuildContext context, WidgetRef ref, TeacherEntry teacher) async {
  if (await ref.read(offlineProvider.notifier).check() && context.mounted) {
    unawaited(context.push('${Routes.connecting}?teacher=${teacher.uid}'));
  }
}

/// The teachers a student can call: search, and All / Available now /
/// Favourites.
class TeachersScreen extends ConsumerStatefulWidget {
  const TeachersScreen({super.key});

  @override
  ConsumerState<TeachersScreen> createState() => _TeachersScreenState();
}

enum _Tab { all, available, favorites }

class _TeachersScreenState extends ConsumerState<TeachersScreen> {
  final _search = TextEditingController();
  _Tab _tab = _Tab.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final gender = ref.watch(settingsProvider.select((x) => x.gender)) ?? Gender.female;
    final teachers = ref.watch(teachersProvider(gender));
    final favorites = ref.watch(favoriteTeachersProvider);
    final query = _search.text.trim().toLowerCase();
    final all = teachers.value ?? const <TeacherEntry>[];
    final list = [
      for (final x in all)
        if ((query.isEmpty || x.name.toLowerCase().contains(query)) &&
            switch (_tab) {
              _Tab.all => true,
              _Tab.available => x.state == TeacherState.available,
              _Tab.favorites => favorites.contains(x.uid),
            })
          x,
    ];
    final empty = switch (_tab) {
      _ when all.isEmpty => s.noTeachersYet,
      _Tab.favorites when query.isEmpty => s.noFavorites,
      _Tab.available when query.isEmpty => s.noTeachersNow,
      _ => s.noOneYet,
    };
    return StepScaffold(
      showBack: true,
      content: [
        WordSafeText(s.teachersTitle, style: tt.headlineMedium),
        const SizedBox(height: 12),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: t.text),
          decoration: InputDecoration(
            hintText: s.searchName,
            prefixIcon: Icon(Icons.search_rounded, color: t.muted, size: 28),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (tab, label) in [
              (_Tab.all, s.tabAll),
              (_Tab.available, s.tabAvailable),
              (_Tab.favorites, s.tabFavorites),
            ])
              PickChip(label: label, selected: _tab == tab, onTap: () => setState(() => _tab = tab)),
          ],
        ),
        const SizedBox(height: 16),
        if (teachers.isLoading && all.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (list.isEmpty)
          SCard(
            child: Row(
              children: [
                Icon(Icons.info_rounded, color: t.muted, size: 30),
                const SizedBox(width: 12),
                Expanded(child: Text(empty, style: tt.bodyLarge)),
              ],
            ),
          )
        else ...[
          for (final x in list) ...[TeacherTile(teacher: x), const SizedBox(height: 12)],
          Text(s.callTeacherNote, style: tt.bodySmall, textAlign: TextAlign.center),
        ],
      ],
    );
  }
}

/// A coloured "Available / In a lesson / Away" label.
class TeacherStatePill extends StatelessWidget {
  const TeacherStatePill({super.key, required this.state});

  final TeacherState state;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    // Gold is only for the icon: as text it is too faint on white.
    final (label, color, icon, iconColor) = switch (state) {
      TeacherState.available => (s.availableL, t.primary, Icons.check_circle_rounded, t.primary),
      TeacherState.busy => (s.inLesson, t.heading, Icons.schedule_rounded, t.gold),
      TeacherState.away => (s.away, t.muted, Icons.remove_circle_outline_rounded, t.muted),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 4),
        Flexible(
          child: WordSafeText(
            label,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color),
          ),
        ),
      ],
    );
  }
}

/// One teacher in the list: picture, name, where they are, a heart, and
/// Call when they are free.
class TeacherTile extends ConsumerWidget {
  const TeacherTile({super.key, required this.teacher});

  final TeacherEntry teacher;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final x = teacher;
    final fav = ref.watch(favoriteTeachersProvider.select((f) => f.contains(x.uid)));
    final name = x.name.isEmpty ? '—' : x.name;
    return SCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Avatar(initialOf(name), size: 60, image: x.avatar, ring: x.state == TeacherState.available),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FullName(name, style: tt.titleLarge!),
                    const SizedBox(height: 2),
                    TeacherStatePill(state: x.state),
                  ],
                ),
              ),
              IconButton(
                tooltip: fav ? s.unfavorite : s.favorite,
                onPressed: () => ref.read(favoriteTeachersProvider.notifier).toggle(x.uid),
                style: IconButton.styleFrom(minimumSize: const Size(kMinTap, kMinTap)),
                icon: Icon(
                  fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: fav ? t.warn : t.muted,
                  size: 32,
                ),
              ),
            ],
          ),
          if (x.state == TeacherState.available) ...[
            const SizedBox(height: 12),
            BigButton(
              label: s.call,
              icon: Icons.call_rounded,
              compact: true,
              onPressed: () => callTeacher(context, ref, x),
            ),
          ],
        ],
      ),
    );
  }
}
