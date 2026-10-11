part of 'chat_screen.dart';

// Writing a message or recording a voice note.

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
      final open = await confirm(context, body: s.micNeeded, confirmLabel: s.openSettings);
      if (open) await openAppSettings();
      return;
    }
    final path = await LocalFiles.newRecording('voice');
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
            maxLength: Limits.message,
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
