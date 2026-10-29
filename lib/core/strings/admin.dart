part of '../strings.dart';

/// Admin screens: applications, people, pausing, the overview, connecting and reports.
extension AdminStrings on S {
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
  String get statLessons => t('Lessons in the last 7 days', 'دروس آخر ${n(7)} أيام');
  String get statMinutes => t('Minutes taught in the last 7 days', 'دقائق التدريس آخر ${n(7)} أيام');
  String get refresh => t('Refresh', 'تحديث');

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
  String get decisionFailed => t(
    "Couldn't save. Check the internet and try again.",
    'تعذّر الحفظ. تحقّقي من الإنترنت وحاولي مجددًا.',
    'تعذّر الحفظ. تحقّق من الإنترنت وحاول مجددًا.',
  );
}
