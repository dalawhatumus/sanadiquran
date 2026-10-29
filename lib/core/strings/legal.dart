part of '../strings.dart';

/// Terms of use and the teachers' code of conduct.
extension LegalStrings on S {
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
  String get codeTitle => t('Teacher code of conduct', 'قواعد السلوك للمعلّمين');
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
        'عند إساءة أي شخص: حظره والإبلاغ عنه. ويجوز للمشرفين إيقاف أي حساب يخالف هذه القواعد.',
      ),
    ),
  ];
}
