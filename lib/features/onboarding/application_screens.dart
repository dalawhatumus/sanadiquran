import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../backend/backend.dart';
import '../../core/router.dart';
import '../../core/settings.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';

/// Answers kept while the teacher moves through the 5 steps.
class ApplicationDraft {
  int? country;
  final languages = <int>{};
  final teach = <int>{0};
  final times = <int>{};
  int? amount;
  String ijazah = '';
  bool sampleSent = false;

  /// The recorded sample on the phone (sent with the application).
  String? samplePath;
  int sampleSec = 0;
  bool pledged = false;
}

final applicationDraftProvider = Provider<ApplicationDraft>((ref) => ApplicationDraft());

/// 10–14 · Teacher application, one step per route (/apply/1 … /apply/5).
class ApplicationScreen extends ConsumerStatefulWidget {
  const ApplicationScreen({super.key, required this.step});

  final int step;

  @override
  ConsumerState<ApplicationScreen> createState() => _ApplicationScreenState();
}

class _ApplicationScreenState extends ConsumerState<ApplicationScreen> {
  ApplicationDraft get d => ref.read(applicationDraftProvider);

  bool get _canGo => switch (widget.step) {
    1 => d.country != null && d.languages.isNotEmpty,
    2 => d.teach.isNotEmpty,
    3 => d.amount != null,
    4 => d.sampleSent,
    _ => d.pledged,
  };

  void _next() {
    if (widget.step < 5) {
      context.push('${Routes.apply}/${widget.step + 1}');
    } else {
      final st = ref.read(settingsProvider);
      // Kept even without internet: it is sent as soon as the phone is online.
      final path = d.samplePath;
      final backend = ref.read(backendProvider);
      unawaited(
        () async {
          final sample = path == null ? null : await File(path).readAsBytes();
          await backend.submitApplication(
            name: st.name,
            gender: st.gender,
            answers: _answers(st.female),
            sample: sample,
            sampleSec: d.sampleSec,
          );
        }().catchError((Object e) => debugPrint('Application not sent: $e')),
      );
      ref.read(settingsProvider.notifier).update((s) => s.copyWith(teacherStatus: TeacherStatus.pending));
      context.go(Routes.applySent);
    }
  }

