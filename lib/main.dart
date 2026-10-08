import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'backend/backend.dart';
import 'backend/config.dart';
import 'backend/firebase_backend.dart';
import 'core/settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // Firebase starts without internet (it keeps its own offline copy), so the
  // Quran and athkar are never held up. Without settings: demo mode.
  Backend? backend;
  if (FirebaseConfig.isSet) {
    try {
      await Firebase.initializeApp(options: FirebaseConfig.options);
      backend = FirebaseBackend();
    } catch (e) {
      debugPrint('Firebase did not start, using demo mode: $e');
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        if (backend != null) backendProvider.overrideWithValue(backend),
      ],
      child: const SanadiApp(),
    ),
  );
}
