import 'quran_data.dart';

/// Finding a surah however its name is typed: in English or Arabic, with
/// or without "Surah" / "سورة" and "al-" / "ال", without dashes, accents or
/// apostrophes, with common spellings ("Yaseen", "Naas", "Rehman", "Kahaf"),
/// small typing slips, the English meaning ("The Cow"), other well-known
/// names ("Tabarak", "Amma"), or its number.
List<Sura> searchSurahs(QuranData q, String query) {
  final raw = query.trim();
  if (raw.isEmpty) return const [];
  final scored = <(int, Sura)>[];

  final number = int.tryParse(_westernDigits(raw).replaceAll(RegExp(r'[^0-9]'), ''));
  final onlyDigits = RegExp(r'^[0-9٠-٩۰-۹\s]+$').hasMatch(raw);

  if (onlyDigits) {
    if (number != null && number >= 1 && number <= q.suras.length) scored.add((0, q.sura(number)));
  } else if (_arabic.hasMatch(raw)) {
    final keys = _arabicKeys(raw);
    for (final s in q.suras) {
      final names = [s.ar, ...?_otherArabic[s.number]].expand(_arabicKeys).toSet();
      final score = _bestScore(keys.toSet(), names, fuzzy: false);
      if (score != null) scored.add((score, s));
    }
  } else {
    final keys = _latinKeys(raw);
    final words = _normalize(raw);
    for (final s in q.suras) {
      final names = [s.en, ...?_otherNames[s.number]].expand(_latinKeys).toSet();
      var score = _bestScore(keys.toSet(), names, fuzzy: true);
      // The English meaning, e.g. "cow", "the people", "friday".
      final meaning = _normalize(surahMeaningsEn[s.number - 1]);
      if (score == null && words.length >= 3 && meaning.contains(words)) score = 1000;
      if (score != null) scored.add((score, s));
    }
  }
  scored.sort((a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.number.compareTo(b.$2.number));
  // With a close match, leave out the far-fetched ones (so "nas" lists An-Nas
  // and An-Nasr, not every name with an n and an s).
  if (scored.isNotEmpty) {
    final best = scored.first.$1 ~/ 100;
    final limit = best <= 2 ? 4 : (best <= 5 ? 7 : 99);
    scored.removeWhere((x) => x.$1 ~/ 100 > limit && x.$1 < 1000);
    if (best <= 7) scored.removeWhere((x) => x.$1 >= 1000);
  }
  return [for (final (_, s) in scored) s];
}

/// How well any of the query's forms matches any of a surah's names (lower
/// is better), or null for no match. The hundreds say how it matched; the
/// rest how many letters differ, so "naas" ranks An-Nas above An-Nisa.
int? _bestScore(Set<String> query, Set<String> names, {required bool fuzzy}) {
  int? best;
  void take(int kind, String k, String n) {
    final score = kind * 100 + (fuzzy ? _letters(_simplify(k), _simplify(n)) : 0);
    if (best == null || score < best!) best = score;
  }

  for (final k in query) {
    if (k.isEmpty) continue;
    final sk = fuzzy ? _skeleton(k) : '';
    final simple = fuzzy ? _simplify(k) : k;
    for (final n in names) {
      if (n == k) {
        take(1, k, n);
      } else if (fuzzy && _simplify(n) == simple) {
        take(2, k, n);
      } else if (n.startsWith(k)) {
        take(3, k, n);
      } else if (fuzzy && simple.length >= 2 && _simplify(n).startsWith(simple)) {
        take(4, k, n);
      } else if (fuzzy && sk.length >= 2 && _skeleton(n) == sk) {
        take(5, k, n);
      } else if (k.length >= 3 && n.contains(k)) {
        take(6, k, n);
      } else if (fuzzy && sk.length >= 2 && _skeleton(n).startsWith(sk)) {
        take(7, k, n);
      } else if (fuzzy && k.length >= 4 && _distance(k, n, k.length >= 7 ? 2 : 1)) {
        take(8, k, n);
      } else if (fuzzy && k.length >= 4 && n.length > k.length && _distance(k, n.substring(0, k.length), 1)) {
        take(9, k, n);
      }
    }
  }
  return best;
}

// ---- English ----

const _accents = {
  'ā': 'a', 'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'ī': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', //
  'ū': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ō': 'o', 'ó': 'o', 'é': 'e', 'è': 'e', 'ē': 'e', //
  'ḥ': 'h', 'ḫ': 'kh', 'ṣ': 's', 'ḍ': 'd', 'ṭ': 't', 'ẓ': 'z', 'ġ': 'gh', 'ṯ': 'th', 'ḏ': 'dh',
};

/// Lower case, without accents, and only letters, digits and single spaces.
String _normalize(String s) {
  var x = s.toLowerCase();
  _accents.forEach((k, v) => x = x.replaceAll(k, v));
  x = x.replaceAll(RegExp('[‘’ʿʾ\'`´]'), '');
  x = x.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  return x;
}

final _surahWord = RegExp(r'^(surah|surat|sura|soorah|soora|surah?tul|suratu|suratul)\s*');
final _article = RegExp(r'^(al|el|an|ar|as|ash|at|ath|ad|adh|az|ul)\s+');

/// The forms a name or query is compared in: run together without spaces,
/// with and without "Surah" and the article.
Iterable<String> _latinKeys(String s) {
  var x = _normalize(s);
  x = x.replaceFirst(_surahWord, '');
  final keys = <String>{x.replaceAll(' ', '')};
  final noArticle = x.replaceFirst(_article, '');
  keys.add(noArticle.replaceAll(' ', ''));
  // "alnas", "alrahman": an article typed without a space.
  final joined = x.replaceAll(' ', '');
  for (final a in ['al', 'el']) {
    if (joined.startsWith(a) && joined.length > a.length + 2) keys.add(joined.substring(a.length));
  }
  return keys;
}

/// Common spellings made alike: long vowels written double ("naas",
/// "yaseen", "soorah"), doubled letters, and a final h after a vowel.
String _simplify(String s) {
  var x = s.replaceAll('ee', 'i').replaceAll('oo', 'u').replaceAll('ou', 'u').replaceAll('q', 'k');
  x = x.replaceAllMapped(RegExp(r'(.)\1+'), (m) => m[1]!);
  if (x.length > 3 && x.endsWith('h') && 'aeiou'.contains(x[x.length - 2])) x = x.substring(0, x.length - 1);
  return x;
}

/// How many letters differ between [a] and [b] (at most 99).
int _letters(String a, String b) {
  for (var d = 0; d < 99; d++) {
    if (_distance(a, b, d)) return d;
  }
  return 99;
}

/// The sound of a name without its vowels, so "yaseen", "yasin" and
/// "ya sin", or "rahman" and "rehman", come out the same.
String _skeleton(String s) {
  var x = s
      .replaceAll('kh', 'k')
      .replaceAll('gh', 'g')
      .replaceAll('dh', 'd')
      .replaceAll('th', 't')
      .replaceAll('q', 'k')
      .replaceAll('w', 'u');
  x = x.replaceAll(RegExp('[aeiou]'), '');
  // Doubled letters ("muzzammil", "naas") and a final h ("baqarah").
  x = x.replaceAllMapped(RegExp(r'(.)\1+'), (m) => m[1]!);
  if (x.length > 2 && x.endsWith('h')) x = x.substring(0, x.length - 1);
  return x;
}

/// Whether [a] and [b] differ by at most [max] typed letters.
bool _distance(String a, String b, int max) {
  if ((a.length - b.length).abs() > max) return false;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final cur = List<int>.filled(b.length + 1, 0)..[0] = i;
    var rowMin = cur[0];
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      cur[j] = [prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost].reduce((x, y) => x < y ? x : y);
      if (cur[j] < rowMin) rowMin = cur[j];
    }
    if (rowMin > max) return false;
    prev = cur;
  }
  return prev[b.length] <= max;
}

