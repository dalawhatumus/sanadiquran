import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sanadi/app.dart';
import 'package:sanadi/backend/backend.dart';
import 'package:sanadi/backend/photos.dart';
import 'package:sanadi/core/connectivity.dart';
import 'package:sanadi/core/router.dart';
import 'package:sanadi/core/settings.dart';
import 'package:sanadi/core/strings.dart';
import 'package:sanadi/features/admin/users_screen.dart';
import 'package:sanadi/features/onboarding/details_screen.dart';
import 'package:sanadi/widgets/avatars.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The details given when signing up (changed from Settings), a person's
/// own photo, and what admins see of them.
void main() {
  // A 1×1 PNG.
  final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
  );
  const s = S(ar: false, female: true);

  Future<(ProviderContainer, GoRouter)> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    SharedPreferences.setMockInitialValues({
      'settings.v2':
          '{"locale":"en","signedIn":true,"role":"student","gender":"female","name":"Fatima",'
          '"permissionsDone":true,"ageGroup":"25-34","nationality":"SA","phone":"+966500000001","tourDone":true,"sessions":2}',
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        onlineCheckProvider.overrideWithValue(() async => true),
        photoPickerProvider.overrideWithValue(({required camera}) async => png),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const SanadiApp()));
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pumpAndSettle();
    return (container, GoRouter.of(tester.element(find.byType(Navigator).first)));
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(text).first);
    await tester.pumpAndSettle();
  }

  testWidgets('details are changed from Settings', (tester) async {
    final (container, router) = await open(tester);
    router.push(Routes.settings);
    await tester.pumpAndSettle();
    await tapText(tester, s.yourDetails);
    expect(find.byType(DetailsScreen), findsOneWidget);
    // What was given before is filled in.
    expect(find.text('Saudi Arabia'), findsOneWidget);
    expect(find.text('+966'), findsOneWidget);
    expect(find.widgetWithText(TextField, '500000001'), findsOneWidget);

    await tapText(tester, '35–44');
    await tester.ensureVisible(find.byKey(const ValueKey('dial')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('dial')));
    await tester.pumpAndSettle();
    await tester.enterText(find.descendant(of: find.byType(BottomSheet), matching: find.byType(TextField)), '20');
    await tester.pumpAndSettle();
    await tapText(tester, 'Egypt');
    expect(find.text('+20'), findsOneWidget);
    // A Saudi number doesn't fit Egypt's code.
    await tester.enterText(find.byKey(const ValueKey('phone')), '1');
    await tapText(tester, s.save);
    expect(find.text(s.phoneInvalid), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('phone')), '010 1234 5678');
    await tapText(tester, s.save);
    expect(find.byType(DetailsScreen), findsNothing);
    final st = container.read(settingsProvider);
    expect((st.ageGroup, st.nationality, st.phone, st.whatsapp), ('35-44', 'SA', '+201012345678', false));
  });

  testWidgets('an own photo is saved and shown, and removed again', (tester) async {
    final (container, router) = await open(tester);
    router.push(Routes.settings);
    await tester.pumpAndSettle();
    await tapText(tester, s.changePicture);
    await tester.tap(find.byKey(const ValueKey('own-photo')));
    await tester.pumpAndSettle();
    expect(find.text(s.photoRules), findsOneWidget);
    await tapText(tester, s.choosePhoto);
    final avatar = container.read(settingsProvider).avatar;
    expect(photoOwner(avatar), 'demo');
    expect(await container.read(backendProvider).photo('demo'), png);
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsWidgets);

    // Back to initials: the photo is deleted from the server too.
    await tapText(tester, s.changePicture);
    await tester.tap(find.bySemanticsLabel(s.useInitials));
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).avatar, isNull);
    expect(await container.read(backendProvider).photo('demo'), isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('admins see details and copy the WhatsApp numbers', (tester) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied.add((call.arguments as Map)['text'] as String);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    final (_, router) = await open(tester);
    router.push(Routes.adminUsers);
    await tester.pumpAndSettle();
    Finder inList(String text) => find.descendant(of: find.byType(UsersScreen), matching: find.text(text));
    expect(inList('Aisha Rahman'), findsOneWidget);
    await tapText(tester, s.whatsappMember);
    expect(inList('Aisha Rahman'), findsNothing);
    expect(inList('Fatima'), findsOneWidget);
    await tapText(tester, s.copyNumbers);
    expect(copied, ['+966500000001']);

    await tapText(tester, 'Fatima');
    expect(find.text('25–34'), findsOneWidget);
    expect(find.textContaining('Saudi Arabia'), findsOneWidget);
    expect(find.textContaining('+966500000001'), findsOneWidget);
    expect(find.text(s.yes), findsOneWidget);
    expect(find.text(s.removePhoto), findsNothing); // no own photo
  });
}
