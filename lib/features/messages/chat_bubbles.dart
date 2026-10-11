part of 'chat_screen.dart';

// Messages in the conversation: day separators, bubbles, unsent messages and the blocked notice.

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
