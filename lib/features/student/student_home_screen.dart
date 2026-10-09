import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../backend/backend.dart';
import '../../backend/chat.dart';
import '../../core/connectivity.dart';
import '../../core/router.dart';
import '../../core/settings.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/avatars.dart';
import '../../widgets/ui.dart';
import '../messages/messages_screen.dart';

/// 17 · Student home: one giant "Recite now" action.
class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final settings = ref.watch(settingsProvider);
    final firstTime = settings.sessions == 0;
    final offline = ref.watch(offlineProvider);

    // Calling needs internet; everything else on this screen works offline.
    Future<void> startCall() async {
      if (await ref.read(offlineProvider.notifier).check() && context.mounted) {
        context.push(Routes.connecting);
      }
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const HomeHeader(),
            const SizedBox(height: 16),
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
            _ReciteButton(onTap: startCall, offline: offline),
            const SizedBox(height: 16),
            if (!offline)
              Consumer(
                builder: (context, ref, _) {
                  final k = ref.watch(availableTeachersProvider(settings.gender)).value;
                  return k == null ? const SizedBox(height: 27) : StatusLine(text: s.teachersAvailable(k), on: k > 0);
                },
              ),
            const SizedBox(height: 16),
            if (firstTime) ...[
              _MyTeacherCard(startCall: startCall, after: true),
              SCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        TintBox(child: SIcon(SIcons.rehal, color: t.primary)),
                        const SizedBox(width: 12),
                        Expanded(child: WordSafeText(s.welcomeTitle, style: tt.titleLarge)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(s.welcomeBody, style: tt.bodyMedium),
                  ],
                ),
              ),
            ] else ...[
              SCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        TintBox(child: Icon(Icons.bookmark_rounded, color: t.primary)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.nextPortionL, style: tt.bodyMedium!.copyWith(color: t.muted)),
                              WordSafeText(
                                settings.sessions > 1 ? s.nextPortion : s.firstPortion,
                                style: tt.titleLarge,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    BigButton(
                      label: s.openInQuran,
                      iconWidget: const SIcon(SIcons.rehal),
                      kind: ButtonKind.outline,
                      onPressed: () => context.push(Routes.mushafAt(sura: 67, ayah: settings.sessions > 1 ? 11 : 1)),
                    ),
                  ],
                ),
              ),
              _MyTeacherCard(startCall: startCall),
            ],
            const SizedBox(height: 14),
            SCard(
              onTap: () => context.push(Routes.progress),
              child: Row(
                children: [
                  TintBox(child: Icon(Icons.insights_rounded, color: t.primary)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        WordSafeText(s.myProgress, style: tt.titleMedium!.copyWith(color: t.heading)),
                        if (!firstTime) Text(s.progressSum, style: tt.bodySmall),
                      ],
                    ),
                  ),
                  Icon(Arrows.next, color: t.primary, size: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReciteButton extends StatelessWidget {
  const _ReciteButton({required this.onTap, this.offline = false});

  final VoidCallback onTap;

  /// Greyed out with "Needs internet" (tapping checks again).
  final bool offline;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    return Semantics(
      button: true,
      label: '${s.recite}. ${offline ? s.needsNet : s.reciteSub}',
      excludeSemantics: true,
      child: Material(
        color: offline ? t.disabledBg : t.primary,
        borderRadius: BorderRadius.circular(32),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
            child: Column(
              children: [
                Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: t.micBg,
                    border: Border.all(
                      color: (offline ? t.disabledInk : t.onPrimary).withValues(alpha: 0.18),
                      width: 14,
                    ),
                  ),
                  child: Icon(Icons.mic_rounded, size: 56, color: offline ? t.disabledInk : t.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  s.recite,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: offline ? t.disabledInk : t.onPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  offline ? s.needsNet : s.reciteSub,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: offline ? t.disabledInk : t.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "My teacher": once connected (online), the real teacher, with their
/// availability and a Message button that opens the chat. In demo mode, a
/// sample teacher.
class _MyTeacherCard extends ConsumerWidget {
  const _MyTeacherCard({required this.startCall, this.after = false});

  final VoidCallback startCall;

  /// Spacing goes after the card (first visit) rather than before it.
  final bool after;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final live = ref.watch(backendProvider).live;
    final firstVisit = ref.watch(settingsProvider.select((x) => x.sessions == 0));

    final Conversation? chat;
    if (live) {
      chat = (ref.watch(conversationsProvider).value ?? const <Conversation>[])
          .where((c) => c.otherRole == UserRole.teacher)
          .firstOrNull;
      if (chat == null) return const SizedBox.shrink();
    } else {
      // The sample teacher only shows after the first (practice) session.
      if (firstVisit && after) return const SizedBox.shrink();
      chat = null;
    }
    final available = chat == null ? true : (ref.watch(teacherAvailableProvider(chat.otherUid)).value ?? false);
    final name = chat?.otherName ?? s.teacherName;

    final card = SCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.myTeacher, style: tt.bodyMedium!.copyWith(color: t.muted)),
          const SizedBox(height: 10),
          Row(
            children: [
              chat == null
                  ? Avatar(s.teacherInitials, size: 56, image: sampleTeacherAvatar(s.female))
                  : Avatar(initialOf(chat.otherName), size: 56, image: chat.otherAvatar),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FullName(name, style: tt.titleLarge!),
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: available ? t.primary : Colors.transparent,
                            border: Border.all(color: available ? t.primary : t.muted, width: 2),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: WordSafeText(
                            available ? s.availableL : s.away,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: available ? t.primary : t.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (available) ...[
                Expanded(
                  child: BigButton(
                    label: s.call,
                    icon: Icons.call_rounded,
                    compact: true,
                    onPressed: chat == null
                        ? startCall
                        : () async {
                            if (await ref.read(offlineProvider.notifier).check() && context.mounted) {
                              unawaited(context.push('${Routes.connecting}?teacher=${chat!.otherUid}'));
                            }
                          },
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: BigButton(
                  label: s.message,
                  icon: Icons.chat_bubble_rounded,
                  kind: ButtonKind.outline,
                  compact: true,
                  onPressed: () =>
                      chat == null ? context.go(Routes.studentMessages) : context.push(Routes.chat(chat.id)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return Padding(padding: after ? const EdgeInsets.only(bottom: 14) : const EdgeInsets.only(top: 14), child: card);
  }
}
