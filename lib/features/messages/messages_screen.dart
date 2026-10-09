import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show Bidi;

import '../../backend/chat.dart';
import '../../core/connectivity.dart';
import '../../core/router.dart';
import '../../core/settings.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';

/// 48 · Messages: conversations with teachers (or students), newest first,
/// with unread counts.
class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final tt = Theme.of(context).textTheme;
    final teacher = ref.watch(settingsProvider.select((x) => x.role == UserRole.teacher));
    final convs = ref.watch(conversationsProvider);
    final offline = ref.watch(offlineProvider);
    final list = convs.value ?? const <Conversation>[];

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: WordSafeText(s.navMessages, style: tt.headlineMedium),
            ),
            if (offline)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: WarnBanner(icon: Icons.wifi_off_rounded, text: s.chatOffline),
              ),
            Expanded(
              child: convs.isLoading && list.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : list.isEmpty
                  ? EmptyState(
                      icon: const Icon(Icons.chat_bubble_rounded),
                      title: s.noChatsTitle,
                      body: teacher ? s.noChatsBodyTeacher : s.noChatsBody,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _ConversationTile(c: list[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  const _ConversationTile({required this.c});

  final Conversation c;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final unread = c.unread > 0;
    final preview = c.lastVoiceSec != null ? s.voiceNoteLen(c.lastVoiceSec!) : c.lastText;
    return SCard(
      padding: const EdgeInsets.all(14),
      border: unread ? t.primary : null,
      onTap: () => context.push(Routes.chat(c.id)),
      child: Row(
        children: [
          Avatar(initialOf(c.otherName), size: 60, image: c.otherAvatar),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: FullName(c.otherName, style: tt.titleLarge!)),
                    if (c.lastAt != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        chatTime(context, c.lastAt!, short: true),
                        style: tt.bodySmall!.copyWith(
                          color: unread ? t.primary : t.muted,
                          fontWeight: unread ? FontWeight.w700 : null,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (c.lastVoiceSec != null) ...[
                      Icon(Icons.mic_rounded, size: 22, color: t.muted),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        preview,
                        textDirection: c.lastVoiceSec != null ? null : textDirectionOf(preview),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodyMedium!.copyWith(
                          color: unread ? t.text : t.muted,
                          fontWeight: unread ? FontWeight.w700 : null,
                        ),
                      ),
                    ),
                    if (unread) ...[
                      const SizedBox(width: 8),
                      Container(
                        constraints: const BoxConstraints(minWidth: 30),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: t.warn, borderRadius: BorderRadius.circular(15)),
                        child: Text(
                          s.n(c.unread),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.onWarn),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// First letter of a name, for the avatar.
String initialOf(String name) {
  final n = name.trim();
  return n.isEmpty ? '?' : n.characters.first.toUpperCase();
}

/// "14:05" today, "Yesterday", or the date. With [short], a date without the
/// time.
String chatTime(BuildContext context, DateTime at, {bool short = false}) {
  final s = S.of(context);
  final l = MaterialLocalizations.of(context);
  final now = DateTime.now();
  final day = DateTime(at.year, at.month, at.day);
  final today = DateTime(now.year, now.month, now.day);
  final time = s.n(l.formatTimeOfDay(TimeOfDay.fromDateTime(at), alwaysUse24HourFormat: true));
  if (day == today) return time;
  if (day == today.subtract(const Duration(days: 1))) return short ? s.yesterday : '${s.yesterday} $time';
  final date = s.n(l.formatShortMonthDay(at));
  return short ? date : '$date $time';
}

/// "Today", "Yesterday" or the full date, for separators in a chat.
String chatDay(BuildContext context, DateTime at) {
  final s = S.of(context);
  final now = DateTime.now();
  final day = DateTime(at.year, at.month, at.day);
  final today = DateTime(now.year, now.month, now.day);
  if (day == today) return s.today;
  if (day == today.subtract(const Duration(days: 1))) return s.yesterday;
  return s.n(MaterialLocalizations.of(context).formatMediumDate(at));
}

/// Right-to-left for Arabic messages, left-to-right for English ones,
/// whatever language the app is in (so punctuation lands at the right end).
TextDirection textDirectionOf(String text) =>
    Bidi.detectRtlDirectionality(text) ? TextDirection.rtl : TextDirection.ltr;
