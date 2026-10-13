import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../backend/chat.dart';
import '../../core/reminders.dart';
import '../../core/router.dart';
import '../../core/settings.dart';
import '../../core/strings.dart';

/// Whether new messages show a notification (on unless switched off in
/// Settings; kept on this phone).
class MessageAlertsOn extends Notifier<bool> {
  static const _key = 'messageAlertsOn';

  @override
  bool build() => ref.read(sharedPreferencesProvider).getBool(_key) ?? true;

  void set(bool on) {
    state = on;
    ref.read(sharedPreferencesProvider).setBool(_key, on);
  }
}

final messageAlertsOnProvider = NotifierProvider<MessageAlertsOn, bool>(MessageAlertsOn.new);

/// Shows the notification for a new message (replaced in tests).
final showMessageNotificationProvider =
    Provider<
      Future<void> Function({required S s, required String conversationId, required String from, required String text})
    >((ref) => Reminders.instance.newMessage);

/// Shows a notification when a conversation's unread count goes up, unless
/// that chat is open on screen. Works while the app is running (open or in
/// the background). Watched once, by the app.
final messageAlertsProvider = Provider<void>((ref) {
  if (!ref.watch(messageAlertsOnProvider)) return;
  final me = ref.watch(settingsProvider.select((s) => (s.signedIn, s.locale?.languageCode == 'ar', s.female)));
  if (!me.$1) return;
  // Unread counts last seen; the first list only sets the starting point.
  Map<String, int>? seen;
  ref.listen(conversationsProvider, (_, next) {
    final list = next.value;
    if (list == null) return;
    final before = seen;
    seen = {for (final c in list) c.id: c.unread};
    if (before == null) return;
    final open = ref.read(routerProvider).state.uri.path;
    for (final c in list) {
      if (c.unread <= (before[c.id] ?? 0) || c.blocked || open == Routes.chat(c.id)) continue;
      final s = S(ar: me.$2, female: me.$3);
      unawaited(
        ref.read(showMessageNotificationProvider)(
          s: s,
          conversationId: c.id,
          from: c.otherName,
          text: c.lastVoiceSec != null ? s.voiceNote : c.lastText,
        ),
      );
    }
  }, fireImmediately: true);
});
