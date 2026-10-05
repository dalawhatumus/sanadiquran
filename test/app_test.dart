import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanadi/app.dart';
import 'package:sanadi/core/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpApp(WidgetTester tester, Map<String, Object> prefs) async {
  // A typical budget Android phone: 360x800 logical pixels.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues(prefs);
  final instance = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(instance)],
      child: const SanadiApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('first launch asks for language in both languages', (tester) async {
    await pumpApp(tester, {});
    expect(find.text('Choose your language'), findsOneWidget);
    expect(find.text('اختر لغتك'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('العربية'), findsOneWidget);
  });

  testWidgets('English onboarding reaches the student home', (tester) async {
    await pumpApp(tester, {});

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Continue with Google'), findsOneWidget);

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(find.text('I want to…'), findsOneWidget);

    await tester.tap(find.text('Memorise and recite'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Recite now'), findsOneWidget);
    for (final tab in ['Home', 'Quran', 'Athkar', 'Messages']) {
      expect(find.text(tab), findsWidgets);
    }
  });

  testWidgets('Arabic student home is right-to-left', (tester) async {
    await pumpApp(tester, {'locale': 'ar', 'role': 'student'});

    expect(find.text('سمِّع الآن'), findsOneWidget);
    final direction = Directionality.of(tester.element(find.text('سمِّع الآن')));
    expect(direction, TextDirection.rtl);
  });

  testWidgets('teacher sees the availability switch and can toggle it', (tester) async {
    await pumpApp(tester, {'locale': 'en', 'role': 'teacher'});

    expect(find.text('You are away'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('You are available to teach'), findsOneWidget);
    expect(find.text('Students'), findsWidgets);
  });

  testWidgets('athkar tab lists all six categories', (tester) async {
    await pumpApp(tester, {'locale': 'en', 'role': 'student'});

    await tester.tap(find.text('Athkar'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    for (final label in [
      'Morning',
      'Evening',
      'After salah',
      'Tasbeeh',
      'Before sleep',
      'On waking',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('layout survives 2x system text size', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpApp(tester, {'locale': 'en', 'role': 'student'});
    expect(find.text('Recite now'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
