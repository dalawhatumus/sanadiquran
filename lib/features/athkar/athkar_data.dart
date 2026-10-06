/// Athkar from Hisn al-Muslim. Quranic passages are referenced by sura and
/// ayah and drawn from the KFGQPC Quran text, never retyped.
///
/// Before public release, have a qualified person check every text and
/// source against a printed Hisn al-Muslim.
class Dhikr {
  const Dhikr({
    this.ar,
    this.quran,
    required this.count,
    this.meaning = '',
    this.translit = '',
    required this.sourceEn,
    required this.sourceAr,
  });

  /// Arabic text (Noto Naskh). Null when this is a Quran passage.
  final String? ar;

  /// (sura, from ayah, to ayah) when this is a Quran passage.
  final (int, int, int)? quran;
  final int count;
  final String meaning;
  final String translit;
  final String sourceEn;
  final String sourceAr;
}

class AthkarSet {
  const AthkarSet(this.id, this.en, this.ar, this.items);

  final String id;
  final String en;
  final String ar;
  final List<Dhikr> items;

  int get total => items.length;
}

const _kursi = Dhikr(
  quran: (2, 255, 255),
  count: 1,
  meaning: 'Ayat al-Kursi (al-Baqarah 2:255).',
  sourceEn: 'An-Nasa\'i (al-Kubra) · al-Hakim',
  sourceAr: 'رواه النسائي في الكبرى والحاكم',
);

const _quls = [
  Dhikr(
    quran: (112, 1, 4),
    count: 3,
    meaning: 'Surah al-Ikhlas (112).',
    sourceEn: 'Abu Dawud 5082 · Tirmidhi 3575',
    sourceAr: 'رواه أبو داود (٥٠٨٢) والترمذي (٣٥٧٥)',
  ),
  Dhikr(
    quran: (113, 1, 5),
    count: 3,
    meaning: 'Surah al-Falaq (113).',
    sourceEn: 'Abu Dawud 5082 · Tirmidhi 3575',
    sourceAr: 'رواه أبو داود (٥٠٨٢) والترمذي (٣٥٧٥)',
  ),
  Dhikr(
    quran: (114, 1, 6),
    count: 3,
    meaning: 'Surah an-Nas (114).',
    sourceEn: 'Abu Dawud 5082 · Tirmidhi 3575',
    sourceAr: 'رواه أبو داود (٥٠٨٢) والترمذي (٣٥٧٥)',
  ),
];

const _bismillahNoHarm = Dhikr(
  ar: 'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ',
  count: 3,
  meaning: 'In the name of Allah, with whose name nothing on earth or in the heavens can cause harm, and He is the All-Hearing, the All-Knowing.',
  translit: 'Bismillāhil-ladhī lā yaḍurru maʿa-smihī shayʾun fil-arḍi wa lā fis-samāʾi wa huwas-samīʿul-ʿalīm.',
  sourceEn: 'Abu Dawud 5088 · Tirmidhi 3388',
  sourceAr: 'رواه أبو داود (٥٠٨٨) والترمذي (٣٣٨٨)',
);

const _sayyidIstighfar = Dhikr(
  ar:
      'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، '
      'أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي، فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ',
  count: 1,
  meaning:
      'O Allah, You are my Lord, there is no god but You. You created me and I am Your servant, and I keep Your covenant and promise as best I can. '
      'I seek refuge in You from the evil I have done. I acknowledge Your favour upon me and I acknowledge my sin, so forgive me, for none forgives sins but You.',
  translit:
      'Allāhumma anta rabbī lā ilāha illā ant, khalaqtanī wa ana ʿabduk, wa ana ʿalā ʿahdika wa waʿdika mastaṭaʿt, aʿūdhu bika min sharri mā ṣanaʿt, '
      'abūʾu laka bi-niʿmatika ʿalayy, wa abūʾu bi-dhanbī faghfir lī, fa-innahu lā yaghfirudh-dhunūba illā ant.',
  sourceEn: 'Bukhari 6306',
  sourceAr: 'رواه البخاري (٦٣٠٦)',
);

