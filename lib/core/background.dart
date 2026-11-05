import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'log.dart';
import 'strings.dart';

/// Keeping Sanadi alive in the background while a teacher is available (an
/// Android foreground service with a small permanent notification), and
/// showing the app over the lock screen while a call rings. Every call is
/// safe to make anywhere: on failure (or in tests) it does nothing.
abstract final class Background {
  static const _availability = MethodChannel('sanadi/availability');
  static const _screen = MethodChannel('sanadi/screen');
  static const _call = MethodChannel('sanadi/call');

  /// Whether the service is running (as far as this app knows), live.
  static final listening = ValueNotifier<bool>(false);
  static bool get running => listening.value;

  static Future<void> startListening(S s) async {
    if (running) return;
    try {
      listening.value =
          await _availability.invokeMethod<bool>('start', {
            'title': s.availabilityTitle,
            'text': s.availabilityText,
            'channelName': s.availabilityChannel,
          }) ??
          false;
    } catch (e) {
      logIssue('Background service: $e');
    }
  }

  static Future<void> stopListening() async {
    if (!running) return;
    listening.value = false;
    try {
      await _availability.invokeMethod<void>('stop');
    } catch (e) {
      logIssue('Background service stop: $e');
    }
  }

  /// Sends Sanadi to the background (like the Home button).
  static Future<void> moveToBack() async {
    try {
      await _screen.invokeMethod<void>('moveToBack');
    } catch (e) {
      logIssue('Move to back: $e');
    }
  }

  /// Lets the call screen show (and wake the screen) on a locked phone,
  /// while a call rings or is in progress only.
  static Future<void> overLockScreen(bool on) async {
    try {
      await _screen.invokeMethod<void>('overLockScreen', on);
    } catch (e) {
      logIssue('Over lock screen: $e');
    }
  }

  /// During a call: a foreground service of the "microphone" kind, so the
  /// other person still hears this phone with the screen off or Sanadi in
  /// the background (Android cuts the microphone off otherwise). Started
  /// while the call screen is showing, stopped when the call ends.
  static Future<void> callStarted(S s) async {
    try {
      await _call.invokeMethod<bool>('start', {
        'title': s.callServiceTitle,
        'text': s.callServiceText,
        'channelName': s.callServiceChannel,
      });
    } catch (e) {
      logIssue('Call service: $e');
    }
  }

  static Future<void> callEnded() async {
    try {
      await _call.invokeMethod<void>('stop');
    } catch (e) {
      logIssue('Call service stop: $e');
    }
  }

  /// The phone's own ringtone (looping) and vibration while a call rings,
  /// following the phone's ring and silent settings.
  static Future<void> ring(bool on) async {
    try {
      await _call.invokeMethod<void>(on ? 'ring' : 'stopRing');
    } catch (e) {
      logIssue('Ringtone: $e');
    }
  }

  /// Whether Android lets Sanadi show a call full screen over the lock
  /// screen (Android 14+ can turn this off). True where it can't be checked.
  static Future<bool> canFullScreen() async {
    try {
      return await _call.invokeMethod<bool>('canFullScreen') ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Opens the phone's setting for showing calls full screen.
  static Future<void> openFullScreenSettings() async {
    try {
      await _call.invokeMethod<void>('openFullScreenSettings');
    } catch (e) {
      logIssue('Full screen settings: $e');
    }
  }
}
