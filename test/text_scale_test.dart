import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sanadi/app.dart';
import 'package:sanadi/backend/backend.dart';
import 'package:sanadi/core/router.dart';
import 'package:sanadi/core/settings.dart';
import 'package:sanadi/core/connectivity.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Material arrows and chevrons that mirror in right-to-left languages.
final _arrowCodes = {
  Icons.arrow_back_rounded.codePoint,
  Icons.arrow_forward_rounded.codePoint,
  Icons.chevron_left_rounded.codePoint,
  Icons.chevron_right_rounded.codePoint,
  Icons.arrow_back.codePoint,
  Icons.arrow_forward.codePoint,
};

final _letter = RegExp(r'\p{L}', unicode: true);

/// Words that a text block splits across two lines (e.g. "Mess-age").
/// Line breaks between words are fine; inside a word they are not.
List<String> brokenWords(WidgetTester tester) {
  final out = <String>[];
  void visit(RenderObject r) {
    if (r is RenderParagraph && r.softWrap && r.hasSize) {
      final text = r.text.toPlainText();
      // Lay the same text out again at the same width to read its lines.
      final tp = TextPainter(
        text: r.text,
        textDirection: r.textDirection,
        textScaler: r.textScaler,
        textAlign: r.textAlign,
        maxLines: r.maxLines,
      )..layout(maxWidth: r.size.width + 0.5);
      var pos = 0;
      while (pos < text.length) {
        final line = tp.getLineBoundary(TextPosition(offset: pos));
        final end = line.end;
        if (end <= pos) break;
        if (end < text.length && end > 0 && _letter.hasMatch(text[end - 1]) && _letter.hasMatch(text[end])) {
          final a = text.lastIndexOf(RegExp(r'\s'), end - 1) + 1;
          var b = text.indexOf(RegExp(r'\s'), end);
          if (b < 0) b = text.length;
          out.add(text.substring(a, b));
        }
        pos = end;
      }
      tp.dispose();
    }
    r.visitChildren(visit);
  }

  for (final e in find.byType(Scaffold).evaluate()) {
    final ro = e.renderObject;
    if (ro != null) visit(ro);
  }
  return out;
}

/// Opens every screen at 100% and 200% text, in English and Arabic, on a
/// 360x800 phone. Any layout overflow fails the test.
Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(rootBundle.load(f));
  }
  await loader.load();
}

void main() {
  // Real fonts, so text measures as it does on a phone.
  setUpAll(() async {
    await _loadFont('Tajawal', ['assets/fonts/Tajawal-Medium.ttf', 'assets/fonts/Tajawal-Bold.ttf']);
    await _loadFont('Montserrat', ['assets/fonts/Montserrat-Medium.ttf', 'assets/fonts/Montserrat-Bold.ttf']);
    await _loadFont('NotoNaskhArabic', [
      'assets/fonts/NotoNaskhArabic-Regular.ttf',
      'assets/fonts/NotoNaskhArabic-Medium.ttf',
      'assets/fonts/NotoNaskhArabic-Bold.ttf',
    ]);
    await _loadFont('KFGQPC', ['assets/fonts/quran/UthmanicHafs1Ver18.ttf']);
  });

  final student = [
    Routes.studentHome,
    Routes.studentQuran,
    Routes.studentAthkar,
    Routes.studentMessages,
    '${Routes.athkar}/morning',
    '${Routes.athkar}/tasbeeh',
    Routes.progress,
    Routes.teacherNotes,
    Routes.connecting,
    Routes.inCall,
    '${Routes.studentEnded}?s=600',
    Routes.settings,
    Routes.mushafAt(sura: 67, ayah: 1),
    Routes.welcome,
    Routes.role,
    Routes.gender,
    Routes.name,
    Routes.permMic,
    Routes.permNotif,
    '/perm-denied/mic',
    Routes.tour,
  ];
  const teacher = [
    Routes.teacherHome,
    Routes.teacherStudents,
    Routes.incoming,
    '${Routes.inCall}?teacher=1',
    '${Routes.teacherEnded}?s=600',
    Routes.notesForm,
    Routes.permFullScreen,
    '${Routes.apply}/1',
    '${Routes.apply}/2',
    '${Routes.apply}/3',
    '${Routes.apply}/4',
    '${Routes.apply}/5',
    Routes.applySent,
    Routes.admin,
  ];

  for (final locale in ['en', 'ar']) {
    for (final scale in [1.0, 2.0]) {
      for (final (role, paths) in [('student', student), ('teacher', teacher)]) {
        testWidgets('$role screens fit: $locale at ${(scale * 100).round()}%', (tester) async {
          tester.view.physicalSize = const Size(1080, 2400);
          tester.view.devicePixelRatio = 3;
          // Names that don't fit would otherwise scroll (marquee) forever.
          tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
            disableAnimations: true,
          );
          addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

          SharedPreferences.setMockInitialValues({
            'settings.v2':
                '{"locale":"$locale","signedIn":true,"role":"$role","gender":"female",'
                '"name":"Fatima Ahmed","permissionsDone":true,"tourDone":true,"teacherStatus":"approved","sessions":2}',
          });
          final prefs = await SharedPreferences.getInstance();
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                sharedPreferencesProvider.overrideWithValue(prefs),
                onlineCheckProvider.overrideWithValue(() async => true),
                pendingApplicationsProvider.overrideWith((ref) => Stream.value([_sampleApplication])),
              ],
              child: const SanadiApp(),
            ),
          );
          await tester.pump(const Duration(milliseconds: 1400));
          await tester.pump(const Duration(milliseconds: 500));

          final context = tester.element(find.byType(Navigator).first);
          final router = GoRouter.of(context);
          for (final path in paths) {
            router.go(path);
            await tester.pump();
            await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
            await tester.pump(const Duration(milliseconds: 400));
            await tester.pump(const Duration(milliseconds: 400));
            expect(tester.takeException(), isNull, reason: path);
            // App rule: arrows never flip with the language (→ proceed, ← back).
            final flipping = find.byWidgetPredicate(
              (w) => w is Icon && (w.icon?.matchTextDirection ?? false) && _arrowCodes.contains(w.icon!.codePoint),
            );
            expect(flipping, findsNothing, reason: '$path: arrow that flips in Arabic');
            final broken = brokenWords(tester);
            expect(broken, isEmpty, reason: '$path: words split across lines');
          }
          // Leave no pending timers behind.
          router.go(role == 'student' ? Routes.studentMessages : Routes.teacherStudents);
          await tester.pump(const Duration(seconds: 6));
        });
      }
    }
  }
}

const _sampleApplication = TeacherApplication(
  uid: 'u1',
  name: 'Khadijah Abdulrahman Al-Hashimi',
  gender: Gender.female,
  answers: {
    'Country': 'South Africa',
    'Languages': 'Arabic, English, Urdu',
    'Can teach': 'Tajweed, Memorisation, Recitation',
    'Memorised': 'The whole Quran',
    'Ijazah / teachers': 'Ijazah in Hafs from Shaykhah Maryam, Cape Town',
  },
);