const _raditu = Dhikr(
  ar: 'رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ نَبِيًّا',
  count: 3,
  meaning: 'I am pleased with Allah as my Lord, with Islam as my religion, and with Muhammad ﷺ as my Prophet.',
  translit: 'Raḍītu billāhi rabbā, wa bil-islāmi dīnā, wa bi-Muḥammadin ṣallallāhu ʿalayhi wa sallama nabiyyā.',
  sourceEn: 'Abu Dawud 5072',
  sourceAr: 'رواه أبو داود (٥٠٧٢)',
);

const _yaHayy = Dhikr(
  ar: 'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ، وَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ',
  count: 1,
  meaning: 'O Ever-Living, O Sustainer of all, by Your mercy I seek help. Set right all my affairs, and do not leave me to myself even for the blink of an eye.',
  translit: 'Yā Ḥayyu yā Qayyūm, bi-raḥmatika astaghīth, aṣliḥ lī shaʾnī kullah, wa lā takilnī ilā nafsī ṭarfata ʿayn.',
  sourceEn: 'An-Nasa\'i (al-Kubra) · al-Hakim',
  sourceAr: 'رواه النسائي في الكبرى والحاكم',
);

const _hasbiya = Dhikr(
  ar: 'حَسْبِيَ اللَّهُ لَا إِلَهَ إِلَّا هُوَ، عَلَيْهِ تَوَكَّلْتُ، وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ',
  count: 7,
  meaning: 'Allah is sufficient for me. There is no god but Him. In Him I put my trust, and He is the Lord of the Mighty Throne.',
  translit: 'Ḥasbiyallāhu lā ilāha illā huw, ʿalayhi tawakkaltu wa huwa rabbul-ʿarshil-ʿaẓīm.',
  sourceEn: 'Abu Dawud 5081',
  sourceAr: 'رواه أبو داود (٥٠٨١)',
);

const _subhanBihamdihi = Dhikr(
  ar: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
  count: 100,
  meaning: 'Glory be to Allah, and praise be to Him.',
  translit: 'Subḥānallāhi wa bi-ḥamdih.',
  sourceEn: 'Muslim 2692',
  sourceAr: 'رواه مسلم (٢٦٩٢)',
);

const _tahlil10 = Dhikr(
  ar: 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
  count: 10,
  meaning: 'There is no god but Allah alone, with no partner. His is the dominion and His is the praise, and He has power over all things.',
  translit: 'Lā ilāha illallāhu waḥdahu lā sharīka lah, lahul-mulku wa lahul-ḥamd, wa huwa ʿalā kulli shayʾin qadīr.',
  sourceEn: 'Ahmad · An-Nasa\'i (al-Kubra)',
  sourceAr: 'رواه أحمد والنسائي في الكبرى',
);

const _morning = AthkarSet('morning', 'Morning athkar', 'أذكار الصباح', [
  _kursi,
  ..._quls,
  Dhikr(
    ar:
        'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، '
        'رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذَا الْيَوْمِ وَخَيْرَ مَا بَعْدَهُ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذَا الْيَوْمِ وَشَرِّ مَا بَعْدَهُ، '
        'رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ',
    count: 1,
    meaning:
        'We have entered the morning, and the dominion belongs to Allah, and all praise is for Allah. There is no god but Allah alone, with no partner. '
        'His is the dominion and His is the praise, and He has power over all things. My Lord, I ask You for the good of this day and what follows it, '
        'and I seek refuge in You from the evil of this day and what follows it. My Lord, I seek refuge in You from laziness and the hardship of old age. '
        'My Lord, I seek refuge in You from punishment in the Fire and punishment in the grave.',
    translit:
        'Aṣbaḥnā wa aṣbaḥal-mulku lillāh, wal-ḥamdu lillāh, lā ilāha illallāhu waḥdahu lā sharīka lah, lahul-mulku wa lahul-ḥamdu wa huwa ʿalā kulli shayʾin qadīr. '
        'Rabbi asʾaluka khayra mā fī hādhal-yawmi wa khayra mā baʿdah, wa aʿūdhu bika min sharri mā fī hādhal-yawmi wa sharri mā baʿdah. '
        'Rabbi aʿūdhu bika minal-kasali wa sūʾil-kibar. Rabbi aʿūdhu bika min ʿadhābin fin-nāri wa ʿadhābin fil-qabr.',
    sourceEn: 'Muslim 2723',
    sourceAr: 'رواه مسلم (٢٧٢٣)',
  ),
  Dhikr(
    ar: 'اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ النُّشُورُ',
    count: 1,
    meaning: 'O Allah, by You we enter the morning and by You we enter the evening, by You we live and by You we die, and to You is the resurrection.',
    translit: 'Allāhumma bika aṣbaḥnā, wa bika amsaynā, wa bika naḥyā, wa bika namūtu, wa ilaykan-nushūr.',
    sourceEn: 'Tirmidhi 3391',
    sourceAr: 'رواه الترمذي (٣٣٩١)',
  ),
  _sayyidIstighfar,
  _bismillahNoHarm,
  _raditu,
  _yaHayy,
  _hasbiya,
  _tahlil10,
  _subhanBihamdihi,
]);

