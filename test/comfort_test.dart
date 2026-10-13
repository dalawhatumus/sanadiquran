import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sanadi/app.dart';
import 'package:sanadi/backend/backend.dart';
import 'package:sanadi/backend/chat.dart';
import 'package:sanadi/backend/sessions.dart';
import 'package:sanadi/core/connectivity.dart';
import 'package:sanadi/core/reminders.dart';
import 'package:sanadi/core/router.dart';
import 'package:sanadi/core/settings.dart';
import 'package:sanadi/core/strings.dart';
import 'package:sanadi/core/text_size.dart';
import 'package:sanadi/features/messages/message_alerts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A demo server whose conversation list the test controls.
class _Server extends DemoBackend {
  final convs = StreamController<List<Conversation>>.broadcast();

  @override
  Stream<List<Conversation>> conversations() => convs.stream;
}

Conversation _conv(int unread, {String text = 'Assalamu alaykum', int? voice}) => Conversation(
  id: 's1_t1',
  otherUid: 't1',
  otherName: 'Aisha',
  otherRole: UserRole.teacher,
  lastText: text,
  lastVoiceSec: voice,
  unread: unread,
);

/// Text size, message notifications, and what a teacher knows from past
/// lessons.
void main() {
  const s = S(ar: false, female: true);

  Future<(ProviderContainer, GoRouter, SharedPreferences, List<(String, String, String)>)> open(
    WidgetTester tester, {
    Backend? backend,
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    SharedPreferences.setMockInitialValues({
      'settings.v2':
          '{"locale":"en","signedIn":true,"role":"student","gender":"female","name":"Fatima",'
          '"permissionsDone":true,"tourDone":true,"sessions":2}',
    });
    final prefs = await SharedPreferences.getInstance();
    final shown = <(String, String, String)>[];
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        onlineCheckProvider.overrideWithValue(() async => true),
        if (backend != null) backendProvider.overrideWithValue(backend),
        showMessageNotificationProvider.overrideWithValue(({
          required S s,
          required String conversationId,
          required String from,
          required String text,
        }) async {
          shown.add((conversationId, from, text));
        }),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const SanadiApp()));
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pumpAndSettle();
    return (container, GoRouter.of(tester.element(find.byType(Navigator).first)), prefs, shown);
  }

  testWidgets('text size: chosen in Settings, applied everywhere, back to the phone\'s', (tester) async {
    final (container, router, prefs, _) = await open(tester);
    router.push(Routes.settings);
    await tester.pumpAndSettle();
    double scaleOf(Finder f) => MediaQuery.textScalerOf(tester.element(f)).scale(10) / 10;
    expect(scaleOf(find.text(s.textSizePreview)), 1.0);

    final choice = find.text(s.percent(1.5));
    await tester.ensureVisible(choice);
    await tester.pumpAndSettle();
    await tester.tap(choice);
    await tester.pumpAndSettle();
    expect(container.read(textSizeProvider), 1.5);
    expect(prefs.getDouble('textScale'), 1.5);
    expect(scaleOf(find.text(s.textSizePreview)), 1.5);

    // The last "Same as phone" (the first is for the theme).
    final phone = find.text(s.textSizePhone).last;
    await tester.ensureVisible(phone);
    await tester.pumpAndSettle();
    await tester.tap(phone);
    await tester.pumpAndSettle();
    expect(container.read(textSizeProvider), isNull);
    expect(prefs.getDouble('textScale'), isNull);
    expect(scaleOf(find.text(s.textSizePreview)), 1.0);
  });

  testWidgets('messages: a notification for a new message, not for the chat on screen', (tester) async {
    final server = _Server();
    final (container, router, _, shown) = await open(tester, backend: server);
    server.convs.add([_conv(0)]);
    await tester.pumpAndSettle();
    expect(shown, isEmpty, reason: 'the first list is only the starting point');

    server.convs.add([_conv(1, text: 'See you after Asr')]);
    await tester.pumpAndSettle();
    expect(shown, [('s1_t1', 'Aisha', 'See you after Asr')]);

    server.convs.add([_conv(2, voice: 12)]);
    await tester.pumpAndSettle();
    expect(shown.last, ('s1_t1', 'Aisha', s.voiceNote));

    // Reading it (unread back to 0) shows nothing.
    server.convs.add([_conv(0)]);
    await tester.pumpAndSettle();
    expect(shown.length, 2);

    // With the chat open, a new message shows nothing.
    router.push(Routes.chat('s1_t1'));
    await tester.pumpAndSettle();
    server.convs.add([_conv(1)]);
    await tester.pumpAndSettle();
    expect(shown.length, 2);
    router.pop();
    await tester.pumpAndSettle();

    // Switched off in Settings: nothing.
    container.read(messageAlertsOnProvider.notifier).set(false);
    await tester.pumpAndSettle();
    server.convs.add([_conv(0)]);
    server.convs.add([_conv(3)]);
    await tester.pumpAndSettle();
    expect(shown.length, 2);
  });

  test('a message notification can only open a chat', () {
    expect(Reminders.safeRoute('/chat/s1_t1'), '/chat/s1_t1');
    expect(Reminders.safeRoute('/chat/AbC-12_x'), '/chat/AbC-12_x');
    for (final bad in ['/chat/', '/chat/../admin', '/chat/a/b', '/chat/a?x=1', '/chats/a']) {
      expect(Reminders.safeRoute(bad), isNull, reason: bad);
    }
  });

  test('a teacher sees the student\'s portion from their last lesson together', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(c.dispose);
    c.listen(lessonsProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    final last = c.read(lastNotesForStudentProvider('demo'));
    expect(last?.notes?.next, const Portion(67, 11, 20));
    expect(c.read(lastNotesForStudentProvider('someone-else')), isNull);
  });
}
