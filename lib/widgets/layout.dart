import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/settings.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import 'ui.dart';

// Page layouts and the home header.

/// A screen with a scrolling body and buttons pinned at the bottom.
class StepScaffold extends StatelessWidget {
  const StepScaffold({
    super.key,
    this.showBack = false,
    this.onBack,
    this.step,
    required this.content,
    this.bottom = const [],
    this.center = false,
    this.topTrailing,
  });

  final bool showBack;
  final VoidCallback? onBack;
  final String? step;
  final List<Widget> content;
  final List<Widget> bottom;
  final bool center;
  final Widget? topTrailing;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final hasTop = showBack || step != null || topTrailing != null;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasTop)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    if (showBack) ...[BackPill(onTap: onBack), const SizedBox(width: 12)],
                    Expanded(
                      child: step == null
                          ? const SizedBox()
                          : WordSafeText(
                              step!,
                              textAlign: TextAlign.end,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.muted),
                            ),
                    ),
                    if (topTrailing != null) Flexible(child: topTrailing!),
                  ],
                ),
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: center ? c.maxHeight - 32 : 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: center ? MainAxisAlignment.center : MainAxisAlignment.start,
                      children: content,
                    ),
                  ),
                ),
              ),
            ),
            if (bottom.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < bottom.length; i++) ...[if (i > 0) const SizedBox(height: 10), bottom[i]],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "Settings" pill with the user's picture; opens settings.
class SettingsChip extends ConsumerWidget {
  const SettingsChip({super.key, this.compact = false});

  /// Just the picture, for crowded headers (still announced as "Settings").
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final s = S.of(context);
    final (name, avatar) = ref.watch(settingsProvider.select((x) => (x.name, x.avatar)));
    final initial = name.isEmpty ? '' : name.characters.first.toUpperCase();
    if (compact) {
      return Semantics(
        button: true,
        label: s.settings,
        excludeSemantics: true,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => context.push('/settings'),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Avatar(initial, size: 52, image: avatar),
          ),
        ),
      );
    }
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Material(
        color: t.surface,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => context.push('/settings'),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kMinTap),
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 16, end: 6, top: 4, bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.settings,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.text),
                  ),
                  const SizedBox(width: 8),
                  Avatar(initial, size: 44, image: avatar),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Top of a home screen: the user's full name and the settings pill.
class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final name = ref.watch(settingsProvider.select((x) => x.name));
    final big = MediaQuery.textScalerOf(context).scale(10) > 15;
    final title = FullName(name, style: tt.headlineSmall!);
    if (big) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [title, const SizedBox(height: 8), const SettingsChip()],
      );
    }
    return Row(
      children: [
        Expanded(child: title),
        const SizedBox(width: 12),
        const SettingsChip(),
      ],
    );
  }
}
