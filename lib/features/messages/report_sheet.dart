import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../backend/backend.dart';
import '../../backend/chat.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';

/// 50 · Report or block the other person in a chat.
Future<void> showReportSheet(BuildContext context, Conversation c) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _ReportSheet(c: c),
);

class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet({required this.c});

  final Conversation c;

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  final _details = TextEditingController();
  int? _reason;
  bool _alsoBlock = false;
  bool _busy = false;
  bool _sent = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final s = S.of(context);
    final backend = ref.read(backendProvider);
    setState(() => _busy = true);
    try {
      await backend.report(
        conversationId: widget.c.id,
        reportedUid: widget.c.otherUid,
        reason: ReportReason.values[_reason!],
        details: _details.text,
      );
      if (_alsoBlock) await backend.setBlocked(widget.c.id, blocked: true);
      if (mounted) setState(() => _sent = true);
    } catch (_) {
      if (mounted) toast(context, s.decisionFailed);
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _block() async {
    final s = S.of(context);
    final t = context.t;
    final name = widget.c.otherName;
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(s.blockQ(name), style: const TextStyle(fontSize: 18)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              s.block,
              style: TextStyle(color: t.warn, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (yes != true) return;
    await ref.read(backendProvider).setBlocked(widget.c.id, blocked: true).catchError((_) {});
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final name = widget.c.otherName;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: _sent
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Center(child: Icon(Icons.check_circle_rounded, color: t.primary, size: 64)),
                    const SizedBox(height: 12),
                    WordSafeText(s.reportThanks, style: tt.titleLarge, textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    BigButton(label: s.done, onPressed: () => Navigator.pop(context)),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    WordSafeText(s.reportName(name), style: tt.headlineSmall),
                    const SizedBox(height: 12),
                    WordSafeText(s.whatHappened, style: tt.titleMedium),
                    const SizedBox(height: 10),
                    for (var i = 0; i < s.reportReasons.length; i++) ...[
                      ChoiceCard(
                        title: s.reportReasons[i],
                        selected: _reason == i,
                        onTap: () => setState(() => _reason = i),
                      ),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 4),
                    TextField(
                      controller: _details,
                      minLines: 2,
                      maxLines: 4,
                      maxLength: 1000,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: t.text),
                      decoration: InputDecoration(hintText: s.reportDetails, counterText: ''),
                    ),
                    const SizedBox(height: 8),
                    if (!widget.c.blockedByMe)
                      ChoiceCard(
                        multi: true,
                        title: s.alsoBlock(name),
                        selected: _alsoBlock,
                        onTap: () => setState(() => _alsoBlock = !_alsoBlock),
                      ),
                    const SizedBox(height: 16),
                    BigButton(
                      label: s.sendReport,
                      icon: Icons.flag_rounded,
                      busy: _busy,
                      onPressed: _reason == null || _busy ? null : _send,
                    ),
                    if (!widget.c.blockedByMe) ...[
                      const SizedBox(height: 10),
                      BigButton(
                        label: s.blockName(name),
                        icon: Icons.block_rounded,
                        kind: ButtonKind.outline,
                        onPressed: _busy ? null : _block,
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
