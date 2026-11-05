import 'package:flutter/services.dart';

import 'log.dart';

/// Keeps the phone's screen on (during a lesson call) or lets it sleep
/// again. Does nothing where the platform doesn't support it (e.g. tests).
abstract final class Screen {
  static const _channel = MethodChannel('sanadi/screen');

  /// Opens the phone's "Add a Google account" screen. False if it couldn't.
  static Future<bool> addGoogleAccount() async {
    try {
      return await _channel.invokeMethod<bool>('addGoogleAccount') ?? false;
    } catch (e) {
      logIssue('Add Google account: $e');
      return false;
    }
  }

  /// How many screens currently want the screen kept on (the Quran, the
  /// athkar, a call). It goes dark again only once none of them do.
  static int _holds = 0;

  /// [on]: one more screen wants it on; off: one fewer. Calls must pair up.
  static Future<void> keepOn(bool on) async {
    _holds = on ? _holds + 1 : (_holds > 0 ? _holds - 1 : 0);
    try {
      await _channel.invokeMethod<void>('keepOn', _holds > 0);
    } catch (e) {
      logIssue('Keep screen on: $e');
    }
  }
}
