import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
