import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../backend/backend.dart';
import '../../core/connectivity.dart';
import '../../core/router.dart';
import '../../core/settings.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';

/// A slim bar above the student's tabs (Quran, athkar, messages): how many
/// teachers are free right now, with a Call button while any are. Tapping
/// the words opens the teacher list. Hidden offline.
class AvailabilityBar extends ConsumerWidget {
  const AvailabilityBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.t;
    if (ref.watch(offlineProvider)) return const SizedBox.shrink();
    final gender = ref.watch(settingsProvider.select((x) => x.gender));
    final k = ref.watch(availableTeachersProvider(gender)).value;
    if (k == null) return const SizedBox.shrink();
    final on = k > 0;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Material(
        key: const ValueKey('availability-bar'),
        color: on ? t.tint : t.surface,
        child: InkWell(
          onTap: () => context.push(Routes.teachers),
          child: Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: t.line)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: on ? t.primary : Colors.transparent,
                    border: Border.all(color: on ? t.primary : t.muted, width: 2.5),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: WordSafeText(
                    s.teachersAvailable(k),
                    maxLines: 2,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: on ? t.primary : t.muted),
                  ),
                ),
                if (on) ...[
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    key: const ValueKey('bar-call'),
                    onPressed: () async {
                      if (await ref.read(offlineProvider.notifier).check() && context.mounted) {
                        unawaited(context.push(Routes.connecting));
                      }
                    },
                    icon: const Icon(Icons.call_rounded, size: 24),
                    label: Text(s.call, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    style: FilledButton.styleFrom(
                      backgroundColor: t.primary,
                      foregroundColor: t.onPrimary,
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
