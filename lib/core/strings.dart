import 'package:flutter/widgets.dart';

import 'settings.dart';

/// All user-facing text, in English and gender-aware Arabic.
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
  String get comingSoon => t('Coming soon, in sha Allah', 'قريبًا بإذن الله');
  String stepOf(int a, int b) => t('Step $a of $b', 'الخطوة ${n(a)} من ${n(b)}');
  String get reportProblem => t('Report a problem', 'الإبلاغ عن مشكلة');

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

  // ---- 3 Welcome ----
  String get tagline => t('Recite the Quran to a teacher, anytime.', 'سمِّع القرآن لمعلّم أو معلّمة، في أي وقت.');
  String get taglineSub => t('Free, for the sake of Allah.', 'مجانًا، لوجه الله.');
  String get continueGoogle => t('Continue with Google', 'المتابعة بحساب Google');
  String get signingIn => t('Signing in…', 'جارٍ تسجيل الدخول…');
  String get signInFailed =>
      t("We couldn't sign you in. Please try again.", 'تعذّر تسجيل الدخول. يُرجى المحاولة مرة أخرى.');
  String get noInternetLong => t(
    'No internet connection. Connect to Wi-Fi or mobile data, then try again.',
    'لا يوجد اتصال بالإنترنت. يُرجى الاتصال بشبكة Wi-Fi أو بيانات الجوال، ثم المحاولة مرة أخرى.',
  );
  String get needsNet => t('Needs internet', 'يحتاج إلى إنترنت');
  String get offlineWorks => t('The Quran and athkar work without internet.', 'المصحف والأذكار يعملان دون إنترنت.');
  String get needsInternetTitle => t('No internet', 'لا يوجد اتصال بالإنترنت');
  String get needsInternetBody => t(
    'Reciting to a teacher needs internet. The Quran and athkar still work offline.',
    'التسميع للمعلّمة يحتاج إلى إنترنت. المصحف والأذكار يعملان دون إنترنت.',
    'التسميع للمعلّم يحتاج إلى إنترنت. المصحف والأذكار يعملان دون إنترنت.',
  );
  String get privacy => t('Privacy policy', 'سياسة الخصوصية');
  String get terms => t('Terms', 'الشروط');
  String get adultsNote => t(
    'Accounts are for adults. Children can recite on a parent\'s account, with the parent nearby.',
    'الحسابات للبالغين. يمكن للأطفال القراءة من حساب وليّ الأمر وبحضوره.',
  );

  // ---- 4 Role (neutral Arabic) ----
  String get roleTitle => t('What would you like to do?', 'ما الذي يناسبك؟');
  String get roleStudent => t('Memorise and recite', 'الحفظ والتسميع');
  String get roleStudentSub => t('Recite to a teacher and see your progress', 'التسميع لمعلّم ومتابعة التقدّم');
  String get roleTeacher => t('Teach as a volunteer', 'التعليم تطوّعًا');
  String get roleTeacherSub =>
      t('Listen to students and correct their recitation', 'الاستماع إلى الطلاب وتصحيح تلاوتهم');

  // ---- 5 Gender (neutral Arabic) ----
  String get genderTitle => t('I am…', 'أنا…');
  String get male => t('Male', 'ذكر');
  String get femaleL => t('Female', 'أنثى');
  String get genderInfo => t(
    "So we can connect you with a teacher of the same gender. This can't be changed later.",
    'لنصلك بمعلّم من الجنس نفسه. لا يمكن تغيير هذا لاحقًا.',
  );

  // ---- 6 Name ----
  String get nameTitle => t('What should we call you?', 'بماذا نناديكِ؟', 'بماذا نناديك؟');
  String get nameSub => t('Your teacher will see this name.', 'سيظهر هذا الاسم لمعلّمتكِ.', 'سيظهر هذا الاسم لمعلّمك.');
  String get nameStudentSub =>
      t('Your students will see this name.', 'سيظهر هذا الاسم لطالباتكِ.', 'سيظهر هذا الاسم لطلابك.');
  String get nameLabel => t('Your name', 'اسمكِ', 'اسمك');
  String get nameHint => t(
    'From your Google account. You can change it.',
    'من حسابكِ في Google، ويمكنكِ تغييره.',
    'من حسابك في Google، ويمكنك تغييره.',
  );
  String get choosePicture => t('Choose your picture', 'اختاري صورتكِ', 'اختر صورتك');
  String get choosePictureOptional =>
      t('Choose your picture (optional)', 'اختاري صورتكِ (اختياري)', 'اختر صورتك (اختياري)');
  String get useInitials => t('Use my initial', 'استخدام الحرف الأول من اسمي');
  String pictureN(int k) => t('Picture $k', 'صورة ${n(k)}');
  String get changePicture => t('Change picture', 'تغيير الصورة');
  String get nameEmpty => t('Please write your name.', 'يُرجى كتابة اسمكِ.', 'يُرجى كتابة اسمك.');

  // ---- 7 Permissions ----
  String get notNow => t('Not now', 'ليس الآن');
  String get micTitle => t('Allow the microphone', 'السماح باستخدام الميكروفون');
  String get micBody => t(
    'So your teacher can hear you recite. On the next screen, tap Allow.',
    'لتسمعكِ معلّمتكِ وأنتِ تُسمّعين. في الشاشة التالية، اضغطي «السماح».',
    'ليسمعك معلّمك وأنت تُسمّع. في الشاشة التالية، اضغط «السماح».',
  );
  String get micBodyTeacher => t(
    'So your students can hear you. On the next screen, tap Allow.',
    'لتسمعكِ طالباتكِ. في الشاشة التالية، اضغطي «السماح».',
    'ليسمعك طلابك. في الشاشة التالية، اضغط «السماح».',
  );
  String get notifTitle => t('Allow notifications', 'السماح بالإشعارات');
  String get notifBody => t(
    'So you know when your teacher calls or messages you. On the next screen, tap Allow.',
    'لتعرفي متى تتصل بكِ معلّمتكِ أو تراسلكِ. في الشاشة التالية، اضغطي «السماح».',
    'لتعرف متى يتصل بك معلّمك أو يراسلك. في الشاشة التالية، اضغط «السماح».',
  );
  String get notifBodyTeacher => t(
    'So you know when a student calls or messages you. On the next screen, tap Allow.',
    'لتعرفي متى تتصل بكِ طالبة أو تراسلكِ. في الشاشة التالية، اضغطي «السماح».',
    'لتعرف متى يتصل بك طالب أو يراسلك. في الشاشة التالية، اضغط «السماح».',
  );
  String get teacherSetup => t('Teacher setup', 'إعداد المعلّمة', 'إعداد المعلّم');
  String get fsTitle => t('Show calls on the full screen', 'إظهار المكالمات على كامل الشاشة');
  String get fsBody => t(
    "So a student's call rings like a phone call, even when your phone is locked. On the next screen, turn on Sanadi.",
    'ليرنّ اتصال الطالبة مثل مكالمة الهاتف، حتى والهاتف مقفل. في الشاشة التالية، فعّلي سَنَدي.',
    'ليرنّ اتصال الطالب مثل مكالمة الهاتف، حتى والهاتف مقفل. في الشاشة التالية، فعّل سَنَدي.',
  );

  // ---- 8 Permission denied ----
  String get micOffTitle => t('The microphone is off', 'الميكروفون مُغلق');
  String get micOffBody => t(
    "Without it, your teacher can't hear you. You can turn it on in your phone's settings.",
    'بدونه لن تسمعكِ معلّمتكِ. يمكنكِ تشغيله من إعدادات الهاتف.',
    'بدونه لن يسمعك معلّمك. يمكنك تشغيله من إعدادات الهاتف.',
  );
  String get notifOffTitle => t('Notifications are off', 'الإشعارات متوقّفة');
  String get notifOffBody => t(
    "Without them, you won't know when someone calls or messages you. You can turn them on in your phone's settings.",
    'بدونها لن تعرفي متى يتصل بكِ أحد أو يراسلكِ. يمكنكِ تشغيلها من إعدادات الهاتف.',
    'بدونها لن تعرف متى يتصل بك أحد أو يراسلك. يمكنك تشغيلها من إعدادات الهاتف.',
  );
  String get inPhoneSettings => t('In your phone settings:', 'في إعدادات الهاتف:');
  String get deniedStep1 =>
      t('Tap Open settings below', 'اضغطي «افتحي الإعدادات» في الأسفل', 'اضغط «افتح الإعدادات» في الأسفل');
  String deniedStep2(bool mic) => mic
      ? t('Tap Permissions, then Microphone', 'اضغطي «الأذونات»، ثم «الميكروفون»', 'اضغط «الأذونات»، ثم «الميكروفون»')
      : t('Tap Notifications', 'اضغطي «الإشعارات»', 'اضغط «الإشعارات»');
  String get deniedStep3 =>
      t('Choose Allow, then come back', 'اختاري «السماح»، ثم عودي إلى هنا', 'اختر «السماح»، ثم عد إلى هنا');
  String get openSettings => t('Open settings', 'افتحي الإعدادات', 'افتح الإعدادات');
  String get turnedOn => t("I've turned it on", 'شغّلته');
  String get stillOff => t(
    "It's still off. Please follow the steps above.",
    'ما زال مُغلقًا. اتّبعي الخطوات أعلاه.',
    'ما زال مُغلقًا. اتّبع الخطوات أعلاه.',
  );

  // ---- 9 Tour ----
  String get skip => t('Skip', 'تخطّي');
  String get start => t('Start', 'ابدئي', 'ابدأ');
  String get tour1Title => t('Tap Recite now', 'اضغطي «سمِّعي الآن»', 'اضغط «سمِّع الآن»');
  String get tour1Body => t(
    "We'll call a teacher who is free. You recite on a call, just like a phone call.",
    'سنتصل لكِ بمعلّمة متاحة، وتُسمّعين في مكالمة مثل مكالمة الهاتف.',
    'سنتصل لك بمعلّم متاح، وتُسمّع في مكالمة مثل مكالمة الهاتف.',
  );
  String get tour2Title => t('See your progress', 'تابعي تقدّمكِ', 'تابع تقدّمك');
  String get tour2Body => t(
    'After each session you can see what you have memorised and your next portion.',
    'بعد كل جلسة يمكنكِ رؤية ما حفظتِه ووِردكِ القادم.',
    'بعد كل جلسة يمكنك رؤية ما حفظته ووِردك القادم.',
  );
  String get tour3Title => t('Athkar every day', 'الأذكار كل يوم');
  String get tour3Body => t(
    'Morning and evening athkar, with a counter and gentle reminders.',
    'أذكار الصباح والمساء، مع عدّاد وتذكيرات لطيفة.',
  );
  String ofN(int a, int b) => t('$a of $b', '${n(a)} من ${n(b)}');

  // ---- 10-14 Teacher application ----
  String appStep(int a) => t('Application · $a of 5', 'الطلب · ${n(a)} من ٥');
  String get appCountryTitle => t(
    'Where are you, and which languages do you speak?',
    'أين تقيمين، وما اللغات التي تتحدّثينها؟',
    'أين تقيم، وما اللغات التي تتحدّثها؟',
  );
  String get country => t('Country', 'البلد');
  List<String> get countries => ar
      ? ['جنوب أفريقيا', 'السعودية', 'لبنان', 'مصر', 'الأردن', 'المملكة المتحدة', 'بلد آخر']
      : ['South Africa', 'Saudi Arabia', 'Lebanon', 'Egypt', 'Jordan', 'United Kingdom', 'Other'];
  String get languagesL => t('Languages you speak', 'اللغات التي تتحدّثينها', 'اللغات التي تتحدّثها');
  String get chooseAll => t('Choose all that apply', 'اختاري كل ما ينطبق', 'اختر كل ما ينطبق');
  List<String> get languages => ar
      ? ['العربية', 'الإنجليزية', 'الأردية', 'الأفريكانية', 'الفرنسية', 'الملايوية']
      : ['Arabic', 'English', 'Urdu', 'Afrikaans', 'French', 'Malay'];
  String get appTeachTitle => t('What can you teach?', 'ماذا يمكنكِ أن تُعلّمي؟', 'ماذا يمكنك أن تُعلّم؟');
  List<(String, String)> get teachTypes => [
    (t('Correction', 'تصحيح التلاوة'), t('Listen and correct mistakes', 'الاستماع وتصحيح الأخطاء')),
    (
      t('Memorise & review', 'الحفظ والمراجعة'),
      t('Help students memorise new portions', 'مساعدة الطالبات على حفظ وِرد جديد', 'مساعدة الطلاب على حفظ وِرد جديد'),
    ),
    (t('Talqeen: learn to read', 'التلقين: تعلّم القراءة'), t('Read together, ayah by ayah', 'القراءة معًا، آيةً آية')),
  ];
  String get freeTitle => t('When are you usually free?', 'متى تكونين متاحة عادةً؟', 'متى تكون متاحًا عادةً؟');
  String get freeSub => t(
    'Just to help us plan. You choose each day when to be available.',
    'للتخطيط فقط، وأنتِ تختارين كل يوم متى تكونين متاحة.',
    'للتخطيط فقط، وأنت تختار كل يوم متى تكون متاحًا.',
  );
  List<String> get freeTimes => ar
      ? ['بعد الفجر', 'الصباح', 'بعد الظهر', 'بعد المغرب', 'الليل']
      : ['After Fajr', 'Morning', 'Afternoon', 'After Maghrib', 'Night'];
  String get recitationTitle => t('Your recitation', 'تلاوتكِ', 'تلاوتك');
  String get howMuch => t('How much of the Quran have you memorised?', 'كم تحفظين من القرآن؟', 'كم تحفظ من القرآن؟');
  List<String> get amounts => ar
      ? ['القرآن كاملًا', 'أكثر من ١٠ أجزاء', 'أقل من ١٠ أجزاء']
      : ['The whole Quran', 'More than 10 juz', 'Less than 10 juz'];
  String get ijazahL => t('Ijazah or qualification (optional)', 'الإجازة أو المؤهّل (اختياري)');
  String get ijazahHint => t('For example: ijazah in Hafs ʿan ʿAsim', 'مثال: إجازة برواية حفص عن عاصم');
  String get ijazahHelp =>
      t("Leave it empty if you don't have one.", 'اتركيه فارغًا إن لم يكن لديكِ.', 'اتركه فارغًا إن لم يكن لديك.');
  String get sampleTitle => t('Record a short sample', 'سجّلي مقطعًا قصيرًا', 'سجّل مقطعًا قصيرًا');
  String get sampleSub => t(
    'Recite any ayat you like, so we can hear your recitation.',
    'اقرئي ما شئتِ من الآيات لنستمع إلى تلاوتكِ.',
    'اقرأ ما شئت من الآيات لنستمع إلى تلاوتك.',
  );
  String get tapRecord => t('Tap to record', 'اضغطي للتسجيل', 'اضغط للتسجيل');
  String get tapStop => t('Tap to stop', 'اضغطي للإيقاف', 'اضغط للإيقاف');
  String get recording => t('Recording', 'جارٍ التسجيل');
  String get sampleLen => t('About 1 minute is enough (up to 2)', 'دقيقة واحدة تكفي (حتى دقيقتين)');
  String sampleLabel(String len) => t('Recitation sample · $len', 'مقطع التلاوة · ${n(len)}');
  String yourSample(String len) => t('Your sample · $len', 'مقطعكِ · ${n(len)}', 'مقطعك · ${n(len)}');
  String get recordAgain => t('Record again', 'سجّلي من جديد', 'سجّل من جديد');
  String get sendSample => t('Send sample', 'أرسلي المقطع', 'أرسل المقطع');
  String get sampleNote => t('Test build: the recording is simulated.', 'نسخة تجريبية: التسجيل للعرض فقط.');
  String get pledgeTitle => t('Our promise to students', 'عهدنا مع الطالبات', 'عهدنا مع الطلاب');
  List<String> get pledges => [
    t('I teach for the sake of Allah, and never ask for money.', 'أُعلّم لوجه الله، ولا أطلب مالًا.'),
    t(
      'I am patient and gentle, especially with older students.',
      'أصبر وأرفق، خاصة بكبيرات السن.',
      'أصبر وأرفق، خاصة بكبار السن.',
    ),
    t(
      "I keep calls about the Quran, and keep students' details private.",
      'أجعل المكالمات للقرآن، وأحفظ خصوصية الطالبات.',
      'أجعل المكالمات للقرآن، وأحفظ خصوصية الطلاب.',
    ),
    t('I follow the Sanadi code of conduct.', 'ألتزم بقواعد السلوك في سَنَدي.'),
  ];
  String get readCode => t('Read the code of conduct', 'اقرئي قواعد السلوك', 'اقرأ قواعد السلوك');
  String get iPromise => t("I promise, by Allah's permission", 'أعاهد على ذلك بإذن الله');
  String get sendApp => t('Send application', 'أرسلي الطلب', 'أرسل الطلب');
  String get jazak => t('JazakAllahu khairan', 'جزاكِ الله خيرًا', 'جزاك الله خيرًا');
  String get appSentBody => t(
    "Your application has been sent. We'll notify you when you're approved, usually within a few days. Until then, the mushaf and athkar are ready for you.",
    'أُرسل طلبكِ. سنُعلمكِ عند الموافقة، عادةً خلال أيام قليلة. وإلى حين ذلك، المصحف والأذكار بين يديكِ.',
    'أُرسل طلبك. سنُعلمك عند الموافقة، عادةً خلال أيام قليلة. وإلى حين ذلك، المصحف والأذكار بين يديك.',
  );
  String get reviewTitle => t('Your application is being reviewed', 'طلبكِ قيد المراجعة', 'طلبك قيد المراجعة');
  String get reviewBody => t(
    "We'll notify you when you're approved, usually within a few days.",
    'سنُعلمكِ عند الموافقة، عادةً خلال أيام قليلة.',
    'سنُعلمك عند الموافقة، عادةً خلال أيام قليلة.',
  );
  String get whileWait => t('While you wait', 'إلى حين ذلك');
  String get openMushaf => t('Open the mushaf', 'افتحي المصحف', 'افتح المصحف');
  String get rejectTitle =>
      t("We can't approve your application yet", 'لا يمكننا قبول طلبكِ حاليًا', 'لا يمكننا قبول طلبك حاليًا');
  String get rejectThanks => t(
    'Thank you for offering your time to teach.',
    'شكرًا لكِ على رغبتكِ في التعليم.',
    'شكرًا لك على رغبتك في التعليم.',
  );
  String get reason => t('Reason', 'السبب');
  String get rejectReason => t(
    "Your recitation sample was too short for us to listen properly. You're welcome to apply again with a sample of about a minute.",
    'كان مقطع التلاوة قصيرًا فلم نتمكّن من الاستماع إليه جيدًا. يسعدنا أن تقدّمي مجددًا بمقطع مدّته دقيقة تقريبًا.',
    'كان مقطع التلاوة قصيرًا فلم نتمكّن من الاستماع إليه جيدًا. يسعدنا أن تقدّم مجددًا بمقطع مدّته دقيقة تقريبًا.',
  );
  String get applyAgain => t('Apply again', 'قدّمي مرة أخرى', 'قدّم مرة أخرى');
  String get contactUs => t('Contact us', 'تواصلي معنا', 'تواصل معنا');

  // ---- 17 Student home ----
  String get recite => t('Recite now', 'سمِّعي الآن', 'سمِّع الآن');
  String get reciteSub => t('Tap to call a teacher', 'اضغطي للاتصال بمعلّمة', 'اضغط للاتصال بمعلّم');
  String teachersAvailable(int k) => switch (k) {
    0 => t('No teachers available right now', 'لا توجد معلّمات متاحات الآن', 'لا يوجد معلّمون متاحون الآن'),
    1 => t('1 teacher available now', 'معلّمة واحدة متاحة الآن', 'معلّم واحد متاح الآن'),
    2 => t('2 teachers available now', 'معلّمتان متاحتان الآن', 'معلّمان متاحان الآن'),
    <= 10 => t('$k teachers available now', '${n(k)} معلّمات متاحات الآن', '${n(k)} معلّمين متاحين الآن'),
    _ => t('$k teachers available now', '${n(k)} معلّمةً متاحةً الآن', '${n(k)} معلّمًا متاحًا الآن'),
  };
  String get nextPortionL => t('Your next portion', 'وِردكِ القادم', 'وِردك القادم');
  String get openInQuran => t('Open in Quran', 'افتحي في المصحف', 'افتح في المصحف');
  String get myTeacher => t('My teacher', 'معلّمتي', 'معلّمي');
  String get availableL => t('Available', 'متاحة', 'متاح');
  String get call => t('Call', 'اتصال');
  String get message => t('Message', 'رسالة');
  String get welcomeTitle => t('Welcome to Sanadi', 'أهلًا بكِ في سَنَدي', 'أهلًا بك في سَنَدي');
  String get welcomeBody => t(
    'Tap Recite now to start your first session. Your teacher and next portion will appear here.',
    'اضغطي «سمِّعي الآن» لتبدئي أول جلسة. ستظهر هنا معلّمتكِ ووِردكِ القادم.',
    'اضغط «سمِّع الآن» لتبدأ أول جلسة. سيظهر هنا معلّمك ووِردك القادم.',
  );
  String get myProgress => t('My progress', 'تقدّمي');

  // ---- 19 Connecting / 21 In call ----
  String get sessionType => t('Correction', 'تصحيح التلاوة');
  String get finding => t('Finding a teacher for you…', 'نبحث لكِ عن معلّمة…', 'نبحث لك عن معلّم…');
  String get findingSub => t('This usually takes less than a minute.', 'عادةً يستغرق هذا أقل من دقيقة.');
  String get callingSub =>
      t(g('Please wait while she answers.', 'Please wait while he answers.'), 'انتظري حتى تردّ.', 'انتظر حتى يردّ.');
  String get inSession => t('In session with', 'في جلسة مع');
  String get goodConn => t('Good connection', 'الاتصال جيد');
  String get mute => t('Mute', 'كتم الصوت');
  String get unmute => t('Unmute', 'إلغاء الكتم');
  String get speaker => t('Speaker', 'مكبّر الصوت');
  String get openQuran => t('Open Quran', 'افتحي المصحف', 'افتح المصحف');
  String get endCall => t('End call', 'إنهاء المكالمة');
  String get mutedBanner => t(
    g("Muted. Your teacher can't hear you.", "Muted. Your teacher can't hear you."),
    'الصوت مكتوم. معلّمتكِ لا تسمعكِ.',
    'الصوت مكتوم. معلّمك لا يسمعك.',
  );
  String get mutedBannerTeacher =>
      t("Muted. Your student can't hear you.", 'الصوت مكتوم. الطالبة لا تسمعكِ.', 'الصوت مكتوم. الطالب لا يسمعك.');
  String get endTitle => t('End this session?', 'إنهاء هذه الجلسة؟');
  String get endBody => t(
    'Your session will be saved to your progress.',
    'ستُحفظ جلستكِ في سجلّ تقدّمكِ.',
    'ستُحفظ جلستك في سجلّ تقدّمك.',
  );
  String get endBodyTeacher => t(
    'The session will be saved to the student\'s progress.',
    'ستُحفظ الجلسة في سجلّ تقدّم الطالبة.',
    'ستُحفظ الجلسة في سجلّ تقدّم الطالب.',
  );
  String get endYes => t('Yes, end call', 'نعم، أنهي المكالمة', 'نعم، أنهِ المكالمة');
  String get endNo => t('No, keep reciting', 'لا، سأكمل التسميع');
  String get endNoTeacher => t('No, continue', 'لا، سأكمل');
  String get testCall => t(
    'Test build: this is a practice call, no one is on the line.',
    'نسخة تجريبية: هذه مكالمة للتجربة، لا أحد على الخط.',
  );

  // ---- 24 Call ended (student) ----
  String get sEndTitle => t('May Allah reward you', 'جزاكِ الله خيرًا', 'جزاك الله خيرًا');
  String get savedToProgress => t('Saved to your progress', 'حُفظت في سجلّ تقدّمكِ', 'حُفظت في سجلّ تقدّمك');
  String get rateQ => t('How was your session? (optional)', 'كيف كانت جلستكِ؟ (اختياري)', 'كيف كانت جلستك؟ (اختياري)');
  List<String> get faces => ar ? ['ليست جيدة', 'مقبولة', 'جيدة'] : ['Not good', 'OK', 'Good'];
  String get thanks =>
      t('Thank you. JazakAllahu khairan.', 'شكرًا لكِ، جزاكِ الله خيرًا.', 'شكرًا لك، جزاك الله خيرًا.');

  // ---- 25 Teacher's notes ----
  String get recitedL => t('You recited', 'سمّعتِ', 'سمّعت');
  String get recited => t('Al-Mulk 1–10', 'سورة المُلك ١–١٠');
  String get practiseL => t('Ayahs to practise', 'آيات للمراجعة');
  String get teacherNoteL => t("Your teacher's note", 'ملاحظة معلّمتكِ', 'ملاحظة معلّمك');
  String get firstPortion => t('Al-Mulk 1–10', 'سورة المُلك ١–١٠');
  String get notesTag => t('Notes', 'ملاحظات');

  // ---- 26 My progress ----
  String get recentL => t('Recent sessions', 'آخر الجلسات');
  String get progressEmptyTitle => t('Your progress will appear here', 'سيظهر تقدّمكِ هنا', 'سيظهر تقدّمك هنا');
  String get progressEmptyBody => t(
    "After your first session you'll see what you have memorised, juz by juz.",
    'بعد أول جلسة سترين ما حفظتِه، جزءًا بعد جزء.',
    'بعد أول جلسة سترى ما حفظته، جزءًا بعد جزء.',
  );
  String juz(int k) => t("Juz' $k", 'الجزء ${n(k)}');

  // ---- 30 Teacher home ----
  String get on => t('ON', 'مفعّل');
  String get off => t('OFF', 'متوقّف');
  String get availOn => t("I'm available to teach", 'أنا متاحة للتدريس', 'أنا متاح للتدريس');
  String get availOnSub =>
      t('Students can call you now', 'يمكن للطالبات الاتصال بكِ الآن', 'يمكن للطلاب الاتصال بك الآن');
  String get availOff => t('You are away', 'أنتِ غير متاحة', 'أنت غير متاح');
  String get availOffSub =>
      t('Tap to start receiving calls', 'اضغطي لتبدئي استقبال المكالمات', 'اضغط لتبدأ استقبال المكالمات');
  String get today => t('Today', 'اليوم');
  String get sessionsL => t('sessions', 'جلسات');
  String get minutesL => t('minutes', 'دقيقة');
  String get waitingOff => t('Turn on to help them', 'فعّلي حالتكِ لمساعدتهن', 'فعّل حالتك لمساعدتهم');
  String get simulateCall => t('Try a practice call', 'جرّبي مكالمة تجريبية', 'جرّب مكالمة تجريبية');

  // ---- 31 Incoming call ----
  String get incoming => t('Incoming call', 'مكالمة واردة');
  String get lastPortionL => t('Last portion', 'آخر وِرد');
  String get lastPortion => t('Al-Mulk 1–10 · Good', 'سورة المُلك ١–١٠ · جيد');
  String get answerWithin => t('Answer within 30 seconds', 'أجيبي خلال ٣٠ ثانية', 'أجب خلال ٣٠ ثانية');
  String get accept => t('Accept', 'قبول');
  String get decline => t('Decline', 'رفض');
  String get missedTitle => t('Call not answered', 'لم يتم الرد على المكالمة');
  String get missedBody => t(
    g(
      "Fatima was connected to another teacher, so she isn't left waiting.",
      "Ahmad was connected to another teacher, so he isn't left waiting.",
    ),
    'تم توصيل فاطمة بمعلّمة أخرى حتى لا تنتظر.',
    'تم توصيل أحمد بمعلّم آخر حتى لا ينتظر.',
  );

  // ---- 34 Call ended (teacher) + optional notes ----
  String get tEndTitle => t('Call ended', 'انتهت المكالمة');
  String get tEndSaved => t("Saved to $studentShort's progress", 'حُفظت في سجلّ تقدّم $studentShort');
  String get addNotes => t(
    'Add notes for $studentShort (optional)',
    'أضيفي ملاحظات ل$studentShort (اختياري)',
    'أضف ملاحظات ل$studentShort (اختياري)',
  );
  String get notesSaved =>
      t('Notes saved. $studentShort will get a notification.', 'حُفظت الملاحظات. سيصل إشعار إلى $studentShort.');
  String get jazakTeach =>
      t('JazakAllahu khairan for teaching.', 'جزاكِ الله خيرًا على التعليم.', 'جزاك الله خيرًا على التعليم.');
  String notesForName(String name) => t('Notes for $name', 'ملاحظات لـ $name');
  String noteToName(String name) => t('Note to $name', 'ملاحظة لـ $name');
  String get allOptional => t(
    'Everything here is optional. Fill in only what helps.',
    'كل ما هنا اختياري. املئي ما يفيد فقط.',
    'كل ما هنا اختياري. املأ ما يفيد فقط.',
  );
  String get portionL => t('Portion recited', 'الوِرد المُسمَّع');
  String get fromAyah => t('From ayah', 'من آية');
  String get toAyah => t('To ayah', 'إلى آية');
  String get gradeL => t('Grade', 'التقدير');
  List<String> get grades => ar ? ['بحاجة إلى تدريب', 'جيد', 'ممتاز'] : ['Needs practice', 'Good', 'Excellent'];
  String get gradeGood => grades[1];
  String get mistakesL =>
      t('Ayahs to practise: tap one', 'آيات للمراجعة: اضغطي على آية', 'آيات للمراجعة: اضغط على آية');
  String get nextL => t('Next portion', 'الوِرد القادم');
  String get typeNote => t('Type a note', 'اكتبي ملاحظة', 'اكتب ملاحظة');
  String get saveNotes => t('Save notes', 'احفظي الملاحظات', 'احفظ الملاحظات');

  // ---- 45-47 Athkar ----
  String get athkarTitle => t('Athkar', 'الأذكار');
  String get nextReminder => t('Next reminder', 'التذكير القادم');
  String get remindersOff => t('Athkar reminders are off', 'تذكيرات الأذكار متوقّفة');
  String get turnOnReminders => t('Turn on reminders', 'فعّلي التذكيرات', 'فعّل التذكيرات');
  String get doneToday => t('Done today', 'تمّت اليوم');
  String get virtue => t('Its virtue', 'فضله');
  String get showTranslit => t('Show transliteration', 'إظهار النطق بالحروف اللاتينية');
  String get tapToCount => t('Tap to count', 'اضغطي للعدّ', 'اضغط للعدّ');
  String get nextDhikr => t('Next dhikr…', 'الذكر التالي…');
  String get previous => t('Previous', 'السابق');
  String get scrollMore => t('Scroll for more', 'مرّري للمزيد', 'مرّر للمزيد');
  String get quranLabel => t('Quran', 'قرآن');
  String get setDoneTitle => t('May Allah accept', 'تقبّل الله منكِ', 'تقبّل الله منك');
  String setDoneBody(String set) => t('You have finished the ${set.toLowerCase()}.', 'أتممتِ $set.', 'أتممت $set.');
  String get backToAthkar => t('Back to athkar', 'العودة للأذكار');
  String get resetCount => t('Start again', 'ابدئي من جديد', 'ابدأ من جديد');

  // ---- 37/39/40 Quran ----
  String get surahs => t('Surahs', 'السور');
  String get juzTab => t("Juz'", 'الأجزاء');
  String get makki => t('Makki', 'مكية');
  String get madani => t('Madani', 'مدنية');
  String get currentPage => t('Current page', 'الصفحة الحالية');
  String get pageBookmarks => t('Page bookmarks', 'علامات الصفحات');
  String get ayahBookmarks => t('Ayah bookmarks', 'علامات الآيات');
  String get noPageBookmarks => t(
    'Tap the bookmark at the top of a page to save it here.',
    'اضغطي على العلامة أعلى الصفحة لحفظها هنا.',
    'اضغط على العلامة أعلى الصفحة لحفظها هنا.',
  );
  String get noAyahBookmarks => t(
    'Press and hold an ayah, then tap Bookmark.',
    'اضغطي مطوّلًا على آية، ثم اختاري «علامة».',
    'اضغط مطوّلًا على آية، ثم اختر «علامة».',
  );
  String get continueReading => t('Continue reading', 'متابعة القراءة');
  String page(int p) => t('Page $p', 'صفحة ${n(p)}');
  String juzPage(int j, int p) => t('Juz $j · Page $p', 'الجزء ${n(j)} · صفحة ${n(p)}');
  String ayahsCount(int k) => t('$k ayahs', '${n(k)} آية');
  String get segLarge => t('Large text', 'نص كبير');
  String get segPage => t('Mushaf page', 'المصحف');
  String get play => t('Play', 'تشغيل');
  String get bookmark => t('Bookmark', 'علامة');
  String get goTo => t('Go to', 'انتقال');
  String ayahTitle(String surah, int a) => t('$surah · Ayah $a', '$surah · الآية ${n(a)}');
  String get playFrom => t('Play from this ayah', 'شغّلي من هذه الآية', 'شغّل من هذه الآية');
  String get copy => t('Copy', 'نسخ');
  String get tapToShowBars => t(
    'Tap the page to show the controls again.',
    'اضغطي على الصفحة لإظهار الأزرار مجددًا.',
    'اضغط على الصفحة لإظهار الأزرار مجددًا.',
  );
  String get copied => t('Ayah copied', 'نُسخت الآية');
  String get bookmarked => t('Bookmark saved', 'حُفظت العلامة');
  String get bookmarks => t('Bookmarks', 'العلامات');
  String get goToPage => t('Go to page', 'الانتقال إلى صفحة');
  String get pageNumberHint => t('Page number (1–604)', 'رقم الصفحة (١–٦٠٤)');
  String get go => t('Go', 'انتقال');

  // ---- 48–50 Messages, chat, report and block ----
  String get noChatsTitle => t('No messages yet', 'لا توجد رسائل بعد');
  String get noChatsBody => t(
    'After your first lesson, you can message your teacher here.',
    'بعد أول درس، يمكنكِ مراسلة معلّمتكِ هنا.',
    'بعد أول درس، يمكنك مراسلة معلّمك هنا.',
  );
  String get noChatsBodyTeacher => t(
    'After your first lesson with a student, you can message them here.',
    'بعد أول درس مع طالبة، يمكنكِ مراسلتها هنا.',
    'بعد أول درس مع طالب، يمكنك مراسلته هنا.',
  );
  String voiceNoteLen(int sec) => t('Voice note · ${_mmss(sec)}', 'رسالة صوتية · ${n(_mmss(sec))}');
  String get voiceNote => t('Voice note', 'رسالة صوتية');
  String get yesterday => t('Yesterday', 'أمس');
  String get typeMessage => t('Type a message…', 'اكتبي رسالة…', 'اكتب رسالة…');
  String get send => t('Send', 'إرسال');
  String get record => t('Record', 'تسجيل');
  String get sending => t('Sending…', 'جارٍ الإرسال…');
  String get notSent =>
      t('Not sent. Tap to try again.', 'لم تُرسل. اضغطي للمحاولة مرة أخرى.', 'لم تُرسل. اضغط للمحاولة مرة أخرى.');
  String get away => t('Away', 'غير متاحة', 'غير متاح');
  String get delete => t('Delete', 'حذف');
  String get deleteQ => t('Delete this message for both of you?', 'حذف هذه الرسالة لديكما معًا؟');
  String get reportBlock => t('Report or block', 'إبلاغ أو حظر');
  String reportName(String name) => t('Report $name', 'الإبلاغ عن $name');
  String get whatHappened => t('What happened?', 'ماذا حدث؟');
  List<String> get reportReasons => [
    t('Inappropriate words', 'كلام غير لائق'),
    t('Not respectful', 'عدم احترام'),
    t('Asked for personal details', 'طلب معلومات شخصية'),
    t('Something else', 'شيء آخر'),
  ];
  String get reportDetails => t('Tell us more (optional)', 'أخبرينا بالمزيد (اختياري)', 'أخبرنا بالمزيد (اختياري)');
  String alsoBlock(String name) => t('Also block $name', 'حظر $name أيضًا');
  String get sendReport => t('Send report', 'إرسال البلاغ');
  String get reportThanks =>
      t('Thank you. We will look into this.', 'جزاكِ الله خيرًا. سننظر في الأمر.', 'جزاك الله خيرًا. سننظر في الأمر.');
  String blockName(String name) => t('Block $name', 'حظر $name');
  String blockQ(String name) => t(
    'Block $name? Neither of you will be able to send messages in this chat.',
    'حظر $name؟ لن يتمكّن أيٌّ منكما من إرسال الرسائل في هذه المحادثة.',
  );
  String get block => t('Block', 'حظر');
  String get unblock => t('Unblock', 'إلغاء الحظر');
  String youBlocked(String name) => t('You blocked $name.', 'لقد حظرتِ $name.', 'لقد حظرت $name.');
  String get cantReply => t(
    "You can't send messages in this chat.",
    'لا يمكنكِ إرسال رسائل في هذه المحادثة.',
    'لا يمكنك إرسال رسائل في هذه المحادثة.',
  );
  String get micNeeded => t(
    'Sanadi needs the microphone to record. Allow it in your phone settings.',
    'يحتاج سَنَدي إلى الميكروفون للتسجيل. اسمحي به من إعدادات الهاتف.',
    'يحتاج سَنَدي إلى الميكروفون للتسجيل. اسمح به من إعدادات الهاتف.',
  );
  String get cantPlay => t("Couldn't play this voice note.", 'تعذّر تشغيل هذه الرسالة الصوتية.');
  String get chatOffline => t(
    "You're offline. Messages will be sent when you're back online.",
    'أنتِ غير متصلة. ستُرسل الرسائل عند عودة الاتصال.',
    'أنت غير متصل. ستُرسل الرسائل عند عودة الاتصال.',
  );
  String get voiceMax => t('Voice notes can be up to 3 minutes.', 'الرسالة الصوتية حتى ٣ دقائق.');
  String get pause => t('Pause', 'إيقاف مؤقت');

  // ---- Real calls ----
  String get callingAny => t('Calling a teacher…', 'نتصل بمعلّمة…', 'نتصل بمعلّم…');
  String get connectingCall => t('Connecting…', 'جارٍ الاتصال…');
  String get reconnecting => t('Reconnecting…', 'جارٍ إعادة الاتصال…');
  String get noTeacherTitle =>
      t('No teacher is free right now', 'لا توجد معلّمة متاحة الآن', 'لا يوجد معلّم متاح الآن');
  String get noTeacherBody =>
      t('Please try again in a little while.', 'حاولي مرة أخرى بعد قليل.', 'حاول مرة أخرى بعد قليل.');
  String get callFailedTitle => t("The call couldn't connect", 'تعذّر الاتصال');
  String get callFailedBody => t(
    'Check the internet and try again.',
    'تحقّقي من الإنترنت وحاولي مرة أخرى.',
    'تحقّق من الإنترنت وحاول مرة أخرى.',
  );
  String sEndSubName(int min, String name) => t('$min minutes with $name', '${n(min)} دقيقة مع $name');
  String tEndSubName(int min, String name) => t('$name · $min minutes', '$name · ${n(min)} دقيقة');
  String missedBodyName(String name) => t(
    g(
      "$name was connected to another teacher, so she isn't left waiting.",
      "$name was connected to another teacher, so he isn't left waiting.",
    ),
    'تم توصيل $name بمعلّمة أخرى حتى لا تنتظر.',
    'تم توصيل $name بمعلّم آخر حتى لا ينتظر.',
  );
  // ---- A teacher calls their student ----
  String callingName(String name) => t('Calling $name…', 'جارٍ الاتصال: $name');
  String get callStudentSub => t(
    g('She hears it ring if Sanadi is open on her phone.', 'He hears it ring if Sanadi is open on his phone.'),
    'يرنّ الاتصال عندها إذا كان سَنَدي مفتوحًا على هاتفها.',
    'يرنّ الاتصال عنده إذا كان سَنَدي مفتوحًا على هاتفه.',
  );
  String noAnswerTitle(String name) => t("$name didn't answer", 'لم تُجب $name', 'لم يُجب $name');
  String get noAnswerBody =>
      t('Try again later, or send a message.', 'حاولي لاحقًا، أو أرسلي رسالة.', 'حاول لاحقًا، أو أرسل رسالة.');
  String missedFromName(String name) =>
      t('You missed a call from $name.', 'فاتتكِ مكالمة من $name.', 'فاتتك مكالمة من $name.');

  String get keepOpen => t(
    'Calls ring even with Sanadi in the background or your phone locked. Don\'t swipe Sanadi away from your recent apps, or calls can\'t reach you.',
    'ترنّ المكالمات حتى وسَنَدي في الخلفية أو الهاتف مقفل. لا تُغلقي سَنَدي بسحبه من التطبيقات الأخيرة، وإلا لن تصلكِ المكالمات.',
    'ترنّ المكالمات حتى وسَنَدي في الخلفية أو الهاتف مقفل. لا تُغلق سَنَدي بسحبه من التطبيقات الأخيرة، وإلا لن تصلك المكالمات.',
  );
  String get micNeededCall => t(
    'Sanadi needs the microphone for calls. Allow it in your phone settings.',
    'يحتاج سَنَدي إلى الميكروفون للمكالمات. اسمحي به من إعدادات الهاتف.',
    'يحتاج سَنَدي إلى الميكروفون للمكالمات. اسمح به من إعدادات الهاتف.',
  );

  // ---- Lessons and progress ----
  String notesFromName(String name) => t('Notes from $name', 'ملاحظات من $name');
  String lessonWhen(String date, int min) => t('$date · $min min', '$date · ${n(min)} د');
  String get noNotes => t('No notes', 'بلا ملاحظات');
  String lessonsCount(int k) => switch (k) {
    1 => t('1 lesson', 'درس واحد'),
    2 => t('2 lessons', 'درسان'),
    <= 10 => t('$k lessons', '${n(k)} دروس'),
    _ => t('$k lessons', '${n(k)} درسًا'),
  };
  String minutesCount(int k) => switch (k) {
    1 => t('1 minute', 'دقيقة واحدة'),
    2 => t('2 minutes', 'دقيقتان'),
    <= 10 => t('$k minutes', '${n(k)} دقائق'),
    _ => t('$k minutes', '${n(k)} دقيقة'),
  };
  String ayahsRecited(int k) => t('Ayahs recited: $k', 'الآيات المُسمَّعة: ${n(k)}');
  String get chooseSurah => t('Choose surah', 'اختاري السورة', 'اختر السورة');
  String get noNextYet => t(
    'Your teacher will set your next portion after a lesson.',
    'ستحدّد معلّمتكِ وِردكِ القادم بعد الدرس.',
    'سيحدّد معلّمك وِردك القادم بعد الدرس.',
  );
  String lastLesson(String date) => t('Last lesson: $date', 'آخر درس: $date');
  String get lessonsL => t('Lessons', 'الدروس');
  String get notesNotSaved => t(
    "Couldn't save the notes. Try again.",
    'تعذّر حفظ الملاحظات. حاولي مرة أخرى.',
    'تعذّر حفظ الملاحظات. حاول مرة أخرى.',
  );
  String get progressHeadline => t('Your lessons so far', 'دروسكِ حتى الآن', 'دروسك حتى الآن');
  String get juzLegendTitle => t('Juz you have recited in', 'الأجزاء التي سمّعتِ منها', 'الأجزاء التي سمّعت منها');
  List<String> get juzLegend => [
    t('Recited well', 'سُمِّعت جيدًا'),
    t('Needs more practice', 'بحاجة إلى تدريب'),
    t('Not yet', 'لم تُسمَّع بعد'),
  ];

  /// "Al-Mulk 11–20" / "سورة المُلك ١١–٢٠" ([sura] is the surah's display name).
  String portionName(String sura, int from, int to) => from == to ? '$sura ${n(from)}' : '$sura ${n(from)}–${n(to)}';

  // ---- Recitation ----
  String get reciterL => t('Reciter', 'القارئ');
  String get repeatL => t('Repeat each ayah', 'تكرار كل آية');
  String get speedL => t('Speed', 'السرعة');
  String get stop => t('Stop', 'إيقاف');
  String repeatTimes(int k) => k == 0 ? '∞' : '×${n(k)}';
  String get recitationFailed => t(
    "Couldn't play the recitation. Check the internet.",
    'تعذّر تشغيل التلاوة. تحقّقي من الإنترنت.',
    'تعذّر تشغيل التلاوة. تحقّق من الإنترنت.',
  );
  String get recitationSettings => t('Recitation settings', 'إعدادات التلاوة');
  String get setNextShort => t('Next portion', 'وِرد قادم');
  String get nextPortionSet => t('Set as your next portion', 'صار وِردكِ القادم', 'صار وِردك القادم');

  // ---- Reminders ----
  String get remindersL => t('Athkar reminders', 'تذكير الأذكار');
  String get remindersChannel => t('Athkar reminders', 'تذكير الأذكار');
  String get remindersChannelDesc => t('Morning and evening athkar reminders', 'تذكير بأذكار الصباح والمساء');
  String get morningAthkar => t('Morning athkar', 'أذكار الصباح');
  String get eveningAthkar => t('Evening athkar', 'أذكار المساء');
  String get morningReminderBody => t(
    'A few minutes of remembrance to begin your day.',
    'دقائق من الذكر تبدئين بها يومكِ.',
    'دقائق من الذكر تبدأ بها يومك.',
  );
  String get eveningReminderBody => t('Time for the evening athkar.', 'حان وقت أذكار المساء.');
  String reminderAt(bool morning, String time) => '${morning ? morningAthkar : eveningAthkar} · ${n(time)}';
  String get reminderTimesHint => t(
    'Choose times that suit you, e.g. after Fajr and after Asr.',
    'اختاري الوقت المناسب لكِ، مثل بعد الفجر وبعد العصر.',
    'اختر الوقت المناسب لك، مثل بعد الفجر وبعد العصر.',
  );

  // ---- Settings: profile, help, privacy ----
  String get changeName => t('Change name', 'تغيير الاسم');
  String get save => t('Save', 'حفظ');
  String get helpSection => t('Help and information', 'المساعدة والمعلومات');
  String get contactSub => t('Questions, ideas or problems', 'أسئلة أو اقتراحات أو مشكلات');
  String get noEmailApp => t(
    'No email app found. Our email address is copied: paste it in any email app.',
    'لا يوجد تطبيق بريد. نسخنا عنوان بريدنا: الصقيه في أي تطبيق بريد.',
    'لا يوجد تطبيق بريد. نسخنا عنوان بريدنا: الصقه في أي تطبيق بريد.',
  );
  String get privacyTitle => t('Privacy policy', 'سياسة الخصوصية');
  String get privacySub => t('What we keep and why', 'ما نحفظه ولماذا');
  String get aboutTitle => t('About Sanadi', 'عن سَنَدي');
  String get aboutSub => t('Thanks and sources', 'شكر ومصادر');
  String get blockedTitle => t('Blocked people', 'المحظورون');
  String get blockedSub => t('People you blocked in messages', 'من حظرتهم في الرسائل');
  String get blockedEmpty => t('You haven\'t blocked anyone', 'لم تحظري أحدًا', 'لم تحظر أحدًا');
  String get deleteAccount => t('Delete my account', 'حذف حسابي');
  String get deleteAccountQ => t('Delete your account?', 'حذف حسابكِ؟', 'حذف حسابك؟');
  String get deleteAccountBody => t(
    'Your profile, teacher application and voice sample are deleted for good. Messages you sent and past lessons stay with the other person. Google may ask you to sign in again first.',
    'يُحذف ملفكِ وطلب التدريس والتسجيل الصوتي نهائيًا. تبقى الرسائل التي أرسلتِها والدروس السابقة عند الطرف الآخر. قد يطلب منكِ Google تسجيل الدخول مرة أخرى أولًا.',
    'يُحذف ملفك وطلب التدريس والتسجيل الصوتي نهائيًا. تبقى الرسائل التي أرسلتها والدروس السابقة عند الطرف الآخر. قد يطلب منك Google تسجيل الدخول مرة أخرى أولًا.',
  );
  String get deleteForever => t('Delete for good', 'حذف نهائي');
  String get accountDeleted => t('Your account was deleted', 'تم حذف حسابكِ', 'تم حذف حسابك');
  String get remindersOnSub => t('Morning and evening, on this phone', 'صباحًا ومساءً، على هذا الهاتف');
  String get remindersOffSub => t('Off', 'متوقف');

  String get aboutBody => t(
    'Sanadi is free, and always will be. It connects learners of every age, from children learning to recite to elders memorising, with volunteer teachers of the same gender, over a simple voice call.',
    'سَنَدي مجاني، وسيبقى كذلك دائمًا. يجمع المتعلّمين من كل الأعمار، من الأطفال في التلقين إلى كبار السن في الحفظ، بمعلّمين متطوعين من الجنس نفسه، عبر مكالمة صوتية بسيطة.',
  );
  String get thanksTitle => t('With thanks', 'مع الشكر');
  List<(String, String)> get acknowledgements => [
    (
      t('Mushaf text and font', 'نص المصحف وخطه'),
      t(
        'King Fahd Glorious Quran Printing Complex (KFGQPC), Madinah: Hafs script and page layout.',
        'مجمع الملك فهد لطباعة المصحف الشريف بالمدينة المنورة: خط حفص وترتيب الصفحات.',
      ),
    ),
    (
      t('Page layout data', 'بيانات ترتيب الصفحات'),
      t('The open-source quran-qcf4 project (MIT licence).', 'مشروع quran-qcf4 مفتوح المصدر (رخصة MIT).'),
    ),
    (
      t('Recitations', 'التلاوات'),
      t(
        'EveryAyah.com and Quran.com, with the recordings of the reciters listed in the Quran player.',
        'موقعا EveryAyah.com وQuran.com، بتسجيلات القرّاء المذكورين في مشغّل القرآن.',
      ),
    ),
    (
      t('Athkar', 'الأذكار'),
      t(
        'Hisn al-Muslim (Fortress of the Muslim) by Sa\'id ibn Ali al-Qahtani.',
        'حصن المسلم للشيخ سعيد بن علي القحطاني.',
      ),
    ),
    (
      t('Ayah of the day', 'آية اليوم'),
      t(
        'English translation of the meanings: Saheeh International (Dar Abul-Qasim, Jeddah). Arabic explanation: al-Tafsir al-Muyassar, King Fahd Glorious Quran Printing Complex.',
        'ترجمة المعاني بالإنجليزية: صحيح إنترناشيونال (دار أبي القاسم، جدة). والتفسير بالعربية: التفسير الميسّر، مجمع الملك فهد لطباعة المصحف الشريف.',
      ),
    ),
    (
      t('Countries and phone codes', 'الدول ورموز الهواتف'),
      t(
        'Country names from the Unicode CLDR project; calling codes and number lengths from Google\'s phone number data.',
        'أسماء الدول من مشروع Unicode CLDR، ورموز الاتصال وأطوال الأرقام من بيانات أرقام الهواتف لدى Google.',
      ),
    ),
  ];

  List<(String, String)> get privacySections => [
    (
      t('What we keep', 'ما نحفظه'),
      t(
        'Your name, gender, whether you are a student or teacher, the picture you chose, and the details you give when signing up: your age group, nationality and phone number. Your Google account is used only to sign you in; we don\'t see your password.',
        'اسمكِ وجنسكِ وهل أنتِ طالبة أم معلّمة، والصورة التي اخترتِها، والبيانات التي تذكرينها عند التسجيل: فئتكِ العمرية وجنسيتكِ ورقم هاتفكِ. يُستخدم حساب Google لتسجيل الدخول فقط، ولا نرى كلمة المرور.',
        'اسمك وجنسك وهل أنت طالب أم معلّم، والصورة التي اخترتها، والبيانات التي تذكرها عند التسجيل: فئتك العمرية وجنسيتك ورقم هاتفك. يُستخدم حساب Google لتسجيل الدخول فقط، ولا نرى كلمة المرور.',
      ),
    ),
    (
      t('Your phone number', 'رقم هاتفكِ', 'رقم هاتفك'),
      t(
        'Only Sanadi\'s admins can see it, and it is used only to keep your account safe and to contact you if needed. Teachers and students never see it. If you choose to join Sanadi\'s WhatsApp community, an admin adds you to it with this number, and WhatsApp\'s own privacy rules then apply there. You can change your choice in Settings.',
        'لا يراه إلا مشرفو سَنَدي، ولا يُستخدم إلا لأمان حسابكِ وللتواصل معكِ عند الحاجة. لا تراه المعلّمات ولا الطالبات أبدًا. وإن اخترتِ الانضمام إلى مجتمع سَنَدي على واتساب يضيفكِ أحد المشرفين بهذا الرقم، وتسري هناك قواعد الخصوصية الخاصة بواتساب. يمكنكِ تغيير اختياركِ من الإعدادات.',
        'لا يراه إلا مشرفو سَنَدي، ولا يُستخدم إلا لأمان حسابك وللتواصل معك عند الحاجة. لا يراه المعلّمون ولا الطلاب أبدًا. وإن اخترت الانضمام إلى مجتمع سَنَدي على واتساب يضيفك أحد المشرفين بهذا الرقم، وتسري هناك قواعد الخصوصية الخاصة بواتساب. يمكنك تغيير اختيارك من الإعدادات.',
      ),
    ),
    (
      t('Your own photo', 'صورتكِ الخاصة', 'صورتك الخاصة'),
      t(
        'If you use your own photo, it is saved small and seen only by people of your own gender in Sanadi, and by admins, who can remove a picture that isn\'t suitable. Choosing another picture deletes it.',
        'إن استخدمتِ صورتكِ الخاصة فإنها تُحفظ بحجم صغير، ولا يراها إلا من هم من جنسكِ في سَنَدي والمشرفون، ويمكن للمشرفين حذف الصورة غير اللائقة. واختيار صورة أخرى يحذفها.',
        'إن استخدمت صورتك الخاصة فإنها تُحفظ بحجم صغير، ولا يراها إلا من هم من جنسك في سَنَدي والمشرفون، ويمكن للمشرفين حذف الصورة غير اللائقة. واختيار صورة أخرى يحذفها.',
      ),
    ),
    (
      t('Messages and lessons', 'الرسائل والدروس'),
      t(
        'Text messages, voice notes, lesson times and teachers\' notes are saved so both people can see them. Only the two people in a conversation (and admins, if a report is made) can read them.',
        'تُحفظ الرسائل والتسجيلات الصوتية وأوقات الدروس وملاحظات المعلّمين ليراها الطرفان. لا يقرؤها إلا طرفا المحادثة (والمشرفون عند وجود بلاغ).',
      ),
    ),
    (
      t('Calls', 'المكالمات'),
      t(
        'Calls go directly between the two phones and are never recorded.',
        'تتم المكالمات مباشرة بين الهاتفين ولا تُسجَّل أبدًا.',
      ),
    ),
    (
      t('Teacher applications', 'طلبات التدريس'),
      t(
        'A teacher\'s answers and recitation sample are seen only by Sanadi\'s admins, to review the application. Once approved, a teacher\'s name, picture and availability are shown to students of the same gender, so they can call them.',
        'لا يرى إجابات المعلّم وتسجيل تلاوته إلا مشرفو سَنَدي لمراجعة الطلب. وبعد اعتماده يظهر اسم المعلّم وصورته وإتاحته للطلاب من الجنس نفسه ليتمكّنوا من الاتصال به.',
      ),
    ),
    (
      t('On your phone only', 'على هاتفكِ فقط', 'على هاتفك فقط'),
      t(
        'Bookmarks, athkar progress, reminder times and the Ayah of the day setting stay on your phone.',
        'العلامات وتقدّم الأذكار وأوقات التذكير وإعداد «آية اليوم» تبقى على هاتفكِ.',
        'العلامات وتقدّم الأذكار وأوقات التذكير وإعداد «آية اليوم» تبقى على هاتفك.',
      ),
    ),
    (
      t('Where it is stored', 'أين تُحفظ'),
      t(
        'On Google Firebase servers in the Middle East. We never sell your data or show adverts.',
        'على خوادم Google Firebase في الشرق الأوسط. لا نبيع بياناتكِ ولا نعرض إعلانات.',
        'على خوادم Google Firebase في الشرق الأوسط. لا نبيع بياناتك ولا نعرض إعلانات.',
      ),
    ),
    (
      t('Children', 'الأطفال'),
      t(
        'Accounts are for adults. A child can recite to a teacher on a parent\'s or guardian\'s account, with that parent nearby. Children don\'t have accounts of their own, so we keep nothing about them. Everyone can read the Quran and athkar without an account.',
        'الحسابات للبالغين. يمكن للطفل أن يقرأ على المعلّم من حساب وليّ أمره وبحضوره. ليس للأطفال حسابات خاصة بهم، فلا نحفظ عنهم شيئًا. ويمكن للجميع قراءة القرآن والأذكار دون حساب.',
      ),
    ),
    (
      t('Your choice', 'قراركِ', 'قرارك'),
      t(
        'You can change your name, picture or details in Settings, and delete your account at any time. For any question, tap Contact us below.',
        'يمكنكِ تغيير اسمكِ أو صورتكِ أو بياناتكِ من الإعدادات، وحذف حسابكِ في أي وقت. لأي سؤال اضغطي «تواصل معنا» في الأسفل.',
        'يمكنك تغيير اسمك أو صورتك أو بياناتك من الإعدادات، وحذف حسابك في أي وقت. لأي سؤال اضغط «تواصل معنا» في الأسفل.',
      ),
    ),
  ];

  // ---- Teacher list, alerts, continue reading ----
  String get teachersTitle => t('Teachers', 'المعلّمات', 'المعلّمون');
  String get seeAll => t('See all', 'عرض الكل');
  String get tabAll => t('All', 'الكل');
  String get tabAvailable => t('Available now', 'متاحة الآن', 'متاح الآن');
  String get tabFavorites => t('Favourites', 'المفضّلة');
  String get inLesson => t('In a lesson', 'في درس');
  String get favorite => t('Add to favourites', 'إضافة إلى المفضّلة');
  String get unfavorite => t('Remove from favourites', 'إزالة من المفضّلة');
  String get noTeachersYet => t('No teachers yet', 'لا توجد معلّمات بعد', 'لا يوجد معلّمون بعد');
  String get noTeachersNow => t(
    'No teacher is free right now. Turn on the alert on your home screen, and we\'ll tell you when one is.',
    'لا توجد معلّمة متاحة الآن. فعّلي التنبيه في الشاشة الرئيسية وسنخبركِ عند توفّر إحداهن.',
    'لا يوجد معلّم متاح الآن. فعّل التنبيه في الشاشة الرئيسية وسنخبرك عند توفّر أحدهم.',
  );
  String get noFavorites => t(
    'Tap the heart on a teacher to keep them here.',
    'اضغطي على القلب بجانب المعلّمة لتظهر هنا.',
    'اضغط على القلب بجانب المعلّم ليظهر هنا.',
  );
  String get callTeacherNote => t(
    'If your teacher can\'t answer, we\'ll connect you to another free teacher.',
    'إن لم تستطع المعلّمة الرد، سنوصلكِ بمعلّمة أخرى متاحة.',
    'إن لم يستطع المعلّم الرد، سنوصلك بمعلّم آخر متاح.',
  );
  String readingAt(String sura, int page) => t('$sura · Page $page', '$sura · صفحة ${n(page)}');
  String get alertTitle => t('Alert me when a teacher is free', 'نبّهيني عند توفّر معلّمة', 'نبّهني عند توفّر معلّم');
  String get alertSub =>
      t('For one hour, while Sanadi is open or in the background.', 'لمدة ساعة، ما دام سَنَدي مفتوحًا أو في الخلفية.');
  String alertOnUntil(String time) => t('On until $time', 'مفعّل حتى ${n(time)}');
  String get teacherFreeTitle => t('A teacher is free now', 'معلّمة متاحة الآن', 'معلّم متاح الآن');
  String get teacherFreeBody =>
      t('Open Sanadi and tap "Recite now".', 'افتحي سَنَدي واضغطي «سمِّعي الآن».', 'افتح سَنَدي واضغط «سمِّع الآن».');
  // ---- Ringing in the background, and other notifications ----
  String get callsChannel => t('Incoming calls', 'المكالمات الواردة');
  String get callsChannelDesc => t('A student calling you', 'اتصال من طالب');
  String get missedChannel => t('Missed calls', 'المكالمات الفائتة');
  String get missedChannelDesc => t('Calls you couldn\'t answer', 'مكالمات لم تتمكّن من الرد عليها');
  String get notesChannel => t('Lesson notes', 'ملاحظات الدروس');
  String get notesChannelDesc => t('When your teacher adds notes', 'عند إضافة المعلّم ملاحظات');
  String get notesTapToRead => t('Tap to read them', 'اضغطي لقراءتها', 'اضغط لقراءتها');
  String get accountChannel => t('Your account', 'حسابك');
  String get accountChannelDesc => t('News about your teacher application', 'مستجدات طلب التدريس');
  String get approvedTitle => t('You\'re approved to teach', 'تم اعتمادكِ للتدريس', 'تم اعتمادك للتدريس');
  String get approvedBody => t(
    'Jazakum Allahu khayran. Switch on "available" when you\'re ready.',
    'جزاكِ الله خيرًا. فعّلي الإتاحة حين تكونين مستعدة.',
    'جزاك الله خيرًا. فعّل الإتاحة حين تكون مستعدًا.',
  );
  String get notApprovedTitle => t('About your application', 'بخصوص طلبكِ', 'بخصوص طلبك');
  String get notApprovedBody =>
      t('Open Sanadi to read the reply.', 'افتحي سَنَدي لقراءة الرد.', 'افتح سَنَدي لقراءة الرد.');
  String get availabilityChannel => t('Available to teach', 'الإتاحة للتدريس');
  String get availabilityTitle => t('You\'re available to teach', 'أنتِ متاحة للتدريس', 'أنت متاح للتدريس');
  String get availabilityText => t(
    'Sanadi will ring here when a student calls.',
    'سيرنّ سَنَدي هنا عند اتصال طالبة.',
    'سيرنّ سَنَدي هنا عند اتصال طالب.',
  );
  String get batteryTitle => t('So calls always ring', 'لكي ترنّ المكالمات دائمًا');
  String get batteryBody => t(
    'Phones put apps to sleep to save battery, and a sleeping app can\'t ring. On the next screen, please allow Sanadi to run without battery limits. It only stays awake while you\'re available to teach.',
    'تُنيم الهواتف التطبيقات لتوفير البطارية، والتطبيق النائم لا يرنّ. في الشاشة التالية، يُرجى السماح لسَنَدي بالعمل دون قيود البطارية. لا يبقى مستيقظًا إلا وأنتِ متاحة للتدريس.',
    'تُنيم الهواتف التطبيقات لتوفير البطارية، والتطبيق النائم لا يرنّ. في الشاشة التالية، يُرجى السماح لسَنَدي بالعمل دون قيود البطارية. لا يبقى مستيقظًا إلا وأنت متاح للتدريس.',
  );
  String get batteryAllow => t('Continue', 'متابعة');

  String get textSizeL => t('Text size', 'حجم الخط');
  String get textSizePhone => t('Same as phone', 'مثل الهاتف');
  String get textSizePreview => t('This is how text looks in Sanadi.', 'هكذا يبدو الخط في سَنَدي.');
  String percent(double x) => ar ? '${n((x * 100).round())}\u066A' : '${(x * 100).round()}%';
  String get messagesChannel => t('Messages', 'الرسائل');
  String get messagesChannelDesc => t('New messages from your teacher or student', 'رسائل جديدة من المعلّم أو الطالب');
  String get messageAlertsL => t('Message notifications', 'إشعارات الرسائل');
  String get messageAlertsSub => t('While Sanadi is open or in the background', 'ما دام سَنَدي مفتوحًا أو في الخلفية');
  String get teacherAlertsChannel => t('Teacher alerts', 'تنبيهات المعلّمين');
  String get teacherAlertsChannelDesc =>
      t('When a teacher becomes free (if you asked)', 'عند توفّر معلّم (إن طلبت ذلك)');
  String waitingCount(int k) => switch (k) {
    0 => t('No students waiting right now', 'لا طالبات ينتظرن الآن', 'لا طلاب ينتظرون الآن'),
    1 => t('1 student waiting for a teacher', 'طالبة واحدة تنتظر معلّمة', 'طالب واحد ينتظر معلّمًا'),
    _ => t('${n(k)} students waiting for a teacher', '${n(k)} طالبات ينتظرن معلّمة', '${n(k)} طلاب ينتظرون معلّمًا'),
  };

  // ---- Admin: people, pausing, overview ----
  String get usersTitle => t('People', 'المستخدمون');
  String get usersSub => t('Find someone, pause or restore an account', 'البحث عن شخص، وإيقاف حساب أو إعادته');
  String get searchName => t('Search by name', 'البحث بالاسم');
  String get pausedTag => t('Paused', 'موقوف');
  String get pauseAccount => t('Pause account', 'إيقاف الحساب');
  String get restoreAccount => t('Restore account', 'إعادة الحساب');
  String pauseQ(String name) => t('Pause $name\'s account?', 'إيقاف حساب $name؟');
  String get pauseBody => t(
    'They won\'t be able to send messages, call or teach until you restore the account.',
    'لن يتمكّن صاحب الحساب من المراسلة أو الاتصال أو التدريس حتى يُعاد الحساب.',
  );
  String get pauseReason => t('Reason (for the admins)', 'السبب (للمشرفين)');
  String pauseName(String name) => t('Pause $name', 'إيقاف $name');
  String get pausedDone => t('Account paused', 'تم إيقاف الحساب');
  String get restoredDone => t('Account restored', 'تمت إعادة الحساب');
  String get overviewTitle => t('Overview', 'نظرة عامة');
  String get overviewSub => t('Teachers, students and lessons', 'المعلّمون والطلاب والدروس');
  String get statStudents => t('Students', 'الطلاب');
  String get statTeachers => t('Approved teachers', 'المعلّمون المعتمدون');
  String get statTeachersOn => t('Teachers switched on', 'معلّمون متاحون الآن');
  String get statPending => t('Applications waiting', 'طلبات بانتظار المراجعة');
  String get statReports => t('Open reports', 'بلاغات مفتوحة');
  String get statLessons => t('Lessons in the last 7 days', 'دروس آخر 7 أيام');
  String get statMinutes => t('Minutes taught in the last 7 days', 'دقائق التدريس آخر 7 أيام');
  String get refresh => t('Refresh', 'تحديث');

  // ---- Paused account ----
  String get pausedTitle => t('Your account is paused', 'حسابكِ موقوف', 'حسابك موقوف');
  String get pausedBody => t(
    'An admin has paused your account, so messages and calls are switched off for now. The Quran and athkar are still here for you. If you think this is a mistake, please contact us.',
    'أوقف أحد المشرفين حسابكِ، لذا توقّفت الرسائل والمكالمات مؤقتًا. ما زال القرآن والأذكار متاحين لكِ. إن كنتِ ترين أن هذا خطأ، يُرجى التواصل معنا.',
    'أوقف أحد المشرفين حسابك، لذا توقّفت الرسائل والمكالمات مؤقتًا. ما زال القرآن والأذكار متاحين لك. إن كنت ترى أن هذا خطأ، يُرجى التواصل معنا.',
  );

  // ---- Auto-away ----
  String get autoAwayTitle => t('We set you to away', 'جعلناكِ غير متاحة', 'جعلناك غير متاح');
  String get autoAwayBody => t(
    'You missed 2 calls in a row, so students aren\'t being sent to you. Switch on when you\'re ready.',
    'فاتتكِ مكالمتان متتاليتان، فلم نعد نحوّل إليكِ الطالبات. فعّلي الإتاحة حين تكونين مستعدة.',
    'فاتتك مكالمتان متتاليتان، فلم نعد نحوّل إليك الطلاب. فعّل الإتاحة حين تكون مستعدًا.',
  );

  // ---- Terms and code of conduct ----
  String get termsTitle => t('Terms of use', 'شروط الاستخدام');
  List<(String, String)> get termsSections => [
    (
      t('A free service', 'خدمة مجانية'),
      t(
        'Sanadi is free. Teachers are volunteers who give their time for the sake of Allah. Nothing is ever sold, and there are no adverts.',
        'سَنَدي مجاني. المعلّمون متطوعون يبذلون وقتهم لوجه الله. لا يُباع فيه شيء، ولا توجد إعلانات.',
      ),
    ),
    (
      t('Accounts and children', 'الحسابات والأطفال'),
      t(
        'You must be an adult to have an account. A child may recite to a teacher only on a parent\'s or guardian\'s account, with that parent nearby during the lesson.',
        'يُشترط أن يكون صاحب الحساب بالغًا. ولا يقرأ الطفل على المعلّم إلا من حساب وليّ أمره، وبحضوره أثناء الدرس.',
      ),
    ),
    (
      t('Respect and good manners', 'الاحترام وحسن الخلق'),
      t(
        'Speak kindly and with respect. Students are only connected with teachers of the same gender. Never ask for or share phone numbers, addresses, photos or money.',
        'الحديث بلطف واحترام. لا يُربط الطلاب إلا بمعلّمين من الجنس نفسه. ولا يجوز طلب أرقام الهواتف أو العناوين أو الصور أو المال، ولا مشاركتها.',
      ),
    ),
    (
      t('Calls and messages', 'المكالمات والرسائل'),
      t(
        'Calls are never recorded by Sanadi, and must not be recorded by anyone. Messages are between the two of you; admins only read them if a report is made.',
        'لا يسجّل سَنَدي المكالمات أبدًا، ولا يجوز لأحد تسجيلها. الرسائل بينكما فقط، ولا يطّلع عليها المشرفون إلا عند وجود بلاغ.',
      ),
    ),
    (
      t('Reporting and pausing', 'الإبلاغ والإيقاف'),
      t(
        'If anyone makes you uncomfortable, block and report them. Admins may pause an account that breaks these terms.',
        'عند الانزعاج من أي شخص: حظره والإبلاغ عنه. ويجوز للمشرفين إيقاف أي حساب يخالف هذه الشروط.',
      ),
    ),
    (
      t('Your account', 'الحساب'),
      t(
        'You can delete your account at any time from Settings. The privacy policy explains what is kept and why.',
        'يمكن حذف الحساب في أي وقت من الإعدادات. وتوضّح سياسة الخصوصية ما نحفظه ولماذا.',
      ),
    ),
  ];
  String get codeTitle => t('Teacher code of conduct', 'ميثاق المعلّم');
  List<(String, String)> get codeSections => [
    (
      t('Sincerity', 'الإخلاص'),
      t(
        'Teach for the sake of Allah alone. Never ask a student for money, gifts or favours.',
        'التعليم ابتغاء وجه الله وحده، وعدم طلب مال أو هدية أو خدمة من أي طالب.',
      ),
    ),
    (
      t('Patience and gentleness', 'الصبر والرفق'),
      t(
        'Many students are elderly or new to reading. Correct gently, encourage often, and let them recite at their own pace.',
        'كثير من الطلاب كبار في السن أو مبتدئون في القراءة: التصحيح برفق، والتشجيع الدائم، وترك الطالب يقرأ بحسب قدرته.',
      ),
    ),
    (
      t('Same gender only', 'من الجنس نفسه فقط'),
      t(
        'Teach only students of your own gender. Sanadi connects you this way; never try to get around it.',
        'التعليم لطلاب من الجنس نفسه فقط. هكذا يربط سَنَدي بين الطرفين، ولا يجوز تجاوز ذلك.',
      ),
    ),
    (
      t('Teaching children', 'تعليم الأطفال'),
      t(
        'A child may recite on a parent\'s account, with the parent nearby. Teach a child only when a parent is present, keep lessons short and encouraging, and never contact a child outside Sanadi.',
        'قد يقرأ الطفل من حساب وليّ أمره وبحضوره. تعليم الطفل يكون بحضور وليّ الأمر فقط، بدروس قصيرة مشجِّعة، ودون أي تواصل مع الطفل خارج سَنَدي.',
      ),
    ),
    (
      t('Privacy', 'الخصوصية'),
      t(
        'Keep everything inside Sanadi. Don\'t ask for or share phone numbers, addresses or photos, and don\'t record calls.',
        'إبقاء كل شيء داخل سَنَدي: عدم طلب أرقام الهواتف أو العناوين أو الصور أو مشاركتها، وعدم تسجيل المكالمات.',
      ),
    ),
    (
      t('Accuracy', 'الضبط'),
      t(
        'Teach only what you are sure of. If you are unsure of a ruling, say so and check before the next lesson.',
        'تعليم ما يُتيقَّن منه فقط. وعند الشك في حكم: التصريح بذلك والتحقق منه قبل الدرس القادم.',
      ),
    ),
    (
      t('Availability', 'الإتاحة'),
      t(
        'Switch on "available" only when you can answer. If you miss two calls in a row, Sanadi sets you to away.',
        'تفعيل الإتاحة فقط عند القدرة على الرد. وعند فوات مكالمتين متتاليتين يوقف سَنَدي الإتاحة تلقائيًا.',
      ),
    ),
    (
      t('Reporting concerns', 'الإبلاغ عن المخاوف'),
      t(
        'If a student or anyone else behaves badly, block and report them. Admins may pause any account that breaks this code.',
        'عند إساءة أي شخص: حظره والإبلاغ عنه. ويجوز للمشرفين إيقاف أي حساب يخالف هذا الميثاق.',
      ),
    ),
  ];

  // ---- Admin: connect and reports ----
  String get connectTitle => t('Connect a student and teacher', 'ربط طالب بمعلّم');
  String get connectSub => t('Open a chat between them', 'فتح محادثة بينهما');
  String get connectHelp => t(
    'Choose a student, then a teacher of the same gender.',
    'اختاري طالبًا، ثم معلّمًا من الجنس نفسه.',
    'اختر طالبًا، ثم معلّمًا من الجنس نفسه.',
  );
  String get studentL => t('Student', 'الطالب');
  String get teacherL => t('Teacher', 'المعلّم');
  String get connect => t('Connect', 'ربط');
  String get connectedDone => t('Connected. They can now message each other.', 'تم الربط. يمكنهما الآن المراسلة.');
  String get noOneYet => t('No one yet', 'لا أحد بعد');
  String get reportsTitle => t('Reports', 'البلاغات');
  String get reportsSub => t('Reports about users', 'بلاغات عن المستخدمين');
  String get markResolved => t('Mark as dealt with', 'تمّت معالجته');
  String get noReports => t('No open reports', 'لا توجد بلاغات مفتوحة');
  String reportedBy(String a, String b) => t('$a reported $b', 'أبلغ $a عن $b');

  static String _mmss(int sec) => '${sec ~/ 60}:${(sec % 60).toString().padLeft(2, '0')}';
  String mmss(int sec) => n(_mmss(sec));

  String get studentsSoonTitle => t('Your students will appear here', 'ستظهر طالباتكِ هنا', 'سيظهر طلابك هنا');
  String get studentsSoonBody => t(
    'After your first sessions, you can see each student\'s progress here.',
    'بعد أولى جلساتكِ، سترين تقدّم كل طالبة هنا.',
    'بعد أولى جلساتك، سترى تقدّم كل طالب هنا.',
  );
  String get language => t('Language', 'اللغة');
  String get appearance => t('Appearance', 'المظهر');
  String get themeSystem => t('Same as phone', 'مثل الهاتف');
  String get themeLight => t('Light', 'فاتح');
  String get themeDark => t('Dark', 'داكن');
  String get account => t('Account', 'الحساب');
  String get signOut => t('Sign out', 'تسجيل الخروج');
  String get signOutQ => t('Sign out of Sanadi?', 'تسجيل الخروج من سَنَدي؟');
  String get testing => t('Testing tools', 'أدوات التجربة');
  String get testingNote => t(
    'Only in test builds. These let you try every screen before the backend is ready.',
    'في النسخ التجريبية فقط، لتجربة كل الشاشات قبل تجهيز الخادم.',
  );
  String get switchRole => t('Switch to teacher / student', 'التبديل بين معلّم وطالب');
  String get approveApp => t('Approve my application', 'الموافقة على طلبي');
  String get rejectApp => t('Reject my application', 'رفض طلبي');
  String get resetApp => t('Start again from the beginning', 'البدء من جديد');
  String get version => t('Version', 'الإصدار');
  String get serverLive => t('Connected: your profile is saved online', 'متصل: ملفك محفوظ على الإنترنت');
  String get serverDemo => t('Demo mode: nothing is saved online yet', 'وضع التجربة: لا يُحفظ شيء على الإنترنت بعد');

  // ---- Admin: teacher applications ----
  String get adminTitle => t('Teacher applications', 'طلبات المعلّمين');
  String get adminSub => t('Review volunteers and approve them', 'مراجعة المتطوعين والموافقة عليهم');
  String get adminEmpty => t('No applications are waiting', 'لا توجد طلبات بانتظار المراجعة');
  String get sister => t('Sister', 'أخت');
  String get brother => t('Brother', 'أخ');
  String get approve => t('Approve', 'موافقة');
  String get declineApp => t('Not approved', 'عدم الموافقة');
  String get declineQ => t('Turn down this application?', 'رفض هذا الطلب؟');
  String get declineReason => t('Reason (the applicant will see it)', 'السبب (سيظهر لصاحب الطلب)');
  String get decisionFailed =>
      t("Couldn't save. Check the internet and try again.", 'تعذّر الحفظ. تحقّق من الإنترنت وحاول مجددًا.');

  // ---- About you (age group, nationality, phone) ----
  String get detailsTitle => t('A little about you', 'قليلًا عنكِ', 'قليلًا عنك');
  String get detailsSub => t(
    'This helps keep Sanadi safe. Only Sanadi\'s admins can see these details; other users never do.',
    'يساعدنا هذا على حماية سَنَدي. لا يرى هذه البيانات إلا مشرفو سَنَدي، ولا يراها أي مستخدم آخر.',
  );
  String get ageGroupL => t('Age', 'العمر');
  String ageLabel(String group) => group == '65+' ? t('65 or over', '${n(65)} فأكثر') : n(group.replaceAll('-', '–'));
  String get under18Note => t(
    'Under 18? Please recite on a parent\'s account, with them nearby.',
    'أقلّ من ${n(18)} سنة؟ اقرئي من حساب وليّ أمركِ وبحضوره.',
    'أقلّ من ${n(18)} سنة؟ اقرأ من حساب وليّ أمرك وبحضوره.',
  );
  String get needAge => t('Please choose your age', 'اختاري عمركِ من فضلكِ', 'اختر عمرك من فضلك');
  String get nationalityL => t('Nationality', 'الجنسية');
  String get chooseNationality => t('Choose your nationality', 'اختاري جنسيتكِ', 'اختر جنسيتك');
  String get needNationality => t('Please choose your nationality', 'اختاري جنسيتكِ من فضلكِ', 'اختر جنسيتك من فضلك');
  String get phoneL => t('Phone number', 'رقم الهاتف');
  String get phoneSub => t(
    'Kept for your account\'s safety, so we can reach you if needed. It is never shown to teachers or students.',
    'يُحفظ لأمان حسابكِ، لنتواصل معكِ عند الحاجة. لا يظهر أبدًا للمعلّمات أو الطالبات.',
    'يُحفظ لأمان حسابك، لنتواصل معك عند الحاجة. لا يظهر أبدًا للمعلّمين أو الطلاب.',
  );
  String get phoneInvalid => t(
    'Please check the number and the country code',
    'تحقّقي من الرقم ومن رمز الدولة',
    'تحقّق من الرقم ومن رمز الدولة',
  );
  String get countryCodeL => t('Country code', 'رمز الدولة');
  String get search => t('Search', 'بحث');
  String get whatsappL =>
      t('Join Sanadi\'s WhatsApp community (optional)', 'الانضمام إلى مجتمع سَنَدي على واتساب (اختياري)');
  String get whatsappSub => t(
    'News and reminders from Sanadi. An admin adds you using this number, and you can leave at any time.',
    'أخبار وتذكيرات من سَنَدي. يضيفكِ أحد المشرفين بهذا الرقم، ويمكنكِ المغادرة في أي وقت.',
    'أخبار وتذكيرات من سَنَدي. يضيفك أحد المشرفين بهذا الرقم، ويمكنك المغادرة في أي وقت.',
  );
  String get yourDetails => t('Your details', 'بياناتكِ', 'بياناتك');
  String get whatsappMember => t('WhatsApp community', 'مجتمع واتساب');
  String get copyNumbers => t('Copy their numbers', 'نسخ أرقامهم');
  String get numbersCopied => t('Numbers copied', 'نُسخت الأرقام');
  String get numberCopied => t('Number copied', 'نُسخ الرقم');
  String get notGivenYet => t('Not given yet', 'لم تُذكر بعد');
  String get yes => t('Yes', 'نعم');
  String get no => t('No', 'لا');

  // ---- Own profile photo ----
  String get ownPhoto => t('My own photo', 'صورتي الخاصة');
  String get takePhoto => t('Take a photo', 'التقاط صورة');
  String get choosePhoto => t('Choose from gallery', 'اختيار من المعرض');
  String get photoRules => t(
    'Please use a decent picture of yourself. Teachers and students of the same gender can see it.',
    'استخدمي صورة لائقة لكِ. تراها المعلّمات والطالبات فقط.',
    'استخدم صورة لائقة لك. يراها المعلّمون والطلاب فقط.',
  );
  String get photoSaving => t('Saving your picture…', 'جارٍ حفظ الصورة…');
  String get photoFailed => t(
    'Couldn\'t save the picture. Check the internet and try again.',
    'تعذّر حفظ الصورة. تحقّقي من الإنترنت وحاولي مجددًا.',
    'تعذّر حفظ الصورة. تحقّق من الإنترنت وحاول مجددًا.',
  );
  String get removePhoto => t('Remove picture', 'حذف الصورة');
  String get removePhotoQ => t('Remove this person\'s picture?', 'حذف صورة هذا الشخص؟');
  String get photoRemoved => t('Picture removed', 'حُذفت الصورة');

  // ---- Ayah of the day ----
  String get ayahOfDay => t('Ayah of the day', 'آية اليوم');
  String get ayahMeaningL => t('Translation of the meaning', 'التفسير الميسّر');

  /// Where the translation (English) or explanation (Arabic) comes from.
  String get ayahSource => t('Saheeh International', 'التفسير الميسّر، مجمع الملك فهد');
  String get ayahMeaningNote => t(
    'This is a translation of the meaning of the ayah, not the Quran itself. The Quran is the Arabic words revealed by Allah, and no translation can carry their full meaning.\n\nTranslation: Saheeh International (Dar Abul-Qasim, Jeddah).',
    'هذا تفسير مختصر يبيّن معنى الآية، وليس من القرآن الكريم؛ فالقرآن هو كلام الله بلفظه العربي المنزّل.\n\nالمصدر: التفسير الميسّر، تأليف نخبة من العلماء، مجمع الملك فهد لطباعة المصحف الشريف بالمدينة المنورة.',
  );
  String ayahOfDaySub(String time) => t('Every day at $time', 'كل يوم الساعة ${n(time)}');
  String get ayahOfDayOff => t('Off', 'متوقّفة');
  String get ayahOfDayHint => t(
    'A short ayah about everyday life, with its meaning, as a notification.',
    'آية قصيرة عن الحياة اليومية مع معناها، في إشعار.',
  );
  String get ayahTimeL => t('Time', 'الوقت');
  String get ayahChannel => t('Ayah of the day', 'آية اليوم');
  String get ayahChannelDesc => t('A short ayah with its meaning, once a day', 'آية قصيرة مع معناها، مرة كل يوم');
  String ayahRef(String sura, int from, int to) => from == to
      ? t('$sura, ayah $from', '$sura، الآية ${n(from)}')
      : t('$sura, ayahs $from–$to', '$sura، الآيات ${n(from)}–${n(to)}');

  // ---- Surah search ----
  String get searchSurah => t('Search for a surah', 'ابحثي عن سورة', 'ابحث عن سورة');
  String get clear => t('Clear', 'مسح');
  String get noSurahFound => t(
    'No surah found. Try another spelling, or the surah\'s number.',
    'لم نجد سورة بهذا الاسم. جرّبي كتابة أخرى أو رقم السورة.',
    'لم نجد سورة بهذا الاسم. جرّب كتابة أخرى أو رقم السورة.',
  );

  // ---- Auto scroll in the mushaf ----
  String get autoScroll => t('Auto scroll', 'التمرير التلقائي');
  String speedN(int v) => t('Speed $v', 'السرعة ${n(v)}');
  String get slower => t('Slower', 'أبطأ');
  String get faster => t('Faster', 'أسرع');
  String get stopAutoScroll => t('Stop auto scroll', 'إيقاف التمرير التلقائي');
}

class StringsScope extends InheritedWidget {
  const StringsScope({super.key, required this.s, required super.child});

  final S s;

  @override
  bool updateShouldNotify(StringsScope old) => old.s.ar != s.ar || old.s.female != s.female;

  static S fromSettings(AppSettings settings, Locale locale) =>
      S(ar: locale.languageCode == 'ar', female: settings.female);
}
