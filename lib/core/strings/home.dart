part of '../strings.dart';

/// The student and teacher home screens, the teacher list and alerts, a paused account and auto-away.
extension HomeStrings on S {
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
  // Labels under a number: the Arabic noun follows it (plural for 3–10).
  String sessionsL(int k) => t(k == 1 ? 'session' : 'sessions', k >= 3 && k <= 10 ? 'جلسات' : 'جلسة');
  String minutesL(int k) => t(k == 1 ? 'minute' : 'minutes', k >= 3 && k <= 10 ? 'دقائق' : 'دقيقة');
  String get waitingOff => t('Turn on to help them', 'فعّلي حالتكِ لمساعدتهن', 'فعّل حالتك لمساعدتهم');
  String get simulateCall => t('Try a practice call', 'جرّبي مكالمة تجريبية', 'جرّب مكالمة تجريبية');

  String get studentsSoonTitle => t('Your students will appear here', 'ستظهر طالباتكِ هنا', 'سيظهر طلابك هنا');
  String get studentsSoonBody => t(
    'After your first sessions, you can see each student\'s progress here.',
    'بعد أولى جلساتكِ، سترين تقدّم كل طالبة هنا.',
    'بعد أولى جلساتك، سترى تقدّم كل طالب هنا.',
  );

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
}
