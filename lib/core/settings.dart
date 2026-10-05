import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserRole { student, teacher }

/// Overridden in main() with the instance loaded at startup.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

@immutable
class AppSettings {
  const AppSettings({this.locale, this.role});

  /// Null until the user picks a language on first launch.
  final Locale? locale;

  /// Null until onboarding is done. Will come from the user's account once
  /// sign-in is built; stored locally for now.
  final UserRole? role;

  AppSettings copyWith({Locale? locale, UserRole? role, bool clearRole = false}) {
    return AppSettings(
      locale: locale ?? this.locale,
      role: clearRole ? null : (role ?? this.role),
    );
  }
}

class SettingsNotifier extends Notifier<AppSettings> {
  static const _localeKey = 'locale';
  static const _roleKey = 'role';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final code = _prefs.getString(_localeKey);
    final roleName = _prefs.getString(_roleKey);
    return AppSettings(
      locale: code == null ? null : Locale(code),
      role: UserRole.values.where((r) => r.name == roleName).firstOrNull,
    );
  }

  Future<void> setLocale(Locale locale) async {
    state = state.copyWith(locale: locale);
    await _prefs.setString(_localeKey, locale.languageCode);
  }

  Future<void> setRole(UserRole role) async {
    state = state.copyWith(role: role);
    await _prefs.setString(_roleKey, role.name);
  }

  Future<void> signOut() async {
    state = state.copyWith(clearRole: true);
    await _prefs.remove(_roleKey);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