  /// The answers in English, for the admin who reviews them.
  Map<String, String> _answers(bool female) {
    final en = S(ar: false, female: female);
    String pick(List<String> all, Iterable<int> chosen) => [for (final i in chosen.toList()..sort()) all[i]].join(', ');
    return {
      'Country': d.country == null ? '' : en.countries[d.country!],
      'Languages': pick(en.languages, d.languages),
      'Can teach': pick([for (final x in en.teachTypes) x.$1], d.teach),
      'Free times': pick(en.freeTimes, d.times),
      'Memorised': d.amount == null ? '' : en.amounts[d.amount!],
      'Ijazah / teachers': d.ijazah.trim(),
      'Recording sample': d.samplePath != null ? 'Recorded (${d.sampleSec}s), play it below' : 'No',
      'Pledge': d.pledged ? 'Agreed' : 'No',
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final tt = Theme.of(context).textTheme;
    final body = switch (widget.step) {
      1 => _countryStep(s, tt),
      2 => _teachStep(s, tt),
      3 => _recitationStep(s, tt),
      4 => [_SampleRecorder(draft: d, onSent: () => setState(() => d.sampleSent = true))],
      _ => _pledgeStep(s, tt),
    };
    return StepScaffold(
      showBack: widget.step > 1,
      step: s.appStep(widget.step),
      content: body,
      bottom: [
        if (widget.step != 4 || d.sampleSent)
          BigButton(
            label: widget.step == 5 ? s.sendApp : s.next,
            icon: widget.step == 5 ? Icons.send_rounded : null,
            trailingIcon: widget.step == 5 ? null : Arrows.forward,
            onPressed: _canGo ? _next : null,
          ),
      ],
    );
  }

  List<Widget> _countryStep(S s, TextTheme tt) => [
    WordSafeText(s.appCountryTitle, style: tt.headlineSmall),
    const SizedBox(height: 20),
    WordSafeText(s.country, style: tt.titleMedium),
    const SizedBox(height: 10),
    Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < s.countries.length; i++)
          PickChip(label: s.countries[i], selected: d.country == i, onTap: () => setState(() => d.country = i)),
      ],
    ),
    const SizedBox(height: 24),
    WordSafeText(s.languagesL, style: tt.titleMedium),
    Text(s.chooseAll, style: tt.bodySmall),
    const SizedBox(height: 10),
    Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < s.languages.length; i++)
          PickChip(
            label: s.languages[i],
            selected: d.languages.contains(i),
            onTap: () => setState(() => d.languages.contains(i) ? d.languages.remove(i) : d.languages.add(i)),
          ),
      ],
    ),
  ];

  List<Widget> _teachStep(S s, TextTheme tt) {
    const icons = [Icons.spellcheck_rounded, Icons.menu_book_rounded, Icons.record_voice_over_rounded];
    return [
      WordSafeText(s.appTeachTitle, style: tt.headlineSmall),
      const SizedBox(height: 16),
      for (var i = 0; i < s.teachTypes.length; i++) ...[
        ChoiceCard(
          multi: true,
          leading: TintBox(child: Icon(icons[i])),
          title: s.teachTypes[i].$1,
          subtitle: s.teachTypes[i].$2,
          selected: d.teach.contains(i),
          onTap: () => setState(() => d.teach.contains(i) ? d.teach.remove(i) : d.teach.add(i)),
        ),
        const SizedBox(height: 12),
      ],
      const SizedBox(height: 12),
      WordSafeText(s.freeTitle, style: tt.titleMedium),
      Text(s.freeSub, style: tt.bodySmall),
      const SizedBox(height: 10),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (var i = 0; i < s.freeTimes.length; i++)
            PickChip(
              label: s.freeTimes[i],
              selected: d.times.contains(i),
              onTap: () => setState(() => d.times.contains(i) ? d.times.remove(i) : d.times.add(i)),
            ),
        ],
      ),
    ];
  }

  List<Widget> _recitationStep(S s, TextTheme tt) => [
    WordSafeText(s.recitationTitle, style: tt.headlineSmall),
    const SizedBox(height: 16),
    WordSafeText(s.howMuch, style: tt.titleMedium),
    const SizedBox(height: 10),
    for (var i = 0; i < s.amounts.length; i++) ...[
      ChoiceCard(title: s.amounts[i], selected: d.amount == i, onTap: () => setState(() => d.amount = i)),
      const SizedBox(height: 10),
    ],
    const SizedBox(height: 14),
    WordSafeText(s.ijazahL, style: tt.titleMedium),
    const SizedBox(height: 10),
    TextFormField(
      initialValue: d.ijazah,
      minLines: 2,
      maxLines: 4,
      onChanged: (v) => d.ijazah = v,
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: context.t.text),
      decoration: InputDecoration(hintText: s.ijazahHint),
    ),
    const SizedBox(height: 6),
    Text(s.ijazahHelp, style: tt.bodySmall),
  ];

  List<Widget> _pledgeStep(S s, TextTheme tt) {
    final t = context.t;
    return [
      WordSafeText(s.pledgeTitle, style: tt.headlineSmall),
      const SizedBox(height: 16),
      SCard(
        child: Column(
          children: [
            for (final p in s.pledges)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_rounded, color: t.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(child: Text(p, style: tt.bodyMedium)),
                  ],
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: LinkButton(label: s.readCode, icon: Icons.description_rounded, onPressed: () => showSoon(context)),
      ),
      const SizedBox(height: 8),
      ChoiceCard(
        multi: true,
        title: s.iPromise,
        selected: d.pledged,
        onTap: () => setState(() => d.pledged = !d.pledged),
      ),
    ];
  }
}

enum _Rec { ready, recording, recorded }

/// 13 · Recording sample. Tap to record, tap to stop; never hold. The
/// recording can be played back, recorded again, or sent with the
/// application.
class _SampleRecorder extends StatefulWidget {
  const _SampleRecorder({required this.draft, required this.onSent});

  final ApplicationDraft draft;
  final VoidCallback onSent;

  @override
  State<_SampleRecorder> createState() => _SampleRecorderState();
}

