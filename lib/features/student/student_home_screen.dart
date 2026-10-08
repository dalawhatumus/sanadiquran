import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/connectivity.dart';
import '../../core/router.dart';
import '../../core/settings.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/avatars.dart';
import '../../widgets/ui.dart';

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
            if (!offline) StatusLine(text: s.teachersAvailable(3)),
            const SizedBox(height: 16),
            if (firstTime)
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
              )
            else ...[
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
              const SizedBox(height: 14),
              SCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(s.myTeacher, style: tt.bodyMedium!.copyWith(color: t.muted)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Avatar(s.teacherInitials, size: 56, image: sampleTeacherAvatar(s.female)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              WordSafeText(s.teacherName, style: tt.titleLarge),
                              Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(color: t.primary, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    s.availableL,
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.primary),
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
                        Expanded(
                          child: BigButton(label: s.call, icon: Icons.call_rounded, onPressed: startCall),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: BigButton(
                            label: s.message,
                            icon: Icons.chat_bubble_rounded,
                            kind: ButtonKind.outline,
                            onPressed: () => context.go(Routes.studentMessages),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
