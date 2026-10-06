import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/router.dart';
import '../../core/settings.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';

enum PermKind {
  mic('mic'),
  notif('notif'),
  fullScreen('fullscreen');

  const PermKind(this.path);
  final String path;

  static PermKind fromPath(String p) => values.firstWhere((k) => k.path == p, orElse: () => mic);
}

/// Goes to the permission after [kind], or finishes the permissions step.
void _afterPermission(BuildContext context, WidgetRef ref, PermKind kind) {
  final teacher = ref.read(settingsProvider).role == UserRole.teacher;
  switch (kind) {
    case PermKind.mic:
      context.go(Routes.permNotif);
    case PermKind.notif when teacher:
      context.go(Routes.permFullScreen);
    case PermKind.notif:
    case PermKind.fullScreen:
      ref.read(settingsProvider.notifier).update((s) => s.copyWith(permissionsDone: true));
      context.go(nextStep(ref.read(settingsProvider)));
  }
}

/// 7 · Permission explainers, shown before Android's own pop-up.
class PermissionScreen extends ConsumerWidget {
  const PermissionScreen({super.key, required this.kind});

  final PermKind kind;

  Future<void> _request(BuildContext context, WidgetRef ref) async {
    if (kind == PermKind.fullScreen) {
      // Full-screen call alerts are set up with the calling feature.
      _afterPermission(context, ref, kind);
      return;
    }
    final perm = kind == PermKind.mic ? Permission.microphone : Permission.notification;
    final status = await perm.request();
    if (!context.mounted) return;
    if (status.isGranted || status.isLimited) {
      _afterPermission(context, ref, kind);
    } else {
      context.push('/perm-denied/${kind.path}');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final tt = Theme.of(context).textTheme;
    final teacher = ref.watch(settingsProvider).role == UserRole.teacher;
    final (Widget icon, String title, String body) = switch (kind) {
      PermKind.mic => (const Icon(Icons.hearing_rounded), s.micTitle, teacher ? s.micBodyTeacher : s.micBody),
      PermKind.notif => (
        const Icon(Icons.notifications_rounded),
        s.notifTitle,
        teacher ? s.notifBodyTeacher : s.notifBody,
      ),
      PermKind.fullScreen => (const Icon(Icons.phone_in_talk_rounded), s.fsTitle, s.fsBody),
    };
    return StepScaffold(
      step: kind == PermKind.fullScreen ? s.teacherSetup : s.stepOf(4, 4),
      center: true,
      content: [
        Center(child: Illustration(size: 144, child: icon)),
        const SizedBox(height: 28),
        Text(title, style: tt.headlineMedium, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(body, style: tt.bodyLarge, textAlign: TextAlign.center),
      ],
      bottom: [
        BigButton(label: s.cont, trailingIcon: Icons.arrow_forward_rounded, onPressed: () => _request(context, ref)),
        BigButton(label: s.notNow, kind: ButtonKind.outline, onPressed: () => _afterPermission(context, ref, kind)),
      ],
    );
  }
}

/// 8 · Permission denied: gentle, with the exact path in settings.
class PermissionDeniedScreen extends ConsumerStatefulWidget {
  const PermissionDeniedScreen({super.key, required this.kind});

  final PermKind kind;

  @override
  ConsumerState<PermissionDeniedScreen> createState() => _PermissionDeniedScreenState();
}

class _PermissionDeniedScreenState extends ConsumerState<PermissionDeniedScreen> {
  Future<void> _check() async {
    final perm = widget.kind == PermKind.mic ? Permission.microphone : Permission.notification;
    final ok = await perm.isGranted;
    if (!mounted) return;
    if (ok) {
      _afterPermission(context, ref, widget.kind);
    } else {
      toast(context, S.of(context).stillOff);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final mic = widget.kind == PermKind.mic;
    final steps = [s.deniedStep1, s.deniedStep2(mic), s.deniedStep3];
    return StepScaffold(
      showBack: true,
      topTrailing: TextButton(
        onPressed: () => _afterPermission(context, ref, widget.kind),
        style: TextButton.styleFrom(minimumSize: const Size(kMinTap, kMinTap)),
        child: Text(
          s.notNow,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: t.text),
        ),
      ),
      content: [
        Center(
          child: Illustration(size: 128, child: Icon(mic ? Icons.mic_off_rounded : Icons.notifications_off_rounded)),
        ),
        const SizedBox(height: 20),
        Text(mic ? s.micOffTitle : s.notifOffTitle, style: tt.headlineMedium, textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Text(mic ? s.micOffBody : s.notifOffBody, style: tt.bodyLarge, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        SCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.inPhoneSettings, style: tt.titleSmall),
              for (var i = 0; i < steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: t.tint, shape: BoxShape.circle),
                        child: Text(
                          s.n(i + 1),
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: t.primary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(steps[i], style: tt.bodyMedium)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
      bottom: [
        BigButton(label: s.openSettings, icon: Icons.settings_rounded, onPressed: openAppSettings),
        BigButton(label: s.turnedOn, kind: ButtonKind.outline, onPressed: _check),
      ],
    );
  }
}
