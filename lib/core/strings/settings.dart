part of '../strings.dart';

/// Settings (language, appearance, account), help, the privacy policy and profile pictures.
extension SettingsStrings on S {
  // ---- Settings: language, appearance, account, testing ----
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
  String get remindersOffSub => t('Off', 'متوقّف');

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
        'يمكنكِ تغيير اسمكِ أو صورتكِ أو بياناتكِ من الإعدادات، وحذف حسابكِ في أي وقت. لأي سؤال اضغطي «تواصلي معنا» في الأسفل.',
        'يمكنك تغيير اسمك أو صورتك أو بياناتك من الإعدادات، وحذف حسابك في أي وقت. لأي سؤال اضغط «تواصل معنا» في الأسفل.',
      ),
    ),
  ];

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
}
