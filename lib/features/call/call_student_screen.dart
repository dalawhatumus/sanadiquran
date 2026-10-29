import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../backend/chat.dart';
import '../../core/router.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';
import '../messages/messages_screen.dart';
import '../teacher/students_screen.dart';
import 'call_controller.dart';

/// A student's name and picture for the teacher, from their chat or their
/// lessons together.
(String, String?) studentContact(WidgetRef ref, String uid) {
  final chat = (ref.watch(conversationsProvider).value ?? const <Conversation>[])
      .where((c) => c.otherUid == uid)
      .firstOrNull;
  if (chat != null) return (chat.otherName, chat.otherAvatar);
  final taught = ref.watch(taughtStudentsProvider).where((x) => x.uid == uid).firstOrNull;
  return (taught?.name ?? '', taught?.avatar);
}

/// A teacher calls one of their students: "Calling Fatima…" while it rings,
/// then the call; or "Fatima didn't answer" with a way to send a message.
class CallStudentScreen extends ConsumerStatefulWidget {
  const CallStudentScreen({super.key, required this.studentId});

  final String studentId;

  @override
  ConsumerState<CallStudentScreen> createState() => _CallStudentScreenState();
}

class _CallStudentScreenState extends ConsumerState<CallStudentScreen> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  CallController get _c => ref.read(callControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  void _start() {
    if (!mounted) return;
    final (name, avatar) = studentContact(ref, widget.studentId);
    _c.reset();
    _c.startAsTeacher(studentId: widget.studentId, studentName: name, studentAvatar: avatar);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _cancel() async {
    final st = ref.read(callControllerProvider);
    if (st.searching) {
      await _c.cancel();
    } else {
      _c.reset();
    }
    if (mounted) context.canPop() ? context.pop() : context.go(Routes.teacherStudents);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final st = ref.watch(callControllerProvider);
    ref.listen(callControllerProvider, (prev, next) {
      if (next.inCall && !(prev?.inCall ?? false)) context.pushReplacement('${Routes.inCall}?teacher=1');
    });
    final (contactName, contactAvatar) = studentContact(ref, widget.studentId);
    final name = st.otherName.isNotEmpty ? st.otherName : contactName;
    final avatar = st.otherAvatar ?? contactAvatar;

    if (st.phase == CallPhase.unmatched || st.phase == CallPhase.failed || st.phase == CallPhase.noMic) {
      final (icon, title, body) = switch (st.phase) {
        CallPhase.unmatched => (Icons.phone_missed_rounded, s.noAnswerTitle(name), s.noAnswerBody),
        CallPhase.noMic => (Icons.mic_off_rounded, s.callFailedTitle, s.micNeededCall),
        _ => (Icons.wifi_off_rounded, s.callFailedTitle, s.callFailedBody),
      };
      final chat = (ref.watch(conversationsProvider).value ?? const <Conversation>[])
          .where((c) => c.otherUid == widget.studentId)
          .firstOrNull;
      return StepScaffold(
        center: true,
        content: [
          Center(child: Illustration(size: 112, child: Icon(icon))),
          const SizedBox(height: 18),
          WordSafeText(title, style: tt.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(body, style: tt.bodyLarge, textAlign: TextAlign.center),
        ],
        bottom: [
          if (st.phase == CallPhase.noMic)
            BigButton(label: s.openSettings, icon: Icons.settings_rounded, onPressed: openAppSettings)
          else
            BigButton(label: s.tryAgain, icon: Icons.refresh_rounded, onPressed: _start),
          if (st.phase == CallPhase.unmatched && chat != null)
            BigButton(
              label: s.message,
              icon: Icons.chat_bubble_rounded,
              kind: ButtonKind.outline,
              onPressed: () {
                _c.reset();
                context.pushReplacement(Routes.chat(chat.id));
              },
            ),
          BigButton(label: s.back, icon: Arrows.back, kind: ButtonKind.outline, onPressed: _cancel),
        ],
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: StepScaffold(
        center: true,
        content: [
          const SizedBox(height: 20),
          Center(
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, child) => Container(
                width: 200,
                height: 200,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: t.tint.withValues(alpha: 1 - _pulse.value * 0.7),
                ),
                child: child,
              ),
              child: Avatar(initialOf(name), size: 140, image: avatar, ring: true),
            ),
          ),
          const SizedBox(height: 36),
          Semantics(
            liveRegion: true,
            child: WordSafeText(s.callingName(name), style: tt.headlineSmall, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 8),
          Text(s.callStudentSub, style: tt.bodyLarge, textAlign: TextAlign.center),
        ],
        bottom: [BigButton(label: s.cancel, icon: Icons.close_rounded, kind: ButtonKind.outline, onPressed: _cancel)],
      ),
    );
  }
}
