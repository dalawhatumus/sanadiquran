import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../backend/admin.dart';
import '../../backend/backend.dart';
import '../../backend/calls.dart';
import '../../core/background.dart';
import '../../core/reminders.dart';
import '../../core/router.dart';
import '../../core/settings.dart';
import '../../core/strings.dart';
import 'call_controller.dart';

/// Shows the incoming-call screen when a student's call rings for this
/// teacher. While a teacher is available (and online), a background service
/// keeps Sanadi running so this also works with the app in the background
/// or the phone locked: then a full-screen call alert brings the app up. A
/// second call while one is in progress is declined, so that student is put
/// through to someone else straight away.
class IncomingCallWatcher extends ConsumerStatefulWidget {
  const IncomingCallWatcher({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<IncomingCallWatcher> createState() => _IncomingCallWatcherState();
}

class _IncomingCallWatcherState extends ConsumerState<IncomingCallWatcher> with WidgetsBindingObserver {
  final _shown = <String>{};
  Timer? _beat;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncService());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _beat?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _heartbeat();
  }

  /// An approved, available teacher, online and not paused.
  bool get _teaching {
    final me = ref.read(settingsProvider);
    return ref.read(backendProvider).live &&
        me.signedIn &&
        me.role == UserRole.teacher &&
        me.teacherStatus == TeacherStatus.approved &&
        me.available &&
        !(ref.read(pausedProvider).value ?? false);
  }

  bool get _reachable => _teaching && (_foreground || Background.running);

  /// Starts or stops the background service with the "available" switch.
  Future<void> _syncService() async {
    if (_teaching) {
      final me = ref.read(settingsProvider);
      await Background.startListening(S(ar: me.locale?.languageCode == 'ar', female: me.female));
    } else {
      await Background.stopListening();
    }
    _heartbeat();
  }

  /// While an available teacher is reachable (app on screen, or kept alive
  /// in the background), says "still here" every minute; students only
  /// ring teachers who do.
  void _heartbeat() {
    _beat?.cancel();
    _beat = null;
    if (!_reachable) return;
    final b = ref.read(backendProvider);
    b.presenceHeartbeat().catchError((_) {});
    _beat = Timer.periodic(const Duration(seconds: 60), (_) {
      if (_reachable) b.presenceHeartbeat().catchError((_) {});
    });
  }

  void _onCalls(List<CallInfo> calls) {
    final me = ref.read(settingsProvider);
    if (me.role != UserRole.teacher || me.teacherStatus != TeacherStatus.approved) return;
    final controller = ref.read(callControllerProvider.notifier);
    final busy = ref.read(callControllerProvider).phase != CallPhase.idle;
    for (final c in calls) {
      if (!_shown.add(c.id)) continue;
      if (busy || !me.available) {
        controller.decline(c);
      } else {
        if (!_foreground) {
          // Not on screen: wake the phone and show the call over the lock
          // screen (cleared when the call screens close).
          Background.overLockScreen(true);
          Reminders.instance.incomingCall(
            s: S(ar: me.locale?.languageCode == 'ar', female: me.female),
            callId: c.id,
            studentName: c.studentName,
          );
        }
        ref.read(routerProvider).push('${Routes.incoming}?id=${c.id}');
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(incomingCallsProvider, (_, next) => _onCalls(next.value ?? const []));
    ref.listen(
      settingsProvider.select((s) => (s.signedIn, s.role, s.teacherStatus, s.available)),
      (_, _) => _syncService(),
    );
    ref.listen(pausedProvider, (_, _) => _syncService());
    return widget.child;
  }
}
