import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Checks whether the internet is reachable. Overridden in tests.
///
/// Only online features call this (sign-in, calls, messages). The Quran,
/// athkar and everything else on the phone work without internet.
final onlineCheckProvider = Provider<Future<bool> Function()>(
  (ref) => () async {
    try {
      final r = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 5));
      return r.isNotEmpty && r.first.rawAddress.isNotEmpty;
    } on Object {
      return false;
    }
  },
);

/// True after an online feature found no internet; cleared by the next
/// successful check.
class OfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  /// Runs the check, remembers the result and returns whether we're online.
  Future<bool> check() async {
    final online = await ref.read(onlineCheckProvider)();
    state = !online;
    return online;
  }
}

final offlineProvider = NotifierProvider<OfflineNotifier, bool>(OfflineNotifier.new);

/// Opens [route] (a call, for example) once a fresh check finds the
/// internet; otherwise the screens show that it's needed.
Future<void> pushWhenOnline(BuildContext context, WidgetRef ref, String route) async {
  if (await ref.read(offlineProvider.notifier).check() && context.mounted) unawaited(context.push(route));
}
