import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../backend/backend.dart';
import '../../core/settings.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';

/// Admins review teacher applications: read the answers, then approve or
/// turn down with a reason. The teacher's app updates straight away.
class ApplicationsScreen extends ConsumerWidget {
  const ApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final tt = Theme.of(context).textTheme;
    final apps = ref.watch(pendingApplicationsProvider);
    return StepScaffold(
      showBack: true,
      content: [
        WordSafeText(s.adminTitle, style: tt.headlineMedium),
        const SizedBox(height: 16),
        ...switch (apps) {
          AsyncData(:final value) when value.isEmpty => [
            SCard(
              child: Row(
                children: [
                  Icon(Icons.inbox_rounded, color: context.t.muted, size: 32),
                  const SizedBox(width: 12),
                  Expanded(child: Text(s.adminEmpty, style: tt.bodyLarge)),
                ],
              ),
            ),
          ],
          AsyncData(:final value) => [
            for (final a in value) ...[_ApplicationCard(app: a), const SizedBox(height: 14)],
          ],
          AsyncError() => [WarnBanner(icon: Icons.error_rounded, text: s.decisionFailed)],
          _ => [const Center(child: CircularProgressIndicator())],
        },
      ],
    );
  }
}

class _ApplicationCard extends ConsumerStatefulWidget {
  const _ApplicationCard({required this.app});

  final TeacherApplication app;

  @override
  ConsumerState<_ApplicationCard> createState() => _ApplicationCardState();
}

class _ApplicationCardState extends ConsumerState<_ApplicationCard> {
  bool _busy = false;

  Future<void> _decide(bool approve) async {
    final s = S.of(context);
    var reason = '';
    if (!approve) {
      final c = TextEditingController();
      final yes = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(s.declineQ),
          content: TextField(
            controller: c,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(hintText: s.declineReason),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.declineApp)),
          ],
        ),
      );
      reason = c.text;
      c.dispose();
      if (yes != true) return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(backendProvider).decide(widget.app.uid, approve: approve, reason: reason);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.decisionFailed)));
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final a = widget.app;
    final female = a.gender == Gender.female;
    return SCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Avatar(a.name.isEmpty ? '?' : a.name.characters.first.toUpperCase(), size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FullName(a.name, style: tt.titleLarge!),
                    if (a.gender != null) Text(female ? s.sister : s.brother, style: tt.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (a.sampleSec > 0) ...[_SamplePlayer(uid: a.uid, seconds: a.sampleSec), const SizedBox(height: 12)],
          // The answers are kept in English, as the applicant gave them.
          Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final MapEntry(:key, :value) in a.answers.entries)
                  if (value.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(key, style: tt.bodySmall!.copyWith(color: t.muted)),
                          Text(value, style: tt.bodyMedium),
                        ],
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: BigButton(
                  label: s.declineApp,
                  icon: Icons.block_rounded,
                  kind: ButtonKind.outline,
                  compact: true,
                  onPressed: _busy ? null : () => _decide(false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: BigButton(
                  label: s.approve,
                  icon: Icons.verified_rounded,
                  compact: true,
                  busy: _busy,
                  onPressed: _busy ? null : () => _decide(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Plays an applicant's recitation sample (downloaded once).
class _SamplePlayer extends ConsumerStatefulWidget {
  const _SamplePlayer({required this.uid, required this.seconds});

  final String uid;
  final int seconds;

  @override
  ConsumerState<_SamplePlayer> createState() => _SamplePlayerState();
}

class _SamplePlayerState extends ConsumerState<_SamplePlayer> {
  AudioPlayer? _player;
  bool _playing = false;
  bool _loading = false;
  String? _path;

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final s = S.of(context);
    final p = _player ??= AudioPlayer()
      ..onPlayerStateChanged.listen((st) {
        if (mounted) setState(() => _playing = st == PlayerState.playing);
      });
    if (_playing) return p.pause();
    setState(() => _loading = true);
    try {
      var path = _path;
      if (path == null) {
        final bytes = await ref.read(backendProvider).applicationSample(widget.uid);
        if (bytes == null) throw StateError('No sample');
        final dir = await getTemporaryDirectory();
        final f = File('${dir.path}/sample_${widget.uid}.m4a');
        await f.writeAsBytes(bytes, flush: true);
        path = _path = f.path;
      }
      await p.play(DeviceFileSource(path));
    } catch (_) {
      if (mounted) toast(context, s.cantPlay);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    return SCard(
      color: t.tint,
      padding: const EdgeInsets.all(12),
      onTap: _loading ? null : _toggle,
      child: Row(
        children: [
          _loading
              ? const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 3))
              : Icon(_playing ? Icons.pause_circle_rounded : Icons.play_circle_rounded, color: t.primary, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: WordSafeText(s.sampleLabel(s.mmss(widget.seconds)), style: Theme.of(context).textTheme.titleSmall),
          ),
        ],
      ),
    );
  }
}