// ---- Arabic ----

final _arabic = RegExp('[؀-ۿ]');

/// Without vowel marks or tatweel, with the forms of alef, ta marbuta and
/// alef maqsura made alike, and without spaces.
String _arabicNormalize(String s) => s
    .replaceAll(RegExp('[ؐ-ًؚ-ٰٟۖ-ۭـ]'), '')
    .replaceAll(RegExp('[أإآٱ]'), 'ا')
    .replaceAll('ة', 'ه')
    .replaceAll('ى', 'ي')
    .replaceAll('ؤ', 'و')
    .replaceAll('ئ', 'ي')
    .replaceAll(RegExp(r'[^ء-ي0-9]'), '');

Iterable<String> _arabicKeys(String s) {
  var x = _arabicNormalize(s);
  if (x.startsWith('سوره')) x = x.substring(4);
  final keys = <String>{x};
  if (x.startsWith('ال') && x.length > 3) keys.add(x.substring(2));
  return keys;
}

/// Western digits for Arabic-Indic and Persian ones.
String _westernDigits(String s) => s.replaceAllMapped(RegExp('[٠-٩۰-۹]'), (m) {
  final c = m[0]!.codeUnitAt(0);
  return '${c >= 0x06F0 ? c - 0x06F0 : c - 0x0660}';
});