const _evening = AthkarSet('evening', 'Evening athkar', 'أذكار المساء', [
  _kursi,
  ..._quls,
  Dhikr(
    ar:
        'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، '
        'رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذِهِ اللَّيْلَةِ وَخَيْرَ مَا بَعْدَهَا، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذِهِ اللَّيْلَةِ وَشَرِّ مَا بَعْدَهَا، '
        'رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ',
    count: 1,
    meaning:
        'We have entered the evening, and the dominion belongs to Allah, and all praise is for Allah. There is no god but Allah alone, with no partner. '
        'His is the dominion and His is the praise, and He has power over all things. My Lord, I ask You for the good of this night and what follows it, '
        'and I seek refuge in You from the evil of this night and what follows it. My Lord, I seek refuge in You from laziness and the hardship of old age. '
        'My Lord, I seek refuge in You from punishment in the Fire and punishment in the grave.',
    translit:
        'Amsaynā wa amsal-mulku lillāh, wal-ḥamdu lillāh, lā ilāha illallāhu waḥdahu lā sharīka lah, lahul-mulku wa lahul-ḥamdu wa huwa ʿalā kulli shayʾin qadīr. '
        'Rabbi asʾaluka khayra mā fī hādhihil-laylati wa khayra mā baʿdahā, wa aʿūdhu bika min sharri mā fī hādhihil-laylati wa sharri mā baʿdahā. '
        'Rabbi aʿūdhu bika minal-kasali wa sūʾil-kibar. Rabbi aʿūdhu bika min ʿadhābin fin-nāri wa ʿadhābin fil-qabr.',
    sourceEn: 'Muslim 2723',
    sourceAr: 'رواه مسلم (٢٧٢٣)',
  ),
  Dhikr(
    ar: 'اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ الْمَصِيرُ',
    count: 1,
    meaning: 'O Allah, by You we enter the evening and by You we enter the morning, by You we live and by You we die, and to You is the return.',
    translit: 'Allāhumma bika amsaynā, wa bika aṣbaḥnā, wa bika naḥyā, wa bika namūtu, wa ilaykal-maṣīr.',
    sourceEn: 'Tirmidhi 3391',
    sourceAr: 'رواه الترمذي (٣٣٩١)',
  ),
  _sayyidIstighfar,
  _bismillahNoHarm,
  Dhikr(
    ar: 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
    count: 3,
    meaning: 'I seek refuge in the perfect words of Allah from the evil of what He has created.',
    translit: 'Aʿūdhu bi-kalimātillāhit-tāmmāti min sharri mā khalaq.',
    sourceEn: 'Muslim 2709',
    sourceAr: 'رواه مسلم (٢٧٠٩)',
  ),
  _raditu,
  _yaHayy,
  _hasbiya,
  _tahlil10,
  _subhanBihamdihi,
]);

const _tasbeeh33 = [
  Dhikr(
    ar: 'سُبْحَانَ اللَّهِ',
    count: 33,
    meaning: 'Glory be to Allah.',
    translit: 'Subḥānallāh.',
    sourceEn: 'Muslim 597',
    sourceAr: 'رواه مسلم (٥٩٧)',
  ),
  Dhikr(
    ar: 'الْحَمْدُ لِلَّهِ',
    count: 33,
    meaning: 'All praise is for Allah.',
    translit: 'Al-ḥamdu lillāh.',
    sourceEn: 'Muslim 597',
    sourceAr: 'رواه مسلم (٥٩٧)',
  ),
  Dhikr(
    ar: 'اللَّهُ أَكْبَرُ',
    count: 33,
    meaning: 'Allah is the Greatest.',
    translit: 'Allāhu akbar.',
    sourceEn: 'Muslim 597',
    sourceAr: 'رواه مسلم (٥٩٧)',
  ),
];

