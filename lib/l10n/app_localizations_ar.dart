// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'سَنَدي';

  @override
  String get appTagline => 'اقرأ القرآن على معلّمك في أي وقت.';

  @override
  String get chooseLanguageTitle => 'اختر لغتك';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get continueWithGoogle => 'المتابعة بحساب Google';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get terms => 'الشروط';

  @override
  String get back => 'رجوع';

  @override
  String get next => 'التالي';

  @override
  String get comingSoon => 'قريبًا';

  @override
  String get comingSoonBody => 'هذا الجزء من سَنَدي قيد الإنشاء، إن شاء الله.';

  @override
  String get ok => 'حسنًا';

  @override
  String get roleQuestion => 'أريد أن…';

  @override
  String get roleStudent => 'أحفظ وأُسمِّع';

  @override
  String get roleStudentHint => 'سمِّع على معلّم وتابع تقدّمك';

  @override
  String get roleTeacher => 'أعلّم متطوّعًا';

  @override
  String get roleTeacherHint => 'استمع إلى الطلاب وساعدهم على الحفظ';

  @override
  String greeting(String name) {
    return 'السلام عليكم، $name';
  }

  @override
  String get guestName => 'ضيفنا العزيز';

  @override
  String get tabHome => 'الرئيسية';

  @override
  String get tabQuran => 'المصحف';

  @override
  String get tabAthkar => 'الأذكار';

  @override
  String get tabMessages => 'الرسائل';

  @override
  String get tabStudents => 'طلابي';

  @override
  String get reciteNow => 'سمِّع الآن';

  @override
  String teachersAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count معلّم متاح الآن',
      many: '$count معلّمًا متاحًا الآن',
      few: '$count معلّمين متاحون الآن',
      two: 'معلّمان متاحان الآن',
      one: 'معلّم واحد متاح الآن',
      zero: 'لا يوجد معلّمون متاحون الآن',
    );
    return '$_temp0';
  }

  @override
  String get nextPortionTitle => 'وِردك القادم';

  @override
  String get nextPortionEmpty => 'سيحدّد معلّمك وِردك القادم بعد أول جلسة.';

  @override
  String get openInQuran => 'افتح في المصحف';

  @override
  String get myTeacherTitle => 'معلّمي';

  @override
  String get myTeacherEmpty => 'بعد أول جلسة سيظهر معلّمك هنا.';

  @override
  String get availableToTeach => 'أنت متاح للتعليم';

  @override
  String get away => 'أنت غير متاح';

  @override
  String get availabilityHint => 'يمكن للطلاب الاتصال بك ما دام هذا مفعّلًا.';

  @override
  String todayStats(int sessions, int minutes) {
    return 'اليوم: $sessions جلسات · $minutes دقيقة';
  }

  @override
  String studentsWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count طالب ينتظرون معلّمًا',
      many: '$count طالبًا ينتظرون معلّمًا',
      few: '$count طلاب ينتظرون معلّمًا',
      two: 'طالبان ينتظران معلّمًا',
      one: 'طالب واحد ينتظر معلّمًا',
      zero: 'لا يوجد طلاب في الانتظار',
    );
    return '$_temp0';
  }

  @override
  String get athkarTitle => 'الأذكار';

  @override
  String get athkarMorning => 'أذكار الصباح';

  @override
  String get athkarEvening => 'أذكار المساء';

  @override
  String get athkarAfterSalah => 'أذكار بعد الصلاة';

  @override
  String get athkarTasbeeh => 'تسابيح';

  @override
  String get athkarSleep => 'أذكار النوم';

  @override
  String get athkarWaking => 'أذكار الاستيقاظ';

  @override
  String get quranTitle => 'المصحف';

  @override
  String get quranPlaceholder =>
      'سيكون المصحف هنا: القراءة صفحةً صفحة، والاستماع، وفتح وِردك القادم.';

  @override
  String get messagesTitle => 'الرسائل';

  @override
  String get messagesEmpty =>
      'لا توجد رسائل بعد. بعد أول جلسة يمكنك مراسلة معلّمك من هنا.';

  @override
  String get studentsTitle => 'طلابي';

  @override
  String get studentsEmpty => 'سيظهر هنا الطلاب الذين تعلّمهم مع تقدّمهم.';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsTextSize => 'حجم الخط';

  @override
  String get settingsTextSizeHint =>
      'يتبع سَنَدي حجم الخط في هاتفك. غيّره من إعدادات الهاتف ← الشاشة ← حجم الخط.';

  @override
  String get settingsPreviewRole => 'وضع المعاينة';

  @override
  String get settingsPreviewRoleHint =>
      'للتجربة فقط: التبديل بين تطبيق الطالب وتطبيق المعلّم.';

  @override
  String get settingsSignOut => 'تسجيل الخروج';

  @override
  String settingsVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String get profile => 'الملف الشخصي والإعدادات';
}
