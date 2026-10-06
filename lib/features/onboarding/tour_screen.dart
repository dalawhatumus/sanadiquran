import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/settings.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';

/// 9 · Welcome tour: 3 cards, Skip always visible.
class TourScreen extends ConsumerStatefulWidget {
  const TourScreen({super.key});

  @override
  ConsumerState<TourScreen> createState() => _TourScreenState();
}

class _TourScreenState extends ConsumerState<TourScreen> {
  final _pc = PageController();
  int _i = 0;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _finish() {
    ref.read(settingsProvider.notifier).update((s) => s.copyWith(tourDone: true));
    context.go(nextStep(ref.read(settingsProvider)));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final cards = [
      (const Icon(Icons.mic_rounded), s.tour1Title, s.tour1Body),
      (const Icon(Icons.bookmark_rounded), s.tour2Title, s.tour2Body),
      (SIcon(SIcons.misbaha, size: 60, color: t.primary), s.tour3Title, s.tour3Body),
    ];
    final last = _i == cards.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: TextButton(
                  onPressed: _finish,
                  style: TextButton.styleFrom(minimumSize: const Size(72, kMinTap)),
                  child: Text(
                    s.skip,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: t.text),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pc,
                onPageChanged: (i) => setState(() => _i = i),
                children: [
                  for (final (icon, title, body) in cards)
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          Illustration(size: 160, child: icon),
                          const SizedBox(height: 32),
                          Text(title, style: tt.headlineMedium, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          Text(body, style: tt.bodyLarge, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Semantics(
              label: s.ofN(_i + 1, cards.length),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var k = 0; k < cards.length; k++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: k == _i ? 28 : 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: k == _i ? t.primary : t.offLine,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(s.ofN(_i + 1, cards.length), style: tt.bodySmall),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: BigButton(
                label: last ? s.start : s.next,
                icon: last ? Icons.check_rounded : null,
                trailingIcon: last ? null : Icons.arrow_forward_rounded,
                onPressed: last
                    ? _finish
                    : () => _pc.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
