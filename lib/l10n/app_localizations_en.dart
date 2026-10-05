// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Sanadi';

  @override
  String get appTagline => 'Recite the Quran to a teacher, anytime.';

  @override
  String get chooseLanguageTitle => 'Choose your language';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get terms => 'Terms';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get comingSoonBody =>
      'This part of Sanadi is still being built, in shaa Allah.';

  @override
  String get ok => 'OK';

  @override
  String get roleQuestion => 'I want to…';

  @override
  String get roleStudent => 'Memorise and recite';

  @override
  String get roleStudentHint => 'Recite to a teacher and track your progress';

  @override
  String get roleTeacher => 'Teach as a volunteer';

  @override
  String get roleTeacherHint => 'Listen to students and help them memorise';

  @override
  String greeting(String name) {
    return 'As-salamu alaykum, $name';
  }

  @override
  String get guestName => 'dear guest';

  @override
  String get tabHome => 'Home';

  @override
  String get tabQuran => 'Quran';

  @override
  String get tabAthkar => 'Athkar';

  @override
  String get tabMessages => 'Messages';

  @override
  String get tabStudents => 'Students';

  @override
  String get reciteNow => 'Recite now';

  @override
  String teachersAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count teachers available now',
      one: '1 teacher available now',
      zero: 'No teachers online right now',
    );
    return '$_temp0';
  }

  @override
  String get nextPortionTitle => 'Your next portion';

  @override
  String get nextPortionEmpty =>
      'Your teacher will set your next portion after your first session.';

  @override
  String get openInQuran => 'Open in Quran';

  @override
  String get myTeacherTitle => 'My teacher';

  @override
  String get myTeacherEmpty =>
      'After your first session, your teacher will appear here.';

  @override
  String get availableToTeach => 'You are available to teach';

  @override
  String get away => 'You are away';

  @override
  String get availabilityHint => 'Students can call you while this is on.';

  @override
  String todayStats(int sessions, int minutes) {
    return 'Today: $sessions sessions · $minutes minutes';
  }

  @override
  String studentsWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count students are waiting for a teacher',
      one: '1 student is waiting for a teacher',
      zero: 'No students waiting',
    );
    return '$_temp0';
  }

  @override
  String get athkarTitle => 'Athkar';

  @override
  String get athkarMorning => 'Morning';

  @override
  String get athkarEvening => 'Evening';

  @override
  String get athkarAfterSalah => 'After salah';

  @override
  String get athkarTasbeeh => 'Tasbeeh';

  @override
  String get athkarSleep => 'Before sleep';

  @override
  String get athkarWaking => 'On waking';

  @override
  String get quranTitle => 'Quran';

  @override
  String get quranPlaceholder =>
      'The mushaf will be here: read page by page, listen, and open your next portion.';

  @override
  String get messagesTitle => 'Messages';

  @override
  String get messagesEmpty =>
      'No messages yet. After your first session you can message your teacher here.';

  @override
  String get studentsTitle => 'My students';

  @override
  String get studentsEmpty =>
      'Students you teach will appear here with their progress.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsTextSize => 'Text size';

  @override
  String get settingsTextSizeHint =>
      'Sanadi follows your phone\'s text size. Change it in your phone\'s Settings → Display → Font size.';

  @override
  String get settingsPreviewRole => 'Preview mode';

  @override
  String get settingsPreviewRoleHint =>
      'For testing only: switch between the student and teacher apps.';

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get profile => 'Profile and settings';
}
