import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../backend/chat.dart';
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

/// The student's Teachers tab: every teacher of their gender with a search,
/// All / Available now / Favourites, a Call button for those who are free,
/// Message for the ones they already talk to, and Messages at the top.
class TeachersScreen extends ConsumerStatefulWidget {
  const TeachersScreen({super.key});

  @override
  ConsumerState<TeachersScreen> createState() => _TeachersScreenState();
}

enum _Tab { all, available, favorites }

class _TeachersScreenState extends ConsumerState<TeachersScreen> with SingleTickerProviderStateMixin {
  final _search = TextEditingController();
  late final _tabs = TabController(length: _Tab.values.length, vsync: this)
    ..addListener(() {
      if (mounted) setState(() {});
    });

  @override
  void dispose() {
    _search.dispose();
    _tabs.dispose();
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
    final offline = ref.watch(offlineProvider);
    final tab = _Tab.values[_tabs.index];
    final query = _search.text.trim().toLowerCase();
    final all = teachers.value ?? const <TeacherEntry>[];
    final list = [
      for (final x in all)
        if ((query.isEmpty || x.name.toLowerCase().contains(query)) &&
            switch (tab) {
              _Tab.all => true,
              _Tab.available => x.state == TeacherState.available,
              _Tab.favorites => favorites.contains(x.uid),
            })
          x,
    ];
    final empty = switch (tab) {
      _ when all.isEmpty => s.noTeachersYet,
      _Tab.favorites when query.isEmpty => s.noFavorites,
      _Tab.available when query.isEmpty => s.noTeachersNow,
      _ => s.noOneYet,
    };

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: WordSafeText(s.teachersTitle, maxLines: 1, style: tt.headlineMedium),
                      ),
                    ),
                  ),
                  // Room for the unread badge, which sits over the button's edge.
                  const SizedBox(width: 12),
                  const MessagesButton(),
                  const SizedBox(width: 8),
                  const SettingsChip(compact: true),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: t.text),
                decoration: InputDecoration(
                  hintText: s.searchName,
                  prefixIcon: Icon(Icons.search_rounded, color: t.muted, size: 28),
                ),
              ),
            ),
            MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.3,
              child: TabBar(
                controller: _tabs,
                labelColor: t.primary,
                unselectedLabelColor: t.muted,
                indicatorColor: t.primary,
                indicatorWeight: 3,
                labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.15),
                tabs: [
                  // Two lines rather than tiny text ("Available / now").
                  for (final label in [s.tabAll, s.tabAvailable, s.tabFavorites])
                    Tab(
                      height: kMinTap + 8,
                      child: WordSafeText(label, maxLines: 2, textAlign: TextAlign.center),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  if (offline) ...[
                    WarnBanner(
                      icon: Icons.wifi_off_rounded,
                      title: s.needsInternetTitle,
                      text: s.needsInternetBody,
                      action: BigButton(
                        label: s.tryAgain,
                        icon: Icons.refresh_rounded,
                        kind: ButtonKind.outline,
                        onPressed: () => ref.read(offlineProvider.notifier).check(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
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
                    for (final x in list) ...[TeacherTile(teacher: x), const SizedBox(height: 14)],
                    Text(s.callTeacherNote, style: tt.bodySmall, textAlign: TextAlign.center),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The chat-bubble button at the top of the Teachers tab, with the number
/// of unread messages. Opens Messages.
class MessagesButton extends ConsumerWidget {
  const MessagesButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.t;
    final unread = ref.watch(unreadTotalProvider);
    return Semantics(
      button: true,
      label: unread > 0 ? '${s.navMessages}, ${s.n(unread)}' : s.navMessages,
      excludeSemantics: true,
      child: Material(
        key: const ValueKey('messages-button'),
        color: t.tint,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => context.push(Routes.messages),
          child: SizedBox(
            width: kMinTap,
            height: kMinTap,
            child: Center(
              child: Badge(
                isLabelVisible: unread > 0,
                label: Text(
                  s.n(unread > 99 ? 99 : unread),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                backgroundColor: t.warn,
                textColor: t.onWarn,
                child: Icon(Icons.chat_bubble_rounded, color: t.primary, size: 28),
              ),
            ),
          ),
        ),
      ),
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

/// One teacher in the list: picture, name, where they are, a heart, Call
/// when they are free, and Message when the student already talks to them.
/// Favourites stand out with a gold edge.
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
    final chat = (ref.watch(conversationsProvider).value ?? const <Conversation>[])
        .where((c) => c.otherUid == x.uid)
        .firstOrNull;
    final name = x.name.isEmpty ? '—' : x.name;
    final free = x.state == TeacherState.available;
    return SCard(
      color: fav ? Color.alphaBlend(t.gold.withValues(alpha: 0.12), t.surface) : null,
      border: fav ? t.gold : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Avatar(initialOf(name), size: 72, image: x.avatar, ring: free),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    FullName(name, style: tt.titleLarge!),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: t.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: free ? t.primary : t.line, width: 1.5),
                      ),
                      child: TeacherStatePill(state: x.state),
                    ),
                  ],
                ),
              ),
              Material(
                color: fav ? t.warn.withValues(alpha: 0.12) : t.tint,
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: fav ? s.unfavorite : s.favorite,
                  onPressed: () => ref.read(favoriteTeachersProvider.notifier).toggle(x.uid),
                  style: IconButton.styleFrom(minimumSize: const Size(kMinTap, kMinTap)),
                  icon: Icon(
                    fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: fav ? t.warn : t.muted,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
          if (free || chat != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                if (free)
                  Expanded(
                    child: BigButton(
                      label: s.call,
                      icon: Icons.call_rounded,
                      compact: true,
                      onPressed: () => callTeacher(context, ref, x),
                    ),
                  ),
                if (free && chat != null) const SizedBox(width: 10),
                if (chat != null)
                  Expanded(
                    child: BigButton(
                      label: s.message,
                      icon: Icons.chat_bubble_rounded,
                      kind: ButtonKind.outline,
                      compact: true,
                      onPressed: () => context.push(Routes.chat(chat.id)),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
