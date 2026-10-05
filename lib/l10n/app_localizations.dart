import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Sanadi'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Recite the Quran to a teacher, anytime.'**
  String get appTagline;

  /// No description provided for @chooseLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseLanguageTitle;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get terms;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @comingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'This part of Sanadi is still being built, in shaa Allah.'**
  String get comingSoonBody;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @roleQuestion.
  ///
  /// In en, this message translates to:
  /// **'I want to…'**
  String get roleQuestion;

  /// No description provided for @roleStudent.
  ///
  /// In en, this message translates to:
  /// **'Memorise and recite'**
  String get roleStudent;

  /// No description provided for @roleStudentHint.
  ///
  /// In en, this message translates to:
  /// **'Recite to a teacher and track your progress'**
  String get roleStudentHint;

  /// No description provided for @roleTeacher.
  ///
  /// In en, this message translates to:
  /// **'Teach as a volunteer'**
  String get roleTeacher;

  /// No description provided for @roleTeacherHint.
  ///
  /// In en, this message translates to:
  /// **'Listen to students and help them memorise'**
  String get roleTeacherHint;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'As-salamu alaykum, {name}'**
  String greeting(String name);

  /// No description provided for @guestName.
  ///
  /// In en, this message translates to:
  /// **'dear guest'**
  String get guestName;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabQuran.
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get tabQuran;

  /// No description provided for @tabAthkar.
  ///
  /// In en, this message translates to:
  /// **'Athkar'**
  String get tabAthkar;

  /// No description provided for @tabMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get tabMessages;

  /// No description provided for @tabStudents.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get tabStudents;

  /// No description provided for @reciteNow.
  ///
  /// In en, this message translates to:
  /// **'Recite now'**
  String get reciteNow;

  /// No description provided for @teachersAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No teachers online right now} =1{1 teacher available now} other{{count} teachers available now}}'**
  String teachersAvailable(int count);

  /// No description provided for @nextPortionTitle.
  ///
  /// In en, this message translates to:
  /// **'Your next portion'**
  String get nextPortionTitle;

  /// No description provided for @nextPortionEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your teacher will set your next portion after your first session.'**
  String get nextPortionEmpty;

  /// No description provided for @openInQuran.
  ///
  /// In en, this message translates to:
  /// **'Open in Quran'**
  String get openInQuran;

  /// No description provided for @myTeacherTitle.
  ///
  /// In en, this message translates to:
  /// **'My teacher'**
  String get myTeacherTitle;

  /// No description provided for @myTeacherEmpty.
  ///
  /// In en, this message translates to:
  /// **'After your first session, your teacher will appear here.'**
  String get myTeacherEmpty;

  /// No description provided for @availableToTeach.
  ///
  /// In en, this message translates to:
  /// **'You are available to teach'**
  String get availableToTeach;

  /// No description provided for @away.
  ///
  /// In en, this message translates to:
  /// **'You are away'**
  String get away;

  /// No description provided for @availabilityHint.
  ///
  /// In en, this message translates to:
  /// **'Students can call you while this is on.'**
  String get availabilityHint;

  /// No description provided for @todayStats.
  ///
  /// In en, this message translates to:
  /// **'Today: {sessions} sessions · {minutes} minutes'**
  String todayStats(int sessions, int minutes);

  /// No description provided for @studentsWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No students waiting} =1{1 student is waiting for a teacher} other{{count} students are waiting for a teacher}}'**
  String studentsWaiting(int count);

  /// No description provided for @athkarTitle.
  ///
  /// In en, this message translates to:
  /// **'Athkar'**
  String get athkarTitle;

  /// No description provided for @athkarMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get athkarMorning;

  /// No description provided for @athkarEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get athkarEvening;

  /// No description provided for @athkarAfterSalah.
  ///
  /// In en, this message translates to:
  /// **'After salah'**
  String get athkarAfterSalah;

  /// No description provided for @athkarTasbeeh.
  ///
  /// In en, this message translates to:
  /// **'Tasbeeh'**
  String get athkarTasbeeh;

  /// No description provided for @athkarSleep.
  ///
  /// In en, this message translates to:
  /// **'Before sleep'**
  String get athkarSleep;

  /// No description provided for @athkarWaking.
  ///
  /// In en, this message translates to:
  /// **'On waking'**
  String get athkarWaking;

  /// No description provided for @quranTitle.
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get quranTitle;

  /// No description provided for @quranPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'The mushaf will be here: read page by page, listen, and open your next portion.'**
  String get quranPlaceholder;

  /// No description provided for @messagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messagesTitle;

  /// No description provided for @messagesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No messages yet. After your first session you can message your teacher here.'**
  String get messagesEmpty;

  /// No description provided for @studentsTitle.
  ///
  /// In en, this message translates to:
  /// **'My students'**
  String get studentsTitle;

  /// No description provided for @studentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Students you teach will appear here with their progress.'**
  String get studentsEmpty;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsTextSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get settingsTextSize;

  /// No description provided for @settingsTextSizeHint.
  ///
  /// In en, this message translates to:
  /// **'Sanadi follows your phone\'s text size. Change it in your phone\'s Settings → Display → Font size.'**
  String get settingsTextSizeHint;

  /// No description provided for @settingsPreviewRole.
  ///
  /// In en, this message translates to:
  /// **'Preview mode'**
  String get settingsPreviewRole;

  /// No description provided for @settingsPreviewRoleHint.
  ///
  /// In en, this message translates to:
  /// **'For testing only: switch between the student and teacher apps.'**
  String get settingsPreviewRoleHint;

  /// No description provided for @settingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsSignOut;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsVersion(String version);

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile and settings'**
  String get profile;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
