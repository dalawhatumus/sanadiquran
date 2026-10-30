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

  static Future<void> keepOn(bool on) async {
    try {
      await _channel.invokeMethod<void>('keepOn', on);
    } catch (e) {
      logIssue('Keep screen on: $e');
    }
  }
}