const _salah = AthkarSet('salah', 'After salah', 'الأذكار بعد الصلاة', [
  Dhikr(
    ar: 'أَسْتَغْفِرُ اللَّهَ',
    count: 3,
    meaning: 'I seek the forgiveness of Allah.',
    translit: 'Astaghfirullāh.',
    sourceEn: 'Muslim 591',
    sourceAr: 'رواه مسلم (٥٩١)',
  ),
  Dhikr(
    ar: 'اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
    count: 1,
    meaning: 'O Allah, You are Peace and from You is peace. Blessed are You, O Owner of majesty and honour.',
    translit: 'Allāhumma antas-salāmu wa minkas-salām, tabārakta yā dhal-jalāli wal-ikrām.',
    sourceEn: 'Muslim 591',
    sourceAr: 'رواه مسلم (٥٩١)',
  ),
  Dhikr(
    ar:
        'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، '
        'اللَّهُمَّ لَا مَانِعَ لِمَا أَعْطَيْتَ، وَلَا مُعْطِيَ لِمَا مَنَعْتَ، وَلَا يَنْفَعُ ذَا الْجَدِّ مِنْكَ الْجَدُّ',
    count: 1,
    meaning:
        'There is no god but Allah alone, with no partner. His is the dominion and His is the praise, and He has power over all things. '
        'O Allah, none can withhold what You give, none can give what You withhold, and the wealth of the wealthy cannot avail him against You.',
    translit:
        'Lā ilāha illallāhu waḥdahu lā sharīka lah, lahul-mulku wa lahul-ḥamdu wa huwa ʿalā kulli shayʾin qadīr. '
        'Allāhumma lā māniʿa limā aʿṭayt, wa lā muʿṭiya limā manaʿt, wa lā yanfaʿu dhal-jaddi minkal-jadd.',
    sourceEn: 'Bukhari 844 · Muslim 593',
    sourceAr: 'رواه البخاري (٨٤٤) ومسلم (٥٩٣)',
  ),
  ..._tasbeeh33,
  Dhikr(
    ar: 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
    count: 1,
    meaning: 'There is no god but Allah alone, with no partner. His is the dominion and His is the praise, and He has power over all things.',
    translit: 'Lā ilāha illallāhu waḥdahu lā sharīka lah, lahul-mulku wa lahul-ḥamdu wa huwa ʿalā kulli shayʾin qadīr.',
    sourceEn: 'Muslim 597',
    sourceAr: 'رواه مسلم (٥٩٧)',
  ),
  _kursi,
]);

const _tasbeeh = AthkarSet('tasbeeh', 'Tasbeeh', 'التسبيح', [
  ..._tasbeeh33,
  Dhikr(
    ar: 'لَا إِلَهَ إِلَّا اللَّهُ',
    count: 33,
    meaning: 'There is no god but Allah.',
    translit: 'Lā ilāha illallāh.',
    sourceEn: 'Tirmidhi 3383',
    sourceAr: 'رواه الترمذي (٣٣٨٣)',
  ),
  Dhikr(
    ar: 'أَسْتَغْفِرُ اللَّهَ',
    count: 33,
    meaning: 'I seek the forgiveness of Allah.',
    translit: 'Astaghfirullāh.',
    sourceEn: 'Muslim 2702',
    sourceAr: 'رواه مسلم (٢٧٠٢)',
  ),
]);

