import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/settings.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
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
    final initial = settings.name.characters.first.toUpperCase();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            HomeHeader(top: s.salam, title: settings.firstName, initial: initial),
            const SizedBox(height: 16),
            _ReciteButton(onTap: () => context.push(Routes.connecting)),
            const SizedBox(height: 16),
            StatusLine(text: s.teachersAvailable(3)),
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
                        Expanded(child: Text(s.welcomeTitle, style: tt.titleLarge)),
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
                              Text(settings.sessions > 1 ? s.nextPortion : s.firstPortion, style: tt.titleLarge),
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
                        Avatar(s.teacherInitials, size: 52),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.teacherName, style: tt.titleLarge),
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
                          child: BigButton(
                            label: s.call,
                            icon: Icons.call_rounded,
                            onPressed: () => context.push(Routes.connecting),
                          ),
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
                        Text(s.myProgress, style: tt.titleMedium!.copyWith(color: t.heading)),
                        if (!firstTime) Text(s.progressSum, style: tt.bodySmall),
                      ],
                    ),
                  ),
                  Icon(
                    context.isAr ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                    color: t.primary,
                    size: 32,
                  ),
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
  const _ReciteButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    return Semantics(
      button: true,
      label: '${s.recite}. ${s.reciteSub}',
      excludeSemantics: true,
      child: Material(
        color: t.primary,
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
                    border: Border.all(color: t.onPrimary.withValues(alpha: 0.18), width: 14),
                  ),
                  child: Icon(Icons.mic_rounded, size: 56, color: t.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  s.recite,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: t.onPrimary, height: 1.2),
                ),
                const SizedBox(height: 6),
                Text(
                  s.reciteSub,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: t.onPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
