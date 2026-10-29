part of '../strings.dart';

/// Teachers' notes, progress and lesson history.
extension LessonStrings on S {
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
  String juz(int k) => t('Juz $k', 'الجزء ${n(k)}');

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
}
