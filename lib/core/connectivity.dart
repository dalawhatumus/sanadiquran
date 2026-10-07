import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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
