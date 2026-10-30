import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../backend/admin.dart';
import '../../core/settings.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';

/// The newest announcement from the admins for this person, on the home
/// screen, until they close it (remembered on the phone).
class AnnouncementCard extends ConsumerStatefulWidget {
  const AnnouncementCard({super.key});

  @override
  ConsumerState<AnnouncementCard> createState() => _AnnouncementCardState();
}

class _AnnouncementCardState extends ConsumerState<AnnouncementCard> {
  static const _kDismissed = 'dismissedAnnouncements';

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final prefs = ref.watch(sharedPreferencesProvider);
    final role = ref.watch(settingsProvider.select((x) => x.role));
    final dismissed = prefs.getStringList(_kDismissed) ?? const <String>[];
    final now = DateTime.now();
    final a = (ref.watch(announcementsProvider).value ?? const <Announcement>[])
        .where((a) => a.showsTo(role, now) && !dismissed.contains(a.id) && a.text(ar: s.ar).isNotEmpty)
        .firstOrNull;
    if (a == null) return const SizedBox.shrink();

    void close() {
      // Only the last few are kept; older ones have expired or been removed.
      final keep = [a.id, ...dismissed].take(30).toList();
      prefs.setStringList(_kDismissed, keep);
      setState(() {});
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SCard(
        color: t.tint,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.campaign_rounded, color: t.primary, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WordSafeText(s.announcementL, style: tt.titleSmall!.copyWith(color: t.heading)),
                  const SizedBox(height: 4),
                  Text(a.text(ar: s.ar), style: tt.bodyLarge),
                ],
              ),
            ),
            IconButton(
              tooltip: s.close,
              onPressed: close,
              icon: Icon(Icons.close_rounded, color: t.muted, size: 26),
              style: IconButton.styleFrom(minimumSize: const Size(kMinTap, kMinTap)),
            ),
          ],
        ),
      ),
    );
  }
}
