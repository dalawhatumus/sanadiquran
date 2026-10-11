import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../backend/backend.dart';
import '../../core/local_files.dart';
import '../../core/log.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';

// Playing a voice note in a chat (one at a time).

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
    final f = await LocalFiles.voiceNote(widget.conversationId, widget.messageId);
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
      logIssue('Voice note: $e');
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
