part of '../strings.dart';

/// Finding a teacher, ringing, the call itself, its end, and call notifications.
extension CallStrings on S {
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
  String get mutedBanner =>
      t("Muted. Your teacher can't hear you.", 'الصوت مكتوم. معلّمتكِ لا تسمعكِ.', 'الصوت مكتوم. معلّمك لا يسمعك.');
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
  String get mistakesL =>
      t('Ayahs to practise: tap one', 'آيات للمراجعة: اضغطي على آية', 'آيات للمراجعة: اضغط على آية');
  String get nextL => t('Next portion', 'الوِرد القادم');
  String get typeNote => t('Type a note', 'اكتبي ملاحظة', 'اكتب ملاحظة');
  String get saveNotes => t('Save notes', 'احفظي الملاحظات', 'احفظ الملاحظات');

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
  String sEndSubName(int min, String name) => t('${minutesCount(min)} with $name', '${minutesCount(min)} مع $name');
  String tEndSubName(int min, String name) => '$name · ${minutesCount(min)}';
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

  // ---- Ringing in the background, and other notifications ----
  String get callsChannel => t('Incoming calls', 'المكالمات الواردة');
  String get callsChannelDesc => t('Someone calling you on Sanadi', 'اتصال يصلكِ في سَنَدي', 'اتصال يصلك في سَنَدي');
  String get missedChannel => t('Missed calls', 'المكالمات الفائتة');
  String get missedChannelDesc =>
      t('Calls you couldn\'t answer', 'مكالمات لم تتمكّني من الرد عليها', 'مكالمات لم تتمكّن من الرد عليها');
  String get notesChannel => t('Lesson notes', 'ملاحظات الدروس');
  String get notesChannelDesc =>
      t('When your teacher adds notes', 'عند إضافة المعلّمة ملاحظات', 'عند إضافة المعلّم ملاحظات');
  String get notesTapToRead => t('Tap to read them', 'اضغطي لقراءتها', 'اضغط لقراءتها');
  String get accountChannel => t('Your account', 'حسابك');
  String get accountChannelDesc => t('News about your teacher application', 'مستجدات طلب التدريس');
  String get approvedTitle => t('You\'re approved to teach', 'تم اعتمادكِ للتدريس', 'تم اعتمادك للتدريس');
  String get approvedBody => t(
    'JazakAllahu khairan. Switch on "available" when you\'re ready.',
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
  String get messagesChannelDesc => t(
    'New messages from your teacher or student',
    'رسائل جديدة من المعلّمة أو الطالبة',
    'رسائل جديدة من المعلّم أو الطالب',
  );
  String get messageAlertsL => t('Message notifications', 'إشعارات الرسائل');
  String get messageAlertsSub => t('While Sanadi is open or in the background', 'ما دام سَنَدي مفتوحًا أو في الخلفية');
  String get teacherAlertsChannel => t('Teacher alerts', 'تنبيهات المعلّمات', 'تنبيهات المعلّمين');
  String get teacherAlertsChannelDesc => t(
    'When a teacher becomes free (if you asked)',
    'عند توفّر معلّمة (إن طلبتِ ذلك)',
    'عند توفّر معلّم (إن طلبت ذلك)',
  );
  String waitingCount(int k) => switch (k) {
    0 => t('No students waiting right now', 'لا طالبات ينتظرن الآن', 'لا طلاب ينتظرون الآن'),
    1 => t('1 student waiting for a teacher', 'طالبة واحدة تنتظر معلّمة', 'طالب واحد ينتظر معلّمًا'),
    2 => t('2 students waiting for a teacher', 'طالبتان تنتظران معلّمة', 'طالبان ينتظران معلّمًا'),
    <= 10 => t('$k students waiting for a teacher', '${n(k)} طالبات ينتظرن معلّمة', '${n(k)} طلاب ينتظرون معلّمًا'),
    _ => t('$k students waiting for a teacher', '${n(k)} طالبةً ينتظرن معلّمة', '${n(k)} طالبًا ينتظرون معلّمًا'),
  };
}
