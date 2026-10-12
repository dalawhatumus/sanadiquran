import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanadi/backend/sessions.dart';
import 'package:sanadi/core/limits.dart';
import 'package:sanadi/core/local_files.dart';
import 'package:sanadi/core/reminders.dart';
import 'package:sanadi/core/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local safety checks: damaged data on the phone, file names, where a
/// notification may lead, and the app's limits against the server's.
void main() {
  Future<ProviderContainer> withPrefs(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(c.dispose);
    return c;
  }

  test('damaged settings on the phone start fresh instead of crashing', () async {
    for (final raw in ['not json', '[1,2]', '{"name": 42, "bookmarks": "x"}', '{"pageBookmarks": ["a"]}']) {
      final c = await withPrefs({'settings.v2': raw});
      expect(c.read(settingsProvider).signedIn, isFalse, reason: raw);
    }
    final c = await withPrefs({'lastPage': 9999});
    expect(c.read(lastPageProvider), 604);
  });

  test('a damaged next portion is ignored, and signing out forgets it', () async {
    final bad = await withPrefs({'ownNextPortion': '{oops'});
    expect(bad.read(ownNextPortionProvider), isNull);
    final c = await withPrefs({});
    c.read(ownNextPortionProvider.notifier).set(const Portion(67, 1, 5));
    expect(c.read(ownNextPortionProvider), isNotNull);
    c.read(ownNextPortionProvider.notifier).clear();
    expect(c.read(ownNextPortionProvider), isNull);
    expect((await SharedPreferences.getInstance()).getString('ownNextPortion'), isNull);
  });

  test('file names from the server can never leave the app folders', () {
    expect(LocalFiles.safeName('s1_t1'), 's1_t1');
    expect(LocalFiles.safeName('../../etc/passwd'), '______etc_passwd');
    expect(LocalFiles.safeName(r'a\b/c'), 'a_b_c');
  });

  test('a notification can only open the athkar it was made for', () {
    expect(Reminders.safeRoute('/athkar/morning'), '/athkar/morning');
    expect(Reminders.safeRoute('/athkar/evening'), '/athkar/evening');
    for (final bad in [null, '', '/admin', '/settings', '/athkar/morning?x=1', 'https://example.com']) {
      expect(Reminders.safeRoute(bad), isNull, reason: '$bad');
    }
  });

  test("the app's typing limits are within the server's", () {
    final rules = File('firebase/firestore.rules').readAsStringSync();
    int serverMax(String pattern) {
      final m = RegExp(pattern).firstMatch(rules);
      expect(m, isNotNull, reason: 'rule not found: $pattern');
      return int.parse(m!.group(1)!);
    }

    expect(Limits.name, lessThanOrEqualTo(serverMax(r"get\('name', null\), (\d+)\)")));
    expect(Limits.message, lessThanOrEqualTo(serverMax(r'data\.text\.size\(\) <= (\d+)')));
    expect(Limits.lessonNote, lessThanOrEqualTo(serverMax(r'notes\.note, (\d+)\)')));
    expect(Limits.reportDetails, lessThanOrEqualTo(serverMax(r'data\.details, (\d+)\)')));
    expect(Limits.declineReason, lessThanOrEqualTo(serverMax(r"get\('reason', null\), (\d+)\)")));
    expect(Limits.pauseReason, lessThanOrEqualTo(serverMax(r'data\.reason, (\d+)\)')));
  });
}
