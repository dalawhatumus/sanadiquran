part of '../strings.dart';

/// Language, welcome, sign-up steps, the teacher application and "About you".
extension OnboardingStrings on S {
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
}
