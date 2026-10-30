import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanadi/backend/backend.dart';
import 'package:sanadi/core/router.dart';
import 'package:sanadi/core/settings.dart';
import 'package:sanadi/core/strings.dart';
import 'package:sanadi/features/onboarding/guest_home_screen.dart';
import 'package:sanadi/features/quran/quran_data.dart';
import 'package:sanadi/features/quran/surah_index_screen.dart';
import 'package:sanadi/widgets/ui.dart';

import 'helpers.dart';

class _Signed extends DemoBackend {
  @override
  String? get accountEmail => 'amal.hassan@gmail.com';
}

/// Signing in without passwords: the real Google button, help for a phone
/// with no Google account, using the Quran and athkar without an account,
/// and seeing which Google account is used.
void main() {
  const s = S(ar: false, female: true);

  setUpAll(loadAppFonts);

  Future<void> tap(WidgetTester tester, String text) async {
    final f = find.text(text);
    await tester.ensureVisible(f.first);
    await tester.pumpAndSettle();
    await tester.tap(f.first);
    await tester.pumpAndSettle();
  }

  testWidgets('the welcome screen: Google\'s own button, no password, help without an account', (tester) async {
    await startApp(tester, prefs: {'settings.v2': '{"locale":"en"}'});
    await tester.pumpAndSettle();
    expect(find.byType(GoogleButton), findsOneWidget);
    expect(find.descendant(of: find.byType(GoogleButton), matching: find.byType(SvgPicture)), findsOneWidget);
    expect(find.text(s.noPasswordNote), findsOneWidget);

    await tap(tester, s.noGoogleAccountQ);
    expect(find.text(s.addGoogleAccount), findsOneWidget);
    for (final step in s.noAccountSteps) {
      expect(find.text(step), findsOneWidget);
    }
    await tap(tester, s.close);
    expect(find.text(s.addGoogleAccount), findsNothing);
  });

  testWidgets('without an account: the Quran and athkar straight away, remembered next time', (tester) async {
    final (container, prefs) = await startApp(
      tester,
      prefs: {'settings.v2': '{"locale":"en"}'},
      overrides: [quranProvider.overrideWith((ref) async => testQuran)],
    );
    await tester.pumpAndSettle();
    await tap(tester, s.readWithoutAccount);
    expect(find.byType(GuestHomeScreen), findsOneWidget);
    expect(jsonDecode(prefs.getString('settings.v2')!)['guest'], true);
    // Reciting needs an account: the sign-in is right there.
    expect(find.text(s.guestReciteTitle), findsOneWidget);
    expect(find.byType(GoogleButton), findsOneWidget);

    // The surah list, with a way back.
    await tap(tester, s.navQuran);
    expect(find.byType(SurahIndexScreen), findsOneWidget);
    await tester.tap(find.byType(BackPill));
    await tester.pumpAndSettle();
    expect(find.byType(GuestHomeScreen), findsOneWidget);

    // Settings has no profile or sign-out for a guest.
    await tester.ensureVisible(find.byType(SettingsChip, skipOffstage: false));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SettingsChip));
    await tester.pumpAndSettle();
    expect(find.text(s.changeName), findsNothing);
    expect(find.text(s.signOut), findsNothing);
    expect(find.text(s.textSizeL), findsOneWidget);

    // Opening Sanadi again goes straight to the guest home.
    expect(nextStep(container.read(settingsProvider)), Routes.guest);
  });

  testWidgets('settings shows which Google account to use on a new phone', (tester) async {
    await startApp(
      tester,
      prefs: {'settings.v2': userSettings(teacherStatus: null)},
      overrides: [backendProvider.overrideWithValue(_Signed())],
    );
    routerOf(tester).push(Routes.settings);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('amal.hassan@gmail.com'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text(s.googleAccountL), findsOneWidget);
    expect(find.text(s.googleAccountHint), findsOneWidget);
  });
}
