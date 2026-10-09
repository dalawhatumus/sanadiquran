import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../backend/backend.dart';
import '../../backend/chat.dart';
import '../../core/connectivity.dart';
import '../../core/router.dart';
import '../../core/settings.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';
import 'messages_screen.dart';
import 'report_sheet.dart';

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
        debugPrint('Message not sent: $e');
        if (mounted) setState(() => _failed.add(m));
      }),
    );
  }

  Future<void> _delete(ChatMessage m) async {
    final s = S.of(context);
    final t = context.t;
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteQ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              s.delete,
              style: TextStyle(color: t.warn, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (yes == true) unawaited(_backend.deleteMessage(_id, m).catchError((_) {}));
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
                      unawaited(context.push(Routes.connecting));
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

class _DaySeparator extends StatelessWidget {
  const _DaySeparator({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(color: t.tint, borderRadius: BorderRadius.circular(14)),
          child: Text(
            text,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t.text),
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({super.key, required this.message, required this.mine, required this.conversationId, this.onLongPress});

  final ChatMessage message;
  final bool mine;
  final String conversationId;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    final m = message;
    final fg = mine ? t.onPrimary : t.text;
    final sub = mine ? t.onPrimary.withValues(alpha: 0.85) : t.muted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
          child: Material(
            color: mine ? t.primary : t.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadiusDirectional.only(
                topStart: const Radius.circular(20),
                topEnd: const Radius.circular(20),
                bottomStart: Radius.circular(mine ? 20 : 6),
                bottomEnd: Radius.circular(mine ? 6 : 20),
              ),
              side: mine ? BorderSide.none : BorderSide(color: t.line, width: 1.5),
            ),
            child: InkWell(
              onLongPress: onLongPress,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (m.type == MessageType.text)
                      Text(
                        m.text,
                        textDirection: textDirectionOf(m.text),
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: fg, height: 1.4),
                      )
                    else
                      VoiceNotePlayer(
                        conversationId: conversationId,
                        messageId: m.id,
                        durationSec: m.durationSec,
                        mine: mine,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (m.sentAt != null)
                          Text(
                            chatTime(context, m.sentAt!),
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: sub),
                          ),
                        if (m.pending) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.schedule_rounded, size: 16, color: sub, semanticLabel: s.sending),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FailedBubble extends StatelessWidget {
  const _FailedBubble({required this.failed, required this.onRetry});

  final _Failed failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
          child: Material(
            color: t.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: t.warn, width: 2),
            ),
            child: InkWell(
              onTap: onRetry,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      failed.audio != null ? s.voiceNoteLen(failed.durationSec) : failed.text,
                      textDirection: failed.audio != null ? null : textDirectionOf(failed.text),
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: t.text, height: 1.4),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh_rounded, size: 22, color: t.warn),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            s.notSent,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.warn),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BlockedBar extends ConsumerWidget {
  const _BlockedBar({required this.c});

  final Conversation c;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    return Container(
      color: t.surface,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            c.blockedByMe ? s.youBlocked(c.otherName) : s.cantReply,
            textAlign: TextAlign.center,
            style: tt.bodyMedium,
          ),
          if (c.blockedByMe) ...[
            const SizedBox(height: 10),
            BigButton(
              label: s.unblock,
              icon: Icons.lock_open_rounded,
              kind: ButtonKind.outline,
              onPressed: () => ref.read(backendProvider).setBlocked(c.id, blocked: false).catchError((_) {}),
            ),
          ],
        ],
      ),
    );
  }
}

enum _Rec { idle, recording, stopped }

/// Text field and send button, or a big microphone: tap to record, then
/// Cancel or Send (no holding needed).
class _Composer extends StatefulWidget {
  const _Composer({required this.onText, required this.onVoice});

  final ValueChanged<String> onText;
  final void Function(Uint8List audio, int durationSec) onVoice;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final _c = TextEditingController();
  AudioRecorder? _recorder;
  _Rec _state = _Rec.idle;
  int _secs = 0;
  Timer? _timer;
  String? _path;

