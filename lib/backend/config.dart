import 'package:firebase_core/firebase_core.dart';

/// Firebase settings, passed in at build time with --dart-define (CI reads
/// them from the repository's Variables). They are not secret: every Android
/// app carries them. When they are missing the app runs in demo mode.
abstract final class FirebaseConfig {
  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const senderId = String.fromEnvironment('FIREBASE_SENDER_ID');
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');

  /// The "Web client" OAuth id; Google sign-in on Android needs it to get a
  /// token that Firebase accepts.
  static const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  static bool get isSet => apiKey.isNotEmpty && appId.isNotEmpty && projectId.isNotEmpty && webClientId.isNotEmpty;

  static FirebaseOptions get options => const FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: senderId,
    projectId: projectId,
    storageBucket: storageBucket == '' ? null : storageBucket,
  );
}

/// An optional TURN relay, for networks that block direct calls. Set with
/// --dart-define (CI reads them from repository Variables); without it calls
/// use Google's public STUN server only.
abstract final class TurnConfig {
  static const _urls = String.fromEnvironment('TURN_URLS');
  static const username = String.fromEnvironment('TURN_USERNAME');
  static const credential = String.fromEnvironment('TURN_CREDENTIAL');

  static bool get isSet => _urls.isNotEmpty && username.isNotEmpty && credential.isNotEmpty;

  static List<String> get urls => [
    for (final u in _urls.split(','))
      if (u.trim().isNotEmpty) u.trim(),
  ];
}
