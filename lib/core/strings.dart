import 'package:flutter/widgets.dart';

import 'settings.dart';

part 'strings/onboarding.dart';
part 'strings/home.dart';
part 'strings/calls.dart';
part 'strings/lessons.dart';
part 'strings/quran.dart';
part 'strings/messages.dart';
part 'strings/settings.dart';
part 'strings/legal.dart';
part 'strings/admin.dart';

/// All user-facing text, in English and gender-aware Arabic. The common
/// words are here; each area's text is in its own file under `strings/`, as
/// an extension (so it is used the same way: `S.of(context).name`).
///
/// Arabic is written for the user's gender: [g] picks the feminine or
/// masculine form. Because teachers are matched by gender, the teacher's
/// gender is always the same as the user's. Before the gender step,
/// onboarding uses neutral Arabic.
class S {
  const S({required this.ar, required this.female});

  final bool ar;
  final bool female;

  /// English, then Arabic feminine, then Arabic masculine (if different).
  String t(String en, String arF, [String? arM]) => ar ? (female || arM == null ? arF : arM) : en;

  /// Picks a gendered form inside Arabic-only text.
  String g(String f, String m) => female ? f : m;

  /// Arabic-Indic digits in Arabic.
  String n(Object x) {
    final s = '$x';
    if (!ar) return s;
    const d = '٠١٢٣٤٥٦٧٨٩';
    return s.replaceAllMapped(RegExp(r'\d'), (m) => d[int.parse(m[0]!)]);
  }

  static S of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<StringsScope>()!.s;

  // ---- Sample people for this test build (replaced by real accounts) ----
  String get teacherName => t(g('Ustadha Aisha', 'Ustadh Yusuf'), 'الأستاذة عائشة', 'الأستاذ يوسف');
  String get teacherInitials => ar ? g('ع', 'ي') : g('AY', 'YU');
  String get studentName => t(g('Fatima Ahmed', 'Ahmad Ali'), 'فاطمة أحمد', 'أحمد علي');
  String get studentShort => t(g('Fatima', 'Ahmad'), 'فاطمة', 'أحمد');
  String get studentInitial => ar ? g('ف', 'أ') : g('F', 'A');

  // ---- Common ----
  String get back => t('Back', 'رجوع');
  String get next => t('Next', 'التالي');
  String get cont => t('Continue', 'متابعة');
  String get cancel => t('Cancel', 'إلغاء');
  String get close => t('Close', 'إغلاق');
  String get done => t('Done', 'تمّ');
  String get ok => t('OK', 'حسنًا');
  String get change => t('Change', 'تغيير');
  String get settings => t('Settings', 'الإعدادات');
  String get tryAgain => t('Try again', 'المحاولة مرة أخرى');
  String stepOf(int a, int b) => t('Step $a of $b', 'الخطوة ${n(a)} من ${n(b)}');
  String get reportProblem => t('Report a problem', 'الإبلاغ عن مشكلة');
  String mmss(int sec) => n(_mmss(sec));

  // ---- Navigation ----
  String get navHome => t('Home', 'الرئيسية');
  String get navQuran => t('Quran', 'المصحف');
  String get navAthkar => t('Athkar', 'الأذكار');
  String get navMessages => t('Messages', 'الرسائل');
  String get navTeachers => t('Teachers', 'المعلّمات', 'المعلّمون');
  String get navStudents => t('Students', 'الطلاب');

  // ---- 2 Language ----
  // Shown in both languages at once, so these are fixed.
  static const chooseLanguageAr = 'اختيار اللغة';
  static const chooseLanguageEn = 'Choose your language';
  static const continueBoth = 'Continue · متابعة';

  static String _mmss(int sec) => '${sec ~/ 60}:${(sec % 60).toString().padLeft(2, '0')}';
}

class StringsScope extends InheritedWidget {
  const StringsScope({super.key, required this.s, required super.child});

  final S s;

  @override
  bool updateShouldNotify(StringsScope old) => old.s.ar != s.ar || old.s.female != s.female;

  static S fromSettings(AppSettings settings, Locale locale) =>
      S(ar: locale.languageCode == 'ar', female: settings.female);
}