  @override
  void initState() {
    super.initState();
    _c.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder?.dispose();
    _c.dispose();
    super.dispose();
  }

  void _sendText() {
    final text = _c.text.trim();
    if (text.isEmpty) return;
    widget.onText(text);
    _c.clear();
  }

  Future<void> _startRecording() async {
    final s = S.of(context);
    var status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (!mounted) return;
      final open = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text(s.micNeeded, style: const TextStyle(fontSize: 18)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.openSettings)),
          ],
        ),
      );
      if (open == true) await openAppSettings();
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final rec = _recorder ??= AudioRecorder();
    // Speech quality is plenty and keeps a 3-minute note well under 1 MB.
    await rec.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 32000, sampleRate: 16000, numChannels: 1),
      path: path,
    );
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    setState(() {
      _state = _Rec.recording;
      _secs = 0;
      _path = path;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _secs++);
      if (_secs >= maxVoiceSeconds) _stop();
    });
  }

  Future<void> _stop() async {
    _timer?.cancel();
    final path = await _recorder?.stop();
    if (path != null) _path = path;
    if (mounted) setState(() => _state = _Rec.stopped);
  }

  Future<void> _cancel() async {
    _timer?.cancel();
    await _recorder?.cancel();
    _deleteFile();
    if (mounted) setState(() => _state = _Rec.idle);
  }

  Future<void> _sendVoice() async {
    if (_state == _Rec.recording) await _stop();
    final path = _path;
    final secs = _secs;
    if (path == null || secs < 1) return _cancel();
    final bytes = await File(path).readAsBytes();
    _deleteFile();
    widget.onVoice(bytes, secs);
    if (mounted) setState(() => _state = _Rec.idle);
  }

  void _deleteFile() {
    final p = _path;
    _path = null;
    if (p != null) File(p).delete().ignore();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    return Container(
      color: t.surface,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: _state == _Rec.idle ? _idle(s, t) : _recording(s, t),
    );
  }

  Widget _idle(S s, SanadiTokens t) {
    final hasText = _c.text.trim().isNotEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _c,
            // Follows what is typed: Arabic right-to-left, English left-to-right.
            textDirection: _c.text.trim().isEmpty ? null : textDirectionOf(_c.text),
            minLines: 1,
            maxLines: 4,
            maxLength: 2000,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: t.text),
            decoration: InputDecoration(hintText: s.typeMessage, counterText: ''),
          ),
        ),
        const SizedBox(width: 10),
        hasText
            ? IconButton.filled(
                tooltip: s.send,
                onPressed: _sendText,
                icon: const Icon(Icons.send_rounded, size: 30, textDirection: TextDirection.ltr),
                style: IconButton.styleFrom(
                  backgroundColor: t.primary,
                  foregroundColor: t.onPrimary,
                  minimumSize: const Size(60, 60),
                ),
              )
            : IconButton.filled(
                tooltip: s.record,
                onPressed: _startRecording,
                icon: const Icon(Icons.mic_rounded, size: 32),
                style: IconButton.styleFrom(
                  backgroundColor: t.primary,
                  foregroundColor: t.onPrimary,
                  minimumSize: const Size(60, 60),
                ),
              ),
      ],
    );
  }

  Widget _recording(S s, SanadiTokens t) {
    final tt = Theme.of(context).textTheme;
    final recording = _state == _Rec.recording;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              recording ? Icons.fiber_manual_record_rounded : Icons.mic_rounded,
              color: recording ? t.warn : t.primary,
              size: 28,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                recording ? '${s.recording} · ${s.mmss(_secs)}' : s.voiceNoteLen(_secs),
                style: tt.titleMedium,
              ),
            ),
          ],
        ),
        if (_secs >= maxVoiceSeconds - 20) ...[const SizedBox(height: 4), Text(s.voiceMax, style: tt.bodySmall)],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: BigButton(
                label: s.cancel,
                icon: Icons.close_rounded,
                kind: ButtonKind.outline,
                compact: true,
                onPressed: _cancel,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: BigButton(label: s.send, icon: Icons.send_rounded, compact: true, onPressed: _sendVoice),
            ),
          ],
        ),
      ],
    );
  }
}

