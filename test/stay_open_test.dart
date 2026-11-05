import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanadi/core/router.dart';
import 'package:sanadi/features/quran/quran_data.dart';

import 'helpers.dart';

/// Sanadi never closes, and the screen never goes dark, in the middle of
/// what an elderly user is doing.
void main() {
  setUpAll(loadAppFonts);

  /// What Sanadi asked of the phone's screen and window, in order.
  List<MethodCall> watchScreen(WidgetTester tester) {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('sanadi/screen'), (c) async {
      calls.add(c);
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('sanadi/screen'), null),
    );
    return calls;
  }

  testWidgets('Back on another tab goes Home; Back on Home keeps Sanadi running', (tester) async {
    final screen = watchScreen(tester);
    await startApp(tester, prefs: {'settings.v2': userSettings()});
    final router = routerOf(tester);
    router.go(Routes.studentAthkar);
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(router.state.uri.path, Routes.studentHome);
    // Home: not closed, just sent to the background like the Home button.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(router.state.uri.path, Routes.studentHome);
    expect(screen.where((c) => c.method == 'moveToBack'), hasLength(1));
  });

  testWidgets('the screen stays on while the mushaf is open, and sleeps again after', (tester) async {
    final screen = watchScreen(tester);
    final quran = testQuran;
    await startApp(
      tester,
      prefs: {'settings.v2': userSettings()},
      overrides: [quranProvider.overrideWith((ref) async => quran)],
    );
    final router = routerOf(tester);
    router.push(Routes.mushaf);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(screen.where((c) => c.method == 'keepOn').last.arguments, isTrue);
    // Minutes on one page: still on.
    await tester.pump(const Duration(minutes: 5));
    expect(screen.where((c) => c.method == 'keepOn').last.arguments, isTrue);
    router.pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(screen.where((c) => c.method == 'keepOn').last.arguments, isFalse);
  });
}
