part of '../strings.dart';

/// Messages, chat, voice notes, reporting and blocking.
extension MessageStrings on S {
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
  String voiceNoteLen(int sec) => t('Voice note · ${S._mmss(sec)}', 'رسالة صوتية · ${n(S._mmss(sec))}');
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
}