/// Other names surahs are widely known by.
const _otherNames = <int, List<String>>{
  1: ['Al-Fatiha', 'Al-Hamd', 'Umm al-Kitab'],
  9: ['Al-Tawbah', 'Bara\'ah'],
  17: ['Bani Israil'],
  40: ['Al-Mu\'min'],
  41: ['Ha Mim Sajdah'],
  47: ['Al-Qital'],
  67: ['Tabarak'],
  76: ['Ad-Dahr'],
  78: ['Amma'],
  94: ['Al-Inshirah', 'Alam Nashrah'],
  106: ['Quraysh'],
  108: ['Al-Kawthar'],
  111: ['Al-Lahab', 'Tabbat'],
  112: ['At-Tawhid'],
};

const _otherArabic = <int, List<String>>{
  1: ['الحمد', 'أم الكتاب'],
  9: ['براءة'],
  17: ['بني إسرائيل'],
  40: ['المؤمن'],
  41: ['حم السجدة'],
  47: ['القتال'],
  67: ['تبارك'],
  76: ['الدهر'],
  78: ['عم'],
  94: ['الانشراح', 'ألم نشرح'],
  111: ['اللهب', 'تبت'],
};

/// The usual English meanings of the surah names.
const surahMeaningsEn = <String>[
  'The Opening', 'The Cow', 'The Family of Imran', 'The Women', 'The Table Spread', 'The Cattle', //
  'The Heights', 'The Spoils of War', 'The Repentance', 'Jonah', 'Hud', 'Joseph', 'The Thunder', //
  'Abraham', 'The Rocky Tract', 'The Bee', 'The Night Journey', 'The Cave', 'Mary', 'Ta-Ha', //
  'The Prophets', 'The Pilgrimage', 'The Believers', 'The Light', 'The Criterion', 'The Poets', //
  'The Ant', 'The Stories', 'The Spider', 'The Romans', 'Luqman', 'The Prostration', //
  'The Combined Forces', 'Sheba', 'The Originator', 'Ya-Sin', 'Those Who Set the Ranks', 'Sad', //
  'The Troops', 'The Forgiver', 'Explained in Detail', 'The Consultation', 'The Ornaments of Gold', //
  'The Smoke', 'The Kneeling', 'The Wind-Curved Sandhills', 'Muhammad', 'The Victory', 'The Rooms', //
  'Qaf', 'The Winnowing Winds', 'The Mount', 'The Star', 'The Moon', 'The Most Merciful', //
  'The Inevitable', 'The Iron', 'The Pleading Woman', 'The Exile', 'The Woman to Be Examined', //
  'The Ranks', 'Friday, The Congregation', 'The Hypocrites', 'The Mutual Loss and Gain', 'The Divorce', //
  'The Prohibition', 'The Sovereignty, The Kingdom', 'The Pen', 'The Reality', 'The Ascending Stairways', //
  'Noah', 'The Jinn', 'The Wrapped One', 'The Cloaked One', 'The Resurrection', 'Man', //
  'Those Sent Forth', 'The Great News', 'Those Who Pull Out', 'He Frowned', 'The Folding Up', //
  'The Cleaving', 'Those Who Give Short Measure', 'The Splitting Open', 'The Great Stars', //
  'The Night Visitor', 'The Most High', 'The Overwhelming Event', 'The Dawn', 'The City', 'The Sun', //
  'The Night', 'The Morning Brightness', 'The Relief, The Opening Up', 'The Fig', 'The Clinging Clot', //
  'The Night of Power, Decree', 'The Clear Evidence', 'The Earthquake', 'The Running Horses', //
  'The Striking Calamity', 'The Competition for More', 'Time, The Declining Day', 'The Slanderer', //
  'The Elephant', 'Quraysh', 'Small Kindnesses', 'Abundance', 'The Disbelievers', 'The Help, Victory', //
  'The Palm Fibre, Flame', 'Sincerity, Purity of Faith', 'The Daybreak', 'Mankind, The People',
];
