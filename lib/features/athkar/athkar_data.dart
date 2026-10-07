/// Athkar from Hisn al-Muslim (Sa'id al-Qahtani). Quranic passages are
/// referenced by sura and ayah and drawn from the KFGQPC Quran text, never
/// retyped.
///
/// A virtue (fadl) is shown only where it comes from a hadith in Bukhari or
/// Muslim, or one graded sahih or hasan; it is left out where the narration
/// is graded weak. Before public release, have a qualified person check every
/// text, source and virtue against a printed Hisn al-Muslim.
class Dhikr {
  const Dhikr({
    this.ar,
    this.quran,
    required this.count,
    this.meaning = '',
    this.translit = '',
    required this.sourceEn,
    required this.sourceAr,
    this.fadlEn = '',
    this.fadlAr = '',
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

  /// Its reward or benefit, from the hadith; empty when none is shown.
  final String fadlEn;
  final String fadlAr;
}

class AthkarSet {
  const AthkarSet(this.id, this.en, this.ar, this.items);

  final String id;
  final String en;
  final String ar;
  final List<Dhikr> items;

  int get total => items.length;
}

// ---------------------------------------------------------------------------
// Morning and evening (shared items)
// ---------------------------------------------------------------------------

Dhikr _kursiFor(bool morning) => Dhikr(
  quran: (2, 255, 255),
  count: 1,
  meaning: 'Ayat al-Kursi (al-Baqarah 2:255).',
  sourceEn: 'Al-Hakim · An-Nasa\'i (al-Kubra) — sahih (al-Albani)',
  sourceAr: 'رواه الحاكم والنسائي في الكبرى، وصحّحه الألباني',
  fadlEn: morning
      ? 'Whoever recites it in the morning is protected from the jinn until evening.'
      : 'Whoever recites it in the evening is protected from the jinn until morning.',
  fadlAr: morning ? 'من قرأها حين يصبح أُجير من الجن حتى يمسي.' : 'من قرأها حين يمسي أُجير من الجن حتى يصبح.',
);

const _qulFadlEn = 'Recited three times morning and evening, they will suffice you against everything.';
const _qulFadlAr = 'من قرأها ثلاث مرات حين يمسي وحين يصبح كفته من كل شيء.';
const _qulSrcEn = 'Abu Dawud 5082 · Tirmidhi 3575 (hasan sahih)';
const _qulSrcAr = 'رواه أبو داود (٥٠٨٢) والترمذي (٣٥٧٥)';

const _quls = [
  Dhikr(
    quran: (112, 1, 4),
    count: 3,
    meaning: 'Surah al-Ikhlas (112).',
    sourceEn: _qulSrcEn,
    sourceAr: _qulSrcAr,
    fadlEn: _qulFadlEn,
    fadlAr: _qulFadlAr,
  ),
  Dhikr(
    quran: (113, 1, 5),
    count: 3,
    meaning: 'Surah al-Falaq (113).',
    sourceEn: _qulSrcEn,
    sourceAr: _qulSrcAr,
    fadlEn: _qulFadlEn,
    fadlAr: _qulFadlAr,
  ),
  Dhikr(
    quran: (114, 1, 6),
    count: 3,
    meaning: 'Surah an-Nas (114).',
    sourceEn: _qulSrcEn,
    sourceAr: _qulSrcAr,
    fadlEn: _qulFadlEn,
    fadlAr: _qulFadlAr,
  ),
];

Dhikr _mulkFor(bool m) => Dhikr(
  ar: m
      ? 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، '
            'رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذَا الْيَوْمِ وَخَيْرَ مَا بَعْدَهُ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذَا الْيَوْمِ وَشَرِّ مَا بَعْدَهُ، '
            'رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ'
      : 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، '
            'رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذِهِ اللَّيْلَةِ وَخَيْرَ مَا بَعْدَهَا، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذِهِ اللَّيْلَةِ وَشَرِّ مَا بَعْدَهَا، '
            'رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ',
  count: 1,
  meaning:
      'We have entered the ${m ? 'morning' : 'evening'}, and the dominion belongs to Allah, and all praise is for Allah. '
      'There is no god but Allah alone, with no partner. His is the dominion and His is the praise, and He has power over all things. '
      'My Lord, I ask You for the good of this ${m ? 'day' : 'night'} and what follows it, and I seek refuge in You from the evil of this ${m ? 'day' : 'night'} and what follows it. '
      'My Lord, I seek refuge in You from laziness and the hardship of old age. My Lord, I seek refuge in You from punishment in the Fire and punishment in the grave.',
  translit:
      '${m ? 'Aṣbaḥnā wa aṣbaḥal' : 'Amsaynā wa amsal'}-mulku lillāh, wal-ḥamdu lillāh, lā ilāha illallāhu waḥdahu lā sharīka lah, '
      'lahul-mulku wa lahul-ḥamdu wa huwa ʿalā kulli shayʾin qadīr. Rabbi asʾaluka khayra mā fī '
      '${m ? 'hādhal-yawmi wa khayra mā baʿdah, wa aʿūdhu bika min sharri mā fī hādhal-yawmi wa sharri mā baʿdah' : 'hādhihil-laylati wa khayra mā baʿdahā, wa aʿūdhu bika min sharri mā fī hādhihil-laylati wa sharri mā baʿdahā'}. '
      'Rabbi aʿūdhu bika minal-kasali wa sūʾil-kibar. Rabbi aʿūdhu bika min ʿadhābin fin-nāri wa ʿadhābin fil-qabr.',
  sourceEn: 'Muslim 2723',
  sourceAr: 'رواه مسلم (٢٧٢٣)',
);

Dhikr _bikaFor(bool m) => Dhikr(
  ar: m
      ? 'اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ النُّشُورُ'
      : 'اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ الْمَصِيرُ',
  count: 1,
  meaning: m
      ? 'O Allah, by You we enter the morning and by You we enter the evening, by You we live and by You we die, and to You is the resurrection.'
      : 'O Allah, by You we enter the evening and by You we enter the morning, by You we live and by You we die, and to You is the return.',
  translit: m
      ? 'Allāhumma bika aṣbaḥnā, wa bika amsaynā, wa bika naḥyā, wa bika namūtu, wa ilaykan-nushūr.'
      : 'Allāhumma bika amsaynā, wa bika aṣbaḥnā, wa bika naḥyā, wa bika namūtu, wa ilaykal-maṣīr.',
  sourceEn: 'Tirmidhi 3391 (hasan)',
  sourceAr: 'رواه الترمذي (٣٣٩١)',
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
  fadlEn: 'Whoever says it with certainty during the day and dies before evening is among the people of Paradise; and the same for the night.',
  fadlAr: 'من قالها من النهار موقنًا بها فمات من يومه قبل أن يمسي فهو من أهل الجنة، ومن قالها من الليل موقنًا بها فمات قبل أن يصبح فهو من أهل الجنة.',
);

Dhikr _ushhiduFor(bool m) => Dhikr(
  ar:
      'اللَّهُمَّ إِنِّي ${m ? 'أَصْبَحْتُ' : 'أَمْسَيْتُ'} أُشْهِدُكَ، وَأُشْهِدُ حَمَلَةَ عَرْشِكَ، وَمَلَائِكَتَكَ، وَجَمِيعَ خَلْقِكَ، '
      'أَنَّكَ أَنْتَ اللَّهُ لَا إِلَهَ إِلَّا أَنْتَ وَحْدَكَ لَا شَرِيكَ لَكَ، وَأَنَّ مُحَمَّدًا عَبْدُكَ وَرَسُولُكَ',
  count: 4,
  meaning:
      'O Allah, I have entered the ${m ? 'morning' : 'evening'} calling You, the bearers of Your Throne, Your angels and all Your creation to witness '
      'that You are Allah, there is no god but You alone, with no partner, and that Muhammad is Your servant and Messenger.',
  translit:
      'Allāhumma innī ${m ? 'aṣbaḥtu' : 'amsaytu'} ushhiduka wa ushhidu ḥamalata ʿarshik, wa malāʾikatak, wa jamīʿa khalqik, '
      'annaka antallāhu lā ilāha illā anta waḥdaka lā sharīka lak, wa anna Muḥammadan ʿabduka wa rasūluk.',
  sourceEn: 'Abu Dawud 5069',
  sourceAr: 'رواه أبو داود (٥٠٦٩)',
);

Dhikr _nimaFor(bool m) => Dhikr(
  ar: 'اللَّهُمَّ مَا ${m ? 'أَصْبَحَ' : 'أَمْسَى'} بِي مِنْ نِعْمَةٍ أَوْ بِأَحَدٍ مِنْ خَلْقِكَ فَمِنْكَ وَحْدَكَ لَا شَرِيكَ لَكَ، فَلَكَ الْحَمْدُ وَلَكَ الشُّكْرُ',
  count: 1,
  meaning:
      'O Allah, whatever blessing I or any of Your creation have this ${m ? 'morning' : 'evening'} is from You alone, with no partner. '
      'To You is all praise and to You is all thanks.',
  translit:
      'Allāhumma mā ${m ? 'aṣbaḥa' : 'amsā'} bī min niʿmatin aw bi-aḥadin min khalqik, fa-minka waḥdaka lā sharīka lak, fa-lakal-ḥamdu wa lakash-shukr.',
  sourceEn: 'Abu Dawud 5073',
  sourceAr: 'رواه أبو داود (٥٠٧٣)',
);

const _afini = Dhikr(
  ar:
      'اللَّهُمَّ عَافِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي، اللَّهُمَّ عَافِنِي فِي بَصَرِي، لَا إِلَهَ إِلَّا أَنْتَ. '
      'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْكُفْرِ وَالْفَقْرِ، وَأَعُوذُ بِكَ مِنْ عَذَابِ الْقَبْرِ، لَا إِلَهَ إِلَّا أَنْتَ',
  count: 3,
  meaning:
      'O Allah, grant me health in my body. O Allah, grant me health in my hearing. O Allah, grant me health in my sight. There is no god but You. '
      'O Allah, I seek refuge in You from disbelief and poverty, and I seek refuge in You from the punishment of the grave. There is no god but You.',
  translit:
      'Allāhumma ʿāfinī fī badanī, Allāhumma ʿāfinī fī samʿī, Allāhumma ʿāfinī fī baṣarī, lā ilāha illā ant. '
      'Allāhumma innī aʿūdhu bika minal-kufri wal-faqr, wa aʿūdhu bika min ʿadhābil-qabr, lā ilāha illā ant.',
  sourceEn: 'Abu Dawud 5090',
  sourceAr: 'رواه أبو داود (٥٠٩٠)',
);

const _hasbiya = Dhikr(
  ar: 'حَسْبِيَ اللَّهُ لَا إِلَهَ إِلَّا هُوَ، عَلَيْهِ تَوَكَّلْتُ، وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ',
  count: 7,
  meaning: 'Allah is sufficient for me. There is no god but Him. In Him I put my trust, and He is the Lord of the Mighty Throne.',
  translit: 'Ḥasbiyallāhu lā ilāha illā huw, ʿalayhi tawakkaltu wa huwa rabbul-ʿarshil-ʿaẓīm.',
  sourceEn: 'Abu Dawud 5081',
  sourceAr: 'رواه أبو داود (٥٠٨١)',
);

const _afw = Dhikr(
  ar:
      'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ، اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي دِينِي وَدُنْيَايَ وَأَهْلِي وَمَالِي، '
      'اللَّهُمَّ اسْتُرْ عَوْرَاتِي، وَآمِنْ رَوْعَاتِي، اللَّهُمَّ احْفَظْنِي مِنْ بَيْنِ يَدَيَّ، وَمِنْ خَلْفِي، وَعَنْ يَمِينِي، وَعَنْ شِمَالِي، وَمِنْ فَوْقِي، '
      'وَأَعُوذُ بِعَظَمَتِكَ أَنْ أُغْتَالَ مِنْ تَحْتِي',
  count: 1,
  meaning:
      'O Allah, I ask You for pardon and well-being in this world and the Hereafter. O Allah, I ask You for pardon and well-being in my religion, my worldly life, '
      'my family and my wealth. O Allah, cover my faults and calm my fears. O Allah, guard me from in front of me and behind me, from my right and my left, and from above me, '
      'and I seek refuge in Your greatness from being taken unawares from beneath me.',
  translit:
      'Allāhumma innī asʾalukal-ʿafwa wal-ʿāfiyata fid-dunyā wal-ākhirah. Allāhumma innī asʾalukal-ʿafwa wal-ʿāfiyata fī dīnī wa dunyāya wa ahlī wa mālī. '
      'Allāhummastur ʿawrātī, wa āmin rawʿātī. Allāhummaḥfaẓnī min bayni yadayya, wa min khalfī, wa ʿan yamīnī, wa ʿan shimālī, wa min fawqī, '
      'wa aʿūdhu bi-ʿaẓamatika an ughtāla min taḥtī.',
  sourceEn: 'Abu Dawud 5074 · Ibn Majah 3871 (sahih)',
  sourceAr: 'رواه أبو داود (٥٠٧٤) وابن ماجه (٣٨٧١)',
  fadlEn: 'The Prophet ﷺ never left these words, morning and evening.',
  fadlAr: 'لم يكن النبي ﷺ يدع هؤلاء الدعوات حين يمسي وحين يصبح.',
);

const _alimAlGhayb = Dhikr(
  ar:
      'اللَّهُمَّ عَالِمَ الْغَيْبِ وَالشَّهَادَةِ، فَاطِرَ السَّمَاوَاتِ وَالْأَرْضِ، رَبَّ كُلِّ شَيْءٍ وَمَلِيكَهُ، أَشْهَدُ أَنْ لَا إِلَهَ إِلَّا أَنْتَ، '
      'أَعُوذُ بِكَ مِنْ شَرِّ نَفْسِي، وَمِنْ شَرِّ الشَّيْطَانِ وَشِرْكِهِ، وَأَنْ أَقْتَرِفَ عَلَى نَفْسِي سُوءًا أَوْ أَجُرَّهُ إِلَى مُسْلِمٍ',
  count: 1,
  meaning:
      'O Allah, Knower of the unseen and the seen, Creator of the heavens and the earth, Lord and Sovereign of all things: I bear witness that there is no god but You. '
      'I seek refuge in You from the evil of my soul, from the evil of Satan and his call to associate partners with You, and from doing wrong to myself or bringing it upon a Muslim.',
  translit:
      'Allāhumma ʿālimal-ghaybi wash-shahādah, fāṭiras-samāwāti wal-arḍ, rabba kulli shayʾin wa malīkah, ashhadu an lā ilāha illā ant, '
      'aʿūdhu bika min sharri nafsī, wa min sharrish-shayṭāni wa shirkih, wa an aqtarifa ʿalā nafsī sūʾan aw ajurrahu ilā muslim.',
  sourceEn: 'Tirmidhi 3392 · Abu Dawud 5067 (sahih)',
  sourceAr: 'رواه الترمذي (٣٣٩٢) وأبو داود (٥٠٦٧)',
);

const _bismillahNoHarm = Dhikr(
  ar: 'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ',
  count: 3,
  meaning: 'In the name of Allah, with whose name nothing on earth or in the heavens can cause harm, and He is the All-Hearing, the All-Knowing.',
  translit: 'Bismillāhil-ladhī lā yaḍurru maʿa-smihī shayʾun fil-arḍi wa lā fis-samāʾi wa huwas-samīʿul-ʿalīm.',
  sourceEn: 'Abu Dawud 5088 · Tirmidhi 3388 (hasan sahih)',
  sourceAr: 'رواه أبو داود (٥٠٨٨) والترمذي (٣٣٨٨)',
  fadlEn: 'Whoever says it three times in the morning and evening, nothing will harm him.',
  fadlAr: 'من قالها ثلاث مرات إذا أصبح وإذا أمسى لم يضرّه شيء.',
);

const _raditu = Dhikr(
  ar: 'رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ نَبِيًّا',
  count: 3,
  meaning: 'I am pleased with Allah as my Lord, with Islam as my religion, and with Muhammad ﷺ as my Prophet.',
  translit: 'Raḍītu billāhi rabbā, wa bil-islāmi dīnā, wa bi-Muḥammadin ṣallallāhu ʿalayhi wa sallama nabiyyā.',
  sourceEn: 'Abu Dawud 5072 · Ahmad',
  sourceAr: 'رواه أبو داود (٥٠٧٢) وأحمد',
);

const _yaHayy = Dhikr(
  ar: 'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ، وَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ',
  count: 1,
  meaning: 'O Ever-Living, O Sustainer of all, by Your mercy I seek help. Set right all my affairs, and do not leave me to myself even for the blink of an eye.',
  translit: 'Yā Ḥayyu yā Qayyūm, bi-raḥmatika astaghīth, aṣliḥ lī shaʾnī kullah, wa lā takilnī ilā nafsī ṭarfata ʿayn.',
  sourceEn: 'Al-Hakim · An-Nasa\'i (al-Kubra) — hasan (al-Albani)',
  sourceAr: 'رواه الحاكم والنسائي في الكبرى، وحسّنه الألباني',
);

Dhikr _fitraFor(bool m) => Dhikr(
  ar:
      '${m ? 'أَصْبَحْنَا' : 'أَمْسَيْنَا'} عَلَى فِطْرَةِ الْإِسْلَامِ، وَعَلَى كَلِمَةِ الْإِخْلَاصِ، وَعَلَى دِينِ نَبِيِّنَا مُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ، '
      'وَعَلَى مِلَّةِ أَبِينَا إِبْرَاهِيمَ، حَنِيفًا مُسْلِمًا، وَمَا كَانَ مِنَ الْمُشْرِكِينَ',
  count: 1,
  meaning:
      'We have entered the ${m ? 'morning' : 'evening'} upon the natural way of Islam, the word of sincerity, the religion of our Prophet Muhammad ﷺ, '
      'and the way of our father Ibrahim, upright and submitting to Allah, and he was not of those who associate partners with Allah.',
  translit:
      '${m ? 'Aṣbaḥnā' : 'Amsaynā'} ʿalā fiṭratil-islām, wa ʿalā kalimatil-ikhlāṣ, wa ʿalā dīni nabiyyinā Muḥammadin ṣallallāhu ʿalayhi wa sallam, '
      'wa ʿalā millati abīnā Ibrāhīma ḥanīfan musliman wa mā kāna minal-mushrikīn.',
  sourceEn: 'Ahmad (sahih)',
  sourceAr: 'رواه أحمد',
);

const _subhanBihamdihi = Dhikr(
  ar: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
  count: 100,
  meaning: 'Glory be to Allah, and praise be to Him.',
  translit: 'Subḥānallāhi wa bi-ḥamdih.',
  sourceEn: 'Muslim 2692',
  sourceAr: 'رواه مسلم (٢٦٩٢)',
  fadlEn:
      'Whoever says it a hundred times morning and evening: no one will bring anything better on the Day of Resurrection, '
      'except someone who said the same or more.',
  fadlAr: 'من قالها حين يصبح وحين يمسي مائة مرة لم يأتِ أحد يوم القيامة بأفضل مما جاء به، إلا أحد قال مثل ما قال أو زاد عليه.',
);

const _tahlil10 = Dhikr(
  ar: 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
  count: 10,
  meaning: 'There is no god but Allah alone, with no partner. His is the dominion and His is the praise, and He has power over all things.',
  translit: 'Lā ilāha illallāhu waḥdahu lā sharīka lah, lahul-mulku wa lahul-ḥamd, wa huwa ʿalā kulli shayʾin qadīr.',
  sourceEn: 'Muslim 2693 · Bukhari 6404',
  sourceAr: 'رواه مسلم (٢٦٩٣) والبخاري (٦٤٠٤)',
  fadlEn: 'Whoever says it ten times is like one who freed four people from the children of Isma\'il.',
  fadlAr: 'من قالها عشر مرات كان كمن أعتق أربعة أنفس من ولد إسماعيل.',
);

const _adadaKhalqihi = Dhikr(
  ar: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، وَزِنَةَ عَرْشِهِ، وَمِدَادَ كَلِمَاتِهِ',
  count: 3,
  meaning:
      'Glory be to Allah and praise be to Him, as many times as the number of His creation, as much as pleases Him, '
      'as much as the weight of His Throne, and as much as the ink of His words.',
  translit: 'Subḥānallāhi wa bi-ḥamdih, ʿadada khalqih, wa riḍā nafsih, wa zinata ʿarshih, wa midāda kalimātih.',
  sourceEn: 'Muslim 2726',
  sourceAr: 'رواه مسلم (٢٧٢٦)',
  fadlEn: 'Said three times, these words outweigh all the dhikr from dawn until mid-morning.',
  fadlAr: 'قالها النبي ﷺ ثلاث مرات، وقال: لو وُزنت بما قلتِ منذ اليوم لوزنتهن.',
);

const _ilman = Dhikr(
  ar: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا، وَرِزْقًا طَيِّبًا، وَعَمَلًا مُتَقَبَّلًا',
  count: 1,
  meaning: 'O Allah, I ask You for beneficial knowledge, good provision and accepted deeds.',
  translit: 'Allāhumma innī asʾaluka ʿilman nāfiʿā, wa rizqan ṭayyibā, wa ʿamalan mutaqabbalā.',
  sourceEn: 'Ibn Majah 925 (sahih)',
  sourceAr: 'رواه ابن ماجه (٩٢٥)',
);

const _astaghfiru100 = Dhikr(
  ar: 'أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ',
  count: 100,
  meaning: 'I seek the forgiveness of Allah and turn to Him in repentance.',
  translit: 'Astaghfirullāha wa atūbu ilayh.',
  sourceEn: 'Muslim 2702 · Bukhari 6307',
  sourceAr: 'رواه مسلم (٢٧٠٢) والبخاري (٦٣٠٧)',
  fadlEn: 'The Prophet ﷺ sought Allah\'s forgiveness and repented a hundred times every day.',
  fadlAr: 'كان النبي ﷺ يستغفر الله ويتوب إليه في اليوم مائة مرة.',
);

const _kalimat = Dhikr(
  ar: 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
  count: 3,
  meaning: 'I seek refuge in the perfect words of Allah from the evil of what He has created.',
  translit: 'Aʿūdhu bi-kalimātillāhit-tāmmāti min sharri mā khalaq.',
  sourceEn: 'Muslim 2709',
  sourceAr: 'رواه مسلم (٢٧٠٩)',
  fadlEn: 'Whoever says it in the evening, a scorpion\'s sting would not harm him that night.',
  fadlAr: 'من قالها حين يمسي لم تضرّه حُمة تلك الليلة.',
);

const _salawat = Dhikr(
  ar: 'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ',
  count: 10,
  meaning: 'O Allah, send blessings and peace upon our Prophet Muhammad.',
  translit: 'Allāhumma ṣalli wa sallim ʿalā nabiyyinā Muḥammad.',
  sourceEn: 'At-Tabarani — hasan (al-Albani, Sahih at-Targhib 656)',
  sourceAr: 'رواه الطبراني، وحسّنه الألباني في صحيح الترغيب (٦٥٦)',
  fadlEn: 'Whoever sends blessings on the Prophet ﷺ ten times in the morning and ten in the evening will receive his intercession on the Day of Resurrection.',
  fadlAr: 'من صلّى على النبي ﷺ حين يصبح عشرًا وحين يمسي عشرًا أدركته شفاعته يوم القيامة.',
);

Dhikr _rabbilAlaminFor(bool m) => Dhikr(
  ar: m
      ? 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ رَبِّ الْعَالَمِينَ، اللَّهُمَّ إِنِّي أَسْأَلُكَ خَيْرَ هَذَا الْيَوْمِ: فَتْحَهُ، وَنَصْرَهُ، وَنُورَهُ، وَبَرَكَتَهُ، وَهُدَاهُ، '
            'وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِيهِ وَشَرِّ مَا بَعْدَهُ'
      : 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ رَبِّ الْعَالَمِينَ، اللَّهُمَّ إِنِّي أَسْأَلُكَ خَيْرَ هَذِهِ اللَّيْلَةِ: فَتْحَهَا، وَنَصْرَهَا، وَنُورَهَا، وَبَرَكَتَهَا، وَهُدَاهَا، '
            'وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِيهَا وَشَرِّ مَا بَعْدَهَا',
  count: 1,
  meaning:
      'We have entered the ${m ? 'morning' : 'evening'}, and the dominion belongs to Allah, Lord of the worlds. O Allah, I ask You for the good of this ${m ? 'day' : 'night'}: '
      'its victory, its help, its light, its blessing and its guidance, and I seek refuge in You from the evil in it and the evil after it.',
  translit: m
      ? 'Aṣbaḥnā wa aṣbaḥal-mulku lillāhi rabbil-ʿālamīn. Allāhumma innī asʾaluka khayra hādhal-yawm: fatḥahu, wa naṣrahu, wa nūrahu, wa barakatahu, wa hudāh, '
            'wa aʿūdhu bika min sharri mā fīhi wa sharri mā baʿdah.'
      : 'Amsaynā wa amsal-mulku lillāhi rabbil-ʿālamīn. Allāhumma innī asʾaluka khayra hādhihil-laylah: fatḥahā, wa naṣrahā, wa nūrahā, wa barakatahā, wa hudāhā, '
            'wa aʿūdhu bika min sharri mā fīhā wa sharri mā baʿdahā.',
  sourceEn: 'Abu Dawud 5084',
  sourceAr: 'رواه أبو داود (٥٠٨٤)',
);

AthkarSet _morningEvening(bool m) =>
    AthkarSet(m ? 'morning' : 'evening', m ? 'Morning athkar' : 'Evening athkar', m ? 'أذكار الصباح' : 'أذكار المساء', [
      _kursiFor(m),
      ..._quls,
      _mulkFor(m),
      _bikaFor(m),
      _sayyidIstighfar,
      _ushhiduFor(m),
      _nimaFor(m),
      _afini,
      _hasbiya,
      _afw,
      _alimAlGhayb,
      _bismillahNoHarm,
      _raditu,
      _yaHayy,
      _fitraFor(m),
      _subhanBihamdihi,
      _tahlil10,
      if (m) _adadaKhalqihi,
      if (m) _ilman,
      _astaghfiru100,
      if (!m) _kalimat,
      _salawat,
      _rabbilAlaminFor(m),
    ]);

// ---------------------------------------------------------------------------
// After salah, tasbeeh, sleep, waking
// ---------------------------------------------------------------------------

const _tasbeehFadlEn =
    'Whoever says these after every prayer, completing a hundred with the tahlil, has his sins forgiven even if they are like the foam of the sea.';
const _tasbeehFadlAr =
    'من سبّح الله دبر كل صلاة ثلاثًا وثلاثين، وحمد الله ثلاثًا وثلاثين، وكبّر الله ثلاثًا وثلاثين، وختم المائة بالتهليل، غُفرت خطاياه وإن كانت مثل زبد البحر.';

const _tasbeeh33 = [
  Dhikr(
    ar: 'سُبْحَانَ اللَّهِ',
    count: 33,
    meaning: 'Glory be to Allah.',
    translit: 'Subḥānallāh.',
    sourceEn: 'Muslim 597',
    sourceAr: 'رواه مسلم (٥٩٧)',
    fadlEn: _tasbeehFadlEn,
    fadlAr: _tasbeehFadlAr,
  ),
  Dhikr(
    ar: 'الْحَمْدُ لِلَّهِ',
    count: 33,
    meaning: 'All praise is for Allah.',
    translit: 'Al-ḥamdu lillāh.',
    sourceEn: 'Muslim 597',
    sourceAr: 'رواه مسلم (٥٩٧)',
    fadlEn: _tasbeehFadlEn,
    fadlAr: _tasbeehFadlAr,
  ),
  Dhikr(
    ar: 'اللَّهُ أَكْبَرُ',
    count: 33,
    meaning: 'Allah is the Greatest.',
    translit: 'Allāhu akbar.',
    sourceEn: 'Muslim 597',
    sourceAr: 'رواه مسلم (٥٩٧)',
    fadlEn: _tasbeehFadlEn,
    fadlAr: _tasbeehFadlAr,
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
    fadlEn: _tasbeehFadlEn,
    fadlAr: _tasbeehFadlAr,
  ),
  Dhikr(
    quran: (2, 255, 255),
    count: 1,
    meaning: 'Ayat al-Kursi (al-Baqarah 2:255).',
    sourceEn: 'An-Nasa\'i (al-Kubra) — sahih (al-Albani)',
    sourceAr: 'رواه النسائي في الكبرى، وصحّحه الألباني',
    fadlEn: 'Whoever recites it after every obligatory prayer, nothing stands between him and Paradise except death.',
    fadlAr: 'من قرأها دبر كل صلاة مكتوبة لم يمنعه من دخول الجنة إلا أن يموت.',
  ),
]);

const _tasbeeh = AthkarSet('tasbeeh', 'Tasbeeh', 'التسبيح', [
  ..._tasbeeh33,
  Dhikr(
    ar: 'لَا إِلَهَ إِلَّا اللَّهُ',
    count: 33,
    meaning: 'There is no god but Allah.',
    translit: 'Lā ilāha illallāh.',
    sourceEn: 'Tirmidhi 3383 (hasan)',
    sourceAr: 'رواه الترمذي (٣٣٨٣)',
    fadlEn: 'The best dhikr is "La ilaha illallah".',
    fadlAr: 'أفضل الذكر: لا إله إلا الله.',
  ),
  _astaghfiru100,
]);

const _sleep = AthkarSet('sleep', 'Before sleep', 'أذكار النوم', [
  Dhikr(
    quran: (2, 255, 255),
    count: 1,
    meaning: 'Ayat al-Kursi (al-Baqarah 2:255).',
    sourceEn: 'Bukhari 2311',
    sourceAr: 'رواه البخاري (٢٣١١)',
    fadlEn: 'A guardian from Allah stays with you, and Satan does not come near you until morning.',
    fadlAr: 'لا يزال عليك من الله حافظ، ولا يقربك شيطان حتى تصبح.',
  ),
  Dhikr(
    quran: (2, 285, 286),
    count: 1,
    meaning: 'The last two ayahs of al-Baqarah (2:285–286).',
    sourceEn: 'Bukhari 5009',
    sourceAr: 'رواه البخاري (٥٠٠٩)',
    fadlEn: 'Whoever recites them at night, they will suffice him.',
    fadlAr: 'من قرأ بالآيتين من آخر سورة البقرة في ليلة كفتاه.',
  ),
  Dhikr(
    quran: (112, 1, 4),
    count: 3,
    meaning: 'Surah al-Ikhlas (112). Then blow into the palms and wipe over as much of the body as you can.',
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
    fadlEn: 'Taught to Ali and Fatimah at bedtime: better for them than a servant.',
    fadlAr: 'علّمها النبي ﷺ عليًّا وفاطمة عند النوم، وقال: هو خير لكما من خادم.',
  ),
  Dhikr(
    ar: 'الْحَمْدُ لِلَّهِ',
    count: 33,
    meaning: 'All praise is for Allah.',
    translit: 'Al-ḥamdu lillāh.',
    sourceEn: 'Bukhari 3705 · Muslim 2727',
    sourceAr: 'رواه البخاري (٣٧٠٥) ومسلم (٢٧٢٧)',
    fadlEn: 'Taught to Ali and Fatimah at bedtime: better for them than a servant.',
    fadlAr: 'علّمها النبي ﷺ عليًّا وفاطمة عند النوم، وقال: هو خير لكما من خادم.',
  ),
  Dhikr(
    ar: 'اللَّهُ أَكْبَرُ',
    count: 34,
    meaning: 'Allah is the Greatest.',
    translit: 'Allāhu akbar.',
    sourceEn: 'Bukhari 3705 · Muslim 2727',
    sourceAr: 'رواه البخاري (٣٧٠٥) ومسلم (٢٧٢٧)',
    fadlEn: 'Taught to Ali and Fatimah at bedtime: better for them than a servant.',
    fadlAr: 'علّمها النبي ﷺ عليًّا وفاطمة عند النوم، وقال: هو خير لكما من خادم.',
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
    fadlEn: 'Whoever wakes at night and says this, then asks Allah, is answered; and if he makes wudu and prays, his prayer is accepted.',
    fadlAr: 'من تعارّ من الليل فقالها ثم دعا استُجيب له، فإن توضأ وصلّى قُبلت صلاته.',
  ),
]);

final athkarSets = [_morningEvening(true), _morningEvening(false), _salah, _tasbeeh, _sleep, _waking];

AthkarSet athkarSet(String id) => athkarSets.firstWhere((s) => s.id == id, orElse: () => athkarSets.first);
