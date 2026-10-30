import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';
import '../quran/ayah_of_day.dart';
import 'sign_in_panel.dart';

/// Home for someone using Sanadi without an account: the Quran, athkar and
/// Ayah of the day straight away, and signing in (once, with Google) only to
/// recite to a teacher.
class GuestHomeScreen extends ConsumerWidget {
  const GuestHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Logo(dark ? 'sanadi-horizontal-rtl-cream' : 'sanadi-horizontal-rtl-green', height: 48),
                  ),
                ),
                const SettingsChip(),
              ],
            ),
            const SizedBox(height: 20),
            WordSafeText(s.guestTitle, style: tt.headlineMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Tile(
                    icon: const SIcon(SIcons.rehal, size: 40),
                    label: s.navQuran,
                    onTap: () => context.push(Routes.quran),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Tile(
                    icon: const SIcon(SIcons.misbaha, size: 40),
                    label: s.athkarTitle,
                    onTap: () => context.push(Routes.athkar),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SCard(
              color: t.tint,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.record_voice_over_rounded, color: t.primary, size: 32),
                      const SizedBox(width: 10),
                      Expanded(child: WordSafeText(s.guestReciteTitle, style: tt.titleLarge)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(s.guestReciteBody, style: tt.bodyLarge),
                  const SizedBox(height: 16),
                  const SignInPanel(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const AyahOfDayCard(),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.onTap});

  final Widget icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return SCard(
      onTap: onTap,
      // Grows with the text size rather than cutting it off.
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 110),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(height: 10),
            WordSafeText(label, style: tt.titleLarge, textAlign: TextAlign.center, maxLines: 2),
          ],
        ),
      ),
    );
  }
}
