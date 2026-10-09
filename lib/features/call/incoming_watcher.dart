import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../backend/backend.dart';
import '../../backend/calls.dart';
import '../../core/router.dart';
import '../../core/settings.dart';
import 'call_controller.dart';

/// While the app is open, shows the incoming-call screen when a student's
/// call rings for this teacher. A second call while one is in progress is
/// declined, so that student is put through to someone else straight away.
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _heartbeat());
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

  bool get _reachable {
    final me = ref.read(settingsProvider);
    return _foreground &&
        me.signedIn &&
        me.role == UserRole.teacher &&
        me.teacherStatus == TeacherStatus.approved &&
        me.available;
  }

  /// While an available teacher has the app on screen, says "still here"
  /// every minute; students only ring teachers who do.
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
      (_, _) => _heartbeat(),
    );
    return widget.child;
  }
}
