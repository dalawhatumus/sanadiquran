import 'package:flutter/foundation.dart';

/// Logs a problem while developing. Release builds (what users install)
/// write nothing, so error details never reach the phone's system log.
void logIssue(String message) {
  if (kDebugMode) debugPrint(message);
}
