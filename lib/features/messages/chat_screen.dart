import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../backend/backend.dart';
import '../../backend/chat.dart';
import '../../core/connectivity.dart';
import '../../core/limits.dart';
import '../../core/local_files.dart';
import '../../core/log.dart';
import '../../core/router.dart';
import '../../core/settings.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';
import 'messages_screen.dart';
import 'report_sheet.dart';
import 'voice_note_player.dart';

part 'chat_bubbles.dart';
part 'chat_composer.dart';

/// 49 · Chat with a teacher or student: large text bubbles and voice notes
/// (tap to record, tap to send), a Call button when the teacher is
/// available, and report / block.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

/// A message that failed to send, kept so it can be tried again.
class _Failed {
  _Failed.text(this.text) : audio = null, durationSec = 0;
  _Failed.voice(Uint8List this.audio, this.durationSec) : text = '';

  final String text;
  final Uint8List? audio;
  final int durationSec;
  final id = UniqueKey();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _failed = <_Failed>[];

  String get _id => widget.conversationId;

  Backend get _backend => ref.read(backendProvider);

  void _send(_Failed m) {
    setState(() => _failed.remove(m));
    final f = m.audio != null ? _backend.sendVoice(_id, m.audio!, m.durationSec) : _backend.sendText(_id, m.text);
    // Offline, Firestore keeps the message and sends it later; only a
    // refusal or error ends up here.
    unawaited(
      f.catchError((Object e) {
        logIssue('Message not sent: $e');
        if (mounted) setState(() => _failed.add(m));
      }),
    );
  }

  Future<void> _delete(ChatMessage m) async {
    final s = S.of(context);
    final yes = await confirm(context, title: s.deleteQ, confirmLabel: s.delete, destructive: true);
    if (yes) unawaited(_backend.deleteMessage(_id, m).catchError((_) {}));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    final convs = ref.watch(conversationsProvider).value ?? const <Conversation>[];
    final c = convs.where((x) => x.id == _id).firstOrNull;
    final msgs = ref.watch(messagesProvider(_id));
    final me = _backend.myUid;
    final offline = ref.watch(offlineProvider);

    // Opening the chat reads it.
    if ((c?.unread ?? 0) > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _backend.markRead(_id).catchError((_) {}));
    }

    final list = msgs.value ?? const <ChatMessage>[];
    // Newest at the bottom: the list is reversed, so build it newest first.
    final items = <Widget>[for (final f in _failed.reversed) _FailedBubble(failed: f, onRetry: () => _send(f))];
    for (var i = list.length - 1; i >= 0; i--) {
      final m = list[i];
      final mine = m.senderId == me;
      items.add(
        _Bubble(
          key: ValueKey(m.id),
          message: m,
          mine: mine,
          conversationId: _id,
          onLongPress: mine ? () => _delete(m) : null,
        ),
      );
      final day = m.sentAt;
      final before = i > 0 ? list[i - 1].sentAt : null;
      if (day != null && (before == null || !DateUtils.isSameDay(day, before))) {
        items.add(_DaySeparator(text: chatDay(context, day)));
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(c: c),
            Divider(height: 1, color: t.line),
            if (offline)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: WarnBanner(icon: Icons.wifi_off_rounded, text: s.chatOffline),
              ),
            Expanded(
              child: msgs.isLoading && list.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(reverse: true, padding: const EdgeInsets.fromLTRB(16, 12, 16, 12), children: items),
            ),
            if (c != null && c.blocked)
              _BlockedBar(c: c)
            else
              _Composer(
                onText: (text) => _send(_Failed.text(text)),
                onVoice: (audio, sec) => _send(_Failed.voice(audio, sec)),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.c});

  final Conversation? c;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final c = this.c;
    final student = ref.watch(settingsProvider.select((x) => x.role == UserRole.student));
    final otherTeacher = c?.otherRole == UserRole.teacher;
    final available = c != null && otherTeacher ? ref.watch(teacherAvailableProvider(c.otherUid)).value : null;

    // The header keeps room for the name next to the buttons at large text.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.5,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
        child: Row(
          children: [
            IconButton(
              tooltip: s.back,
              onPressed: () => context.canPop() ? context.pop() : context.go(Routes.studentMessages),
              icon: Icon(Arrows.back, size: 30, color: t.text),
              style: IconButton.styleFrom(minimumSize: const Size(kMinTap, kMinTap)),
            ),
            if (c != null) ...[
              Avatar(initialOf(c.otherName), size: 48, image: c.otherAvatar),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FullName(c.otherName, style: tt.titleLarge!),
                    if (available != null)
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: available ? t.primary : Colors.transparent,
                              border: Border.all(color: available ? t.primary : t.muted, width: 2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: WordSafeText(
                              available ? s.availableL : s.away,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: available ? t.primary : t.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (student && available == true && !c.blocked)
                IconButton.filled(
                  tooltip: s.call,
                  onPressed: () async {
                    if (await ref.read(offlineProvider.notifier).check() && context.mounted) {
                      unawaited(context.push('${Routes.connecting}?teacher=${c.otherUid}'));
                    }
                  },
                  icon: const Icon(Icons.call_rounded, size: 28),
                  style: IconButton.styleFrom(
                    backgroundColor: t.primary,
                    foregroundColor: t.onPrimary,
                    minimumSize: const Size(56, 56),
                  ),
                ),
              IconButton(
                tooltip: s.reportBlock,
                onPressed: () => showReportSheet(context, c),
                icon: Icon(Icons.flag_rounded, size: 28, color: t.muted),
                style: IconButton.styleFrom(minimumSize: const Size(kMinTap, kMinTap)),
              ),
            ] else
              const Spacer(),
          ],
        ),
      ),
    );
  }
}
