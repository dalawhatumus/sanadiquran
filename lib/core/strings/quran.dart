part of '../strings.dart';

/// The mushaf, recitation, athkar and their reminders, Ayah of the day, surah search and auto scroll.
extension QuranStrings on S {
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