/// Plays a voice note: big play / pause button, progress and length. The
/// recording is downloaded once and kept on the phone.
class VoiceNotePlayer extends ConsumerStatefulWidget {
  const VoiceNotePlayer({
    super.key,
    required this.conversationId,
    required this.messageId,
    required this.durationSec,
    required this.mine,
  });

  final String conversationId;
  final String messageId;
  final int durationSec;
  final bool mine;

  /// Only one voice note plays at a time.
  static final playing = ValueNotifier<String?>(null);

  @override
  ConsumerState<VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends ConsumerState<VoiceNotePlayer> {
  AudioPlayer? _player;
  final _subs = <StreamSubscription<Object?>>[];
  bool _loading = false;
  bool _playing = false;
  Duration _pos = Duration.zero;

  @override
  void initState() {
    super.initState();
    VoiceNotePlayer.playing.addListener(_otherStarted);
  }

  void _otherStarted() {
    if (VoiceNotePlayer.playing.value != widget.messageId && _playing) _player?.pause();
  }

  @override
  void dispose() {
    VoiceNotePlayer.playing.removeListener(_otherStarted);
    for (final s in _subs) {
      s.cancel();
    }
    _player?.dispose();
    super.dispose();
  }

  Future<String> _file() async {
    final dir = await getApplicationCacheDirectory();
    final f = File('${dir.path}/voice/${widget.conversationId}_${widget.messageId}.m4a');
    if (!await f.exists()) {
      final bytes = await ref.read(backendProvider).voiceAudio(widget.conversationId, widget.messageId);
      await f.parent.create(recursive: true);
      await f.writeAsBytes(bytes, flush: true);
    }
    return f.path;
  }

  Future<void> _toggle() async {
    final s = S.of(context);
    if (_playing) {
      await _player?.pause();
      return;
    }
    setState(() => _loading = true);
    try {
      final p = _player ??= () {
        final p = AudioPlayer();
        _subs
          ..add(
            p.onPlayerStateChanged.listen((st) {
              if (mounted) setState(() => _playing = st == PlayerState.playing);
            }),
          )
          ..add(
            p.onPositionChanged.listen((d) {
              if (mounted) setState(() => _pos = d);
            }),
          )
          ..add(
            p.onPlayerComplete.listen((_) {
              if (mounted) setState(() => _pos = Duration.zero);
            }),
          );
        return p;
      }();
      VoiceNotePlayer.playing.value = widget.messageId;
      if (_pos > Duration.zero) {
        await p.resume();
      } else {
        await p.play(DeviceFileSource(await _file()));
      }
    } catch (e) {
      debugPrint('Voice note: $e');
      if (mounted) toast(context, s.cantPlay);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    final fg = widget.mine ? t.onPrimary : t.primary;
    final total = widget.durationSec <= 0 ? 1 : widget.durationSec;
    final progress = (_pos.inMilliseconds / (total * 1000)).clamp(0.0, 1.0);
    final shown = _playing || _pos > Duration.zero ? _pos.inSeconds : widget.durationSec;
    return Semantics(
      button: true,
      label: '${s.voiceNote}, ${s.mmss(widget.durationSec)}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: IconButton.filled(
              tooltip: _playing ? s.pause : s.play,
              onPressed: _loading ? null : _toggle,
              icon: _loading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 3, color: widget.mine ? t.primary : t.onPrimary),
                    )
                  : Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 34),
              style: IconButton.styleFrom(
                backgroundColor: fg,
                foregroundColor: widget.mine ? t.primary : t.onPrimary,
                disabledBackgroundColor: fg,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Shrinks to make room for the length at large text sizes.
          Flexible(
            child: SizedBox(
              width: 120,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  color: fg,
                  backgroundColor: fg.withValues(alpha: 0.25),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            s.mmss(shown),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: widget.mine ? t.onPrimary : t.text,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
