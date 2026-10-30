import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/settings.dart';
import '../../core/strings.dart';
import '../../widgets/ui.dart';
import 'sign_in_panel.dart';

/// 3 · Welcome: sign in with Google (no passwords), or go straight to the
/// Quran and athkar without an account. Signing in is only needed to recite
/// to a teacher.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final tt = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return StepScaffold(
      center: true,
      content: [
        const SizedBox(height: 24),
        Center(child: Logo(dark ? 'sanadi-horizontal-rtl-cream' : 'sanadi-horizontal-rtl-green', height: 84)),
        const SizedBox(height: 28),
        WordSafeText(s.tagline, textAlign: TextAlign.center, style: tt.headlineSmall),
        const SizedBox(height: 8),
        Text(s.taglineSub, textAlign: TextAlign.center, style: tt.bodyMedium),
        const SizedBox(height: 28),
        // All in the scrolling part, so it still fits at the largest text.
        const SignInPanel(),
        const SizedBox(height: 12),
        BigButton(
          label: s.readWithoutAccount,
          iconWidget: const SIcon(SIcons.rehal),
          kind: ButtonKind.outline,
          onPressed: () {
            ref.read(settingsProvider.notifier).update((x) => x.copyWith(guest: true));
            context.go(Routes.guest);
          },
        ),
        const SizedBox(height: 16),
        Text(s.adultsNote, textAlign: TextAlign.center, style: tt.bodySmall),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            LinkButton(label: s.privacy, onPressed: () => context.push(Routes.privacy)),
            LinkButton(label: s.terms, onPressed: () => context.push(Routes.terms)),
          ],
        ),
      ],
    );
  }
}