class _SampleRecorderState extends State<_SampleRecorder> {
  ApplicationDraft get d => widget.draft;
  late _Rec _state = d.samplePath != null ? _Rec.recorded : _Rec.ready;
  late int _secs = d.sampleSec;
  Timer? _timer;
  AudioRecorder? _recorder;
  AudioPlayer? _player;
  bool _playing = false;

  @override
  void dispose() {
    _timer?.cancel();
    _recorder?.dispose();
    _player?.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final s = S.of(context);
    if (_state == _Rec.recording) return _stop();
    if (!(await Permission.microphone.request()).isGranted) {
      if (mounted) toast(context, s.micNeeded);
      return;
    }
    await _player?.stop();
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/sample_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final rec = _recorder ??= AudioRecorder();
    await rec.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 32000, sampleRate: 16000, numChannels: 1),
      path: path,
    );
    if (!mounted) return;
    setState(() {
      _state = _Rec.recording;
      _secs = 0;
      d.samplePath = null;
      d.sampleSent = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _secs++);
      if (_secs >= 120) _stop();
    });
  }

  Future<void> _stop() async {
    _timer?.cancel();
    final path = await _recorder?.stop();
    if (!mounted) return;
    setState(() {
      _state = _Rec.recorded;
      d.samplePath = path;
      d.sampleSec = _secs;
    });
  }

  Future<void> _play() async {
    final path = d.samplePath;
    if (path == null) return;
    final p = _player ??= AudioPlayer()
      ..onPlayerStateChanged.listen((st) {
        if (mounted) setState(() => _playing = st == PlayerState.playing);
      });
    if (_playing) {
      await p.pause();
    } else {
      await p.play(DeviceFileSource(path));
    }
  }

  String get _len => '${_secs ~/ 60}:${(_secs % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final recording = _state == _Rec.recording;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WordSafeText(s.sampleTitle, style: tt.headlineSmall),
        const SizedBox(height: 8),
        Text(s.sampleSub, style: tt.bodyMedium),
        const SizedBox(height: 28),
        if (_state == _Rec.ready || recording) ...[
          Center(
            child: Semantics(
              button: true,
              label: recording ? s.tapStop : s.tapRecord,
              child: GestureDetector(
                onTap: _toggle,
                child: Container(
                  width: 168,
                  height: 168,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: recording ? t.warn : t.primary,
                    border: Border.all(color: t.tint, width: 10),
                  ),
                  child: Icon(
                    recording ? Icons.stop_rounded : Icons.mic_rounded,
                    size: 72,
                    color: recording ? t.onWarn : t.onPrimary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            recording ? '${s.recording} · ${s.n(_len)}' : s.tapRecord,
            textAlign: TextAlign.center,
            style: tt.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(recording ? s.tapStop : s.sampleLen, textAlign: TextAlign.center, style: tt.bodySmall),
        ] else ...[
          SCard(
            onTap: _play,
            child: Row(
              children: [
                TintBox(
                  size: 56,
                  circle: true,
                  child: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: t.primary),
                ),
                const SizedBox(width: 14),
                Expanded(child: Text(s.yourSample(_len), style: tt.titleMedium)),
                if (d.sampleSent) Icon(Icons.check_circle_rounded, color: t.primary, size: 30),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (!d.sampleSent) ...[
            BigButton(label: s.sendSample, icon: Icons.send_rounded, onPressed: widget.onSent),
            const SizedBox(height: 10),
          ],
          BigButton(label: s.recordAgain, icon: Icons.mic_rounded, kind: ButtonKind.outline, onPressed: _toggle),
        ],
        const SizedBox(height: 20),
        Text(s.sampleNote, style: tt.bodySmall, textAlign: TextAlign.center),
      ],
    );
  }
}

/// 14 · Application sent.
class ApplicationSentScreen extends StatelessWidget {
  const ApplicationSentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final tt = Theme.of(context).textTheme;
    return StepScaffold(
      center: true,
      content: [
        const Center(child: Illustration(size: 144, child: Icon(Icons.volunteer_activism_rounded))),
        const SizedBox(height: 24),
        WordSafeText(s.jazak, style: tt.headlineMedium, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(s.appSentBody, style: tt.bodyLarge, textAlign: TextAlign.center),
      ],
      bottom: [BigButton(label: s.done, onPressed: () => context.go(Routes.teacherHome))],
    );
  }
}
