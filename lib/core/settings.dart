import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserRole { student, teacher }

enum Gender { male, female }

/// Where a teacher's application stands. Will come from the server once the
/// backend exists; stored locally for this test build.
enum TeacherStatus { none, pending, approved, rejected }

enum MushafMode { large, page }

/// Overridden in main() with the instance loaded at startup.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

@immutable
class AppSettings {
  const AppSettings({
    this.locale,
    this.signedIn = false,
    this.role,
    this.gender,
    this.name = '',
    this.permissionsDone = false,
    this.tourDone = false,
    this.teacherStatus = TeacherStatus.none,
    this.available = true,
    this.themeMode = ThemeMode.system,
    this.mushafMode = MushafMode.large,
    this.remindersOn = true,
    this.sessions = 0,
    this.bookmarks = const [],
    this.athkarDone = const {},
    this.lastPage = 1,
  });

  /// Null until the user picks a language on first launch.
  final Locale? locale;
  final bool signedIn;
  final UserRole? role;
  final Gender? gender;
  final String name;
  final bool permissionsDone;
  final bool tourDone;
  final TeacherStatus teacherStatus;

  /// Teacher's "I'm available to teach" switch.
  final bool available;
  final ThemeMode themeMode;
  final MushafMode mushafMode;
  final bool remindersOn;

  /// Number of completed (test) sessions. Zero shows the first-time home.
  final int sessions;

  /// Bookmarked ayahs as "sura:ayah".
  final List<String> bookmarks;

  /// Athkar sets finished, keyed by set id, value = yyyy-mm-dd.
  final Map<String, String> athkarDone;
  final int lastPage;

  bool get female => gender == Gender.female;
  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  AppSettings copyWith({
    Locale? locale,
    bool? signedIn,
    UserRole? role,
    Gender? gender,
    String? name,
    bool? permissionsDone,
    bool? tourDone,
    TeacherStatus? teacherStatus,
    bool? available,
    ThemeMode? themeMode,
    MushafMode? mushafMode,
    bool? remindersOn,
    int? sessions,
    List<String>? bookmarks,
    Map<String, String>? athkarDone,
    int? lastPage,
  }) {
    return AppSettings(
      locale: locale ?? this.locale,
      signedIn: signedIn ?? this.signedIn,
      role: role ?? this.role,
      gender: gender ?? this.gender,
      name: name ?? this.name,
      permissionsDone: permissionsDone ?? this.permissionsDone,
      tourDone: tourDone ?? this.tourDone,
      teacherStatus: teacherStatus ?? this.teacherStatus,
      available: available ?? this.available,
      themeMode: themeMode ?? this.themeMode,
      mushafMode: mushafMode ?? this.mushafMode,
      remindersOn: remindersOn ?? this.remindersOn,
      sessions: sessions ?? this.sessions,
      bookmarks: bookmarks ?? this.bookmarks,
      athkarDone: athkarDone ?? this.athkarDone,
      lastPage: lastPage ?? this.lastPage,
    );
  }

  Map<String, Object?> toJson() => {
    'locale': locale?.languageCode,
    'signedIn': signedIn,
    'role': role?.name,
    'gender': gender?.name,
    'name': name,
    'permissionsDone': permissionsDone,
    'tourDone': tourDone,
    'teacherStatus': teacherStatus.name,
    'available': available,
    'themeMode': themeMode.name,
    'mushafMode': mushafMode.name,
    'remindersOn': remindersOn,
    'sessions': sessions,
    'bookmarks': bookmarks,
    'athkarDone': athkarDone,
    'lastPage': lastPage,
  };

  static T? _enum<T extends Enum>(List<T> values, Object? name) => values.where((v) => v.name == name).firstOrNull;

  factory AppSettings.fromJson(Map<String, Object?> j) => AppSettings(
    locale: j['locale'] is String ? Locale(j['locale'] as String) : null,
    signedIn: j['signedIn'] == true,
    role: _enum(UserRole.values, j['role']),
    gender: _enum(Gender.values, j['gender']),
    name: (j['name'] as String?) ?? '',
    permissionsDone: j['permissionsDone'] == true,
    tourDone: j['tourDone'] == true,
    teacherStatus: _enum(TeacherStatus.values, j['teacherStatus']) ?? TeacherStatus.none,
    available: j['available'] != false,
    themeMode: _enum(ThemeMode.values, j['themeMode']) ?? ThemeMode.system,
    mushafMode: _enum(MushafMode.values, j['mushafMode']) ?? MushafMode.large,
    remindersOn: j['remindersOn'] != false,
    sessions: (j['sessions'] as num?)?.toInt() ?? 0,
    bookmarks: [...((j['bookmarks'] as List?) ?? const []).cast<String>()],
    athkarDone: {...((j['athkarDone'] as Map?) ?? const {}).cast<String, String>()},
    lastPage: (j['lastPage'] as num?)?.toInt() ?? 1,
  );
}

class SettingsNotifier extends Notifier<AppSettings> {
  static const _key = 'settings.v2';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final raw = _prefs.getString(_key);
    if (raw == null) return const AppSettings();
    try {
      return AppSettings.fromJson((jsonDecode(raw) as Map).cast<String, Object?>());
    } on FormatException {
      return const AppSettings();
    }
  }

  void update(AppSettings Function(AppSettings s) change) {
    state = change(state);
    _prefs.setString(_key, jsonEncode(state.toJson()));
  }

  void toggleBookmark(int sura, int ayah) {
    final key = '$sura:$ayah';
    update(
      (s) => s.copyWith(
        bookmarks: s.bookmarks.contains(key) ? (List.of(s.bookmarks)..remove(key)) : [...s.bookmarks, key],
      ),
    );
  }

  void markAthkarDone(String setId) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    update((s) => s.copyWith(athkarDone: {...s.athkarDone, setId: today}));
  }

  /// Signs out and starts again from the language screen.
  void reset() {
    state = const AppSettings();
    _prefs.remove(_key);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
