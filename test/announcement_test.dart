import 'package:flutter_test/flutter_test.dart';
import 'package:sanadi/backend/admin.dart';
import 'package:sanadi/backend/backend.dart';
import 'package:sanadi/core/strings.dart';
import 'package:sanadi/features/shell/announcement_card.dart';

import 'helpers.dart';

/// A demo server with the admins' announcements, counting "active" stamps.
class _Server extends DemoBackend {
  _Server(this.list);

  final List<Announcement> list;
  int stamps = 0;

  @override
  Stream<List<Announcement>> announcements() => Stream.value(list);

  @override
  Future<void> markActive() async => stamps++;
}

/// Announcements from the admin portal on the home screen, and noting that
/// someone opened the app today.
void main() {
  const s = S(ar: false, female: true);
  final now = DateTime.now();
  final list = [
    const Announcement(id: 'teachers', textEn: 'Teachers only', audience: 'teacher'),
    Announcement(id: 'old', textEn: 'Already over', until: now.subtract(const Duration(days: 1))),
    const Announcement(id: 'ar-only', textAr: 'رمضان مبارك'),
    const Announcement(id: 'all', textEn: 'Ramadan Mubarak!', textAr: 'رمضان مبارك'),
  ];

  setUpAll(loadAppFonts);

  test('the text is in the person\'s language, or the other one', () {
    expect(list[3].text(ar: true), 'رمضان مبارك');
    expect(list[2].text(ar: false), 'رمضان مبارك');
    expect(list[0].showsTo(null, now), isFalse);
  });

  testWidgets('a student sees the newest one meant for them, until they close it', (tester) async {
    final server = _Server(list);
    final (_, prefs) = await startApp(
      tester,
      prefs: {'settings.v2': userSettings(teacherStatus: null)},
      overrides: [backendProvider.overrideWithValue(server)],
    );
    await tester.pump();
    expect(find.byType(AnnouncementCard), findsOneWidget);
    // Not the teachers' one or the expired one; the Arabic-only one shows in
    // Arabic for an English reader rather than not at all.
    expect(find.text('Teachers only'), findsNothing);
    expect(find.text('Already over'), findsNothing);
    expect(find.text(s.announcementL), findsOneWidget);
    expect(find.text('رمضان مبارك'), findsOneWidget);

    await tester.tap(find.byTooltip(s.close));
    await tester.pumpAndSettle();
    expect(find.text('Ramadan Mubarak!'), findsOneWidget);
    await tester.tap(find.byTooltip(s.close));
    await tester.pumpAndSettle();
    expect(find.text(s.announcementL), findsNothing);
    expect(prefs.getStringList('dismissedAnnouncements'), ['all', 'ar-only']);

    // Opening the app noted them as active, once today.
    expect(server.stamps, 1);
    expect(prefs.getString('lastActiveDay'), now.toIso8601String().substring(0, 10));
  });

  testWidgets('a teacher sees the teachers\' announcement; no second stamp the same day', (tester) async {
    final server = _Server(list);
    await startApp(
      tester,
      prefs: {
        'settings.v2': userSettings(role: 'teacher'),
        'lastActiveDay': now.toIso8601String().substring(0, 10),
        'dismissedAnnouncements': ['ar-only', 'all'],
      },
      overrides: [backendProvider.overrideWithValue(server)],
    );
    await tester.pump();
    expect(find.text('Teachers only'), findsOneWidget);
    expect(server.stamps, 0);
  });
}