const _sleep = AthkarSet('sleep', 'Before sleep', 'أذكار النوم', [
  Dhikr(
    quran: (2, 255, 255),
    count: 1,
    meaning: 'Ayat al-Kursi (al-Baqarah 2:255).',
    sourceEn: 'Bukhari 2311',
    sourceAr: 'رواه البخاري (٢٣١١)',
  ),
  Dhikr(
    quran: (2, 285, 286),
    count: 1,
    meaning: 'The last two ayahs of al-Baqarah (2:285–286).',
    sourceEn: 'Bukhari 5009',
    sourceAr: 'رواه البخاري (٥٠٠٩)',
  ),
  Dhikr(
    quran: (112, 1, 4),
    count: 3,
    meaning: 'Surah al-Ikhlas (112), then blow into the palms and wipe over the body.',
    sourceEn: 'Bukhari 5017',
    sourceAr: 'رواه البخاري (٥٠١٧)',
  ),
  Dhikr(
    quran: (113, 1, 5),
    count: 3,
    meaning: 'Surah al-Falaq (113).',
    sourceEn: 'Bukhari 5017',
    sourceAr: 'رواه البخاري (٥٠١٧)',
  ),
  Dhikr(
    quran: (114, 1, 6),
    count: 3,
    meaning: 'Surah an-Nas (114).',
    sourceEn: 'Bukhari 5017',
    sourceAr: 'رواه البخاري (٥٠١٧)',
  ),
  Dhikr(
    ar: 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
    count: 1,
    meaning: 'In Your name, O Allah, I die and I live.',
    translit: 'Bismika Allāhumma amūtu wa aḥyā.',
    sourceEn: 'Bukhari 6324',
    sourceAr: 'رواه البخاري (٦٣٢٤)',
  ),
  Dhikr(
    ar: 'اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ',
    count: 3,
    meaning: 'O Allah, protect me from Your punishment on the Day You resurrect Your servants.',
    translit: 'Allāhumma qinī ʿadhābaka yawma tabʿathu ʿibādak.',
    sourceEn: 'Abu Dawud 5045',
    sourceAr: 'رواه أبو داود (٥٠٤٥)',
  ),
  Dhikr(
    ar: 'سُبْحَانَ اللَّهِ',
    count: 33,
    meaning: 'Glory be to Allah.',
    translit: 'Subḥānallāh.',
    sourceEn: 'Bukhari 3705 · Muslim 2727',
    sourceAr: 'رواه البخاري (٣٧٠٥) ومسلم (٢٧٢٧)',
  ),
  Dhikr(
    ar: 'الْحَمْدُ لِلَّهِ',
    count: 33,
    meaning: 'All praise is for Allah.',
    translit: 'Al-ḥamdu lillāh.',
    sourceEn: 'Bukhari 3705 · Muslim 2727',
    sourceAr: 'رواه البخاري (٣٧٠٥) ومسلم (٢٧٢٧)',
  ),
  Dhikr(
    ar: 'اللَّهُ أَكْبَرُ',
    count: 34,
    meaning: 'Allah is the Greatest.',
    translit: 'Allāhu akbar.',
    sourceEn: 'Bukhari 3705 · Muslim 2727',
    sourceAr: 'رواه البخاري (٣٧٠٥) ومسلم (٢٧٢٧)',
  ),
]);

const _waking = AthkarSet('waking', 'On waking', 'أذكار الاستيقاظ', [
  Dhikr(
    ar: 'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ',
    count: 1,
    meaning: 'All praise is for Allah, who gave us life after He caused us to die, and to Him is the resurrection.',
    translit: 'Al-ḥamdu lillāhil-ladhī aḥyānā baʿda mā amātanā wa ilayhin-nushūr.',
    sourceEn: 'Bukhari 6312',
    sourceAr: 'رواه البخاري (٦٣١٢)',
  ),
  Dhikr(
    ar:
        'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، '
        'سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلَا إِلَهَ إِلَّا اللَّهُ، وَاللَّهُ أَكْبَرُ، وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ، اللَّهُمَّ اغْفِرْ لِي',
    count: 1,
    meaning:
        'There is no god but Allah alone, with no partner. His is the dominion and His is the praise, and He has power over all things. '
        'Glory be to Allah, all praise is for Allah, there is no god but Allah, Allah is the Greatest, and there is no power and no strength except through Allah. O Allah, forgive me.',
    translit:
        'Lā ilāha illallāhu waḥdahu lā sharīka lah, lahul-mulku wa lahul-ḥamd, wa huwa ʿalā kulli shayʾin qadīr. '
        'Subḥānallāh, wal-ḥamdu lillāh, wa lā ilāha illallāh, wallāhu akbar, wa lā ḥawla wa lā quwwata illā billāh. Allāhummaghfir lī.',
    sourceEn: 'Bukhari 1154',
    sourceAr: 'رواه البخاري (١١٥٤)',
  ),
]);

const athkarSets = [_morning, _evening, _salah, _tasbeeh, _sleep, _waking];

AthkarSet athkarSet(String id) => athkarSets.firstWhere((s) => s.id == id, orElse: () => _morning);
