import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings.dart';
import 'quran_data.dart';

/// A reciter, with the folders their per-ayah recordings live in.
class Reciter {
  const Reciter(this.id, this.en, this.ar, this.everyAyah, [this.quranCom]);

  final String id;
  final String en;
  final String ar;

  /// Folder on everyayah.com.
  final String everyAyah;

  /// Folder on verses.quran.com, tried if EveryAyah fails.
  final String? quranCom;

  String name(bool arabic) => arabic ? ar : en;

  List<String> urls(int sura, int ayah) {
    final file = '${sura.toString().padLeft(3, '0')}${ayah.toString().padLeft(3, '0')}.mp3';
    return [
      'https://everyayah.com/data/$everyAyah/$file',
      if (quranCom != null) 'https://verses.quran.com/$quranCom/mp3/$file',
    ];
  }
}

const reciters = [
  Reciter('alafasy', 'Mishary Alafasy', 'مشاري العفاسي', 'Alafasy_128kbps', 'Alafasy'),
  // Husary's teaching recitation: slow and clear, with pauses to repeat.
  Reciter('husary_muallim', 'Al-Husary (teaching)', 'الحصري (المعلّم)', 'Husary_Muallim_128kbps'),
  Reciter('husary', 'Mahmoud Khalil Al-Husary', 'محمود خليل الحصري', 'Husary_128kbps', 'Husary'),
  Reciter('minshawi', 'Al-Minshawi', 'محمد صديق المنشاوي', 'Minshawy_Murattal_128kbps', 'Minshawi/Murattal'),
  Reciter('abdulbasit', 'Abdul Basit', 'عبد الباسط عبد الصمد', 'Abdul_Basit_Murattal_192kbps', 'AbdulBaset/Murattal'),
  Reciter('sudais', 'Abdurrahman As-Sudais', 'عبد الرحمن السديس', 'Abdurrahmaan_As-Sudais_192kbps', 'Sudais'),
];

Reciter reciterById(String id) => reciters.firstWhere((r) => r.id == id, orElse: () => reciters.first);

/// How often each ayah is played; 0 means keep repeating.
const repeatChoices = [1, 3, 5, 0];
const speedChoices = [0.75, 1.0, 1.25];

@immutable
class RecitationState {
  const RecitationState({
    this.ayah,
    this.playing = false,
    this.loading = false,
    this.reciterId = 'alafasy',
    this.repeat = 1,
    this.speed = 1.0,
    this.failed = false,
  });

  /// The ayah being recited (null when stopped).
  final Ayah? ayah;
  final bool playing;
  final bool loading;
  final String reciterId;
  final int repeat;
  final double speed;

  /// The last ayah couldn't be loaded (e.g. no internet).
  final bool failed;

  bool get active => ayah != null;
  Reciter get reciter => reciterById(reciterId);

  RecitationState copyWith({
    Ayah? ayah,
    bool clearAyah = false,
    bool? playing,
    bool? loading,
    String? reciterId,
    int? repeat,
    double? speed,
    bool? failed,
  }) => RecitationState(
    ayah: clearAyah ? null : (ayah ?? this.ayah),
    playing: playing ?? this.playing,
    loading: loading ?? this.loading,
    reciterId: reciterId ?? this.reciterId,
    repeat: repeat ?? this.repeat,
    speed: speed ?? this.speed,
    failed: failed ?? this.failed,
  );
}

/// Plays the Quran ayah by ayah from a starting ayah, repeating each one as
/// chosen, and carries on to the end of the Quran (or until stopped).
class RecitationController extends Notifier<RecitationState> {
  AudioPlayer? _player;
  final _subs = <StreamSubscription<Object?>>[];
  int _played = 0;
  int _token = 0;

  static const _kReciter = 'recitation.reciter';
  static const _kRepeat = 'recitation.repeat';
  static const _kSpeed = 'recitation.speed';

  @override
  RecitationState build() {
    ref.onDispose(_dispose);
    final p = ref.read(sharedPreferencesProvider);
    return RecitationState(
      reciterId: p.getString(_kReciter) ?? 'alafasy',
      repeat: p.getInt(_kRepeat) ?? 1,
      speed: p.getDouble(_kSpeed) ?? 1.0,
    );
  }

  AudioPlayer get _p => _player ??= () {
    final p = AudioPlayer();
    _subs.add(p.onPlayerComplete.listen((_) => _ended()));
    _subs.add(
      p.onPlayerStateChanged.listen((s) {
        if (state.active && !state.loading) state = state.copyWith(playing: s == PlayerState.playing);
      }),
    );
    return p;
  }();

  /// Starts reciting from [ayah].
  Future<void> playFrom(Ayah ayah) async {
    _played = 0;
    await _load(ayah);
  }

  Future<void> toggle() async {
    if (!state.active) return;
    if (state.playing) {
      await _p.pause();
      state = state.copyWith(playing: false);
    } else {
      await _p.resume();
      state = state.copyWith(playing: true);
    }
  }

  Future<void> stop() async {
    _token++;
    await _player?.stop();
    state = state.copyWith(clearAyah: true, playing: false, loading: false, failed: false);
  }

  Future<void> setReciter(String id) async {
    ref.read(sharedPreferencesProvider).setString(_kReciter, id);
    state = state.copyWith(reciterId: id);
    final a = state.ayah;
    if (a != null) await _load(a);
  }

  void setRepeat(int n) {
    ref.read(sharedPreferencesProvider).setInt(_kRepeat, n);
    state = state.copyWith(repeat: n);
  }

  Future<void> setSpeed(double s) async {
    ref.read(sharedPreferencesProvider).setDouble(_kSpeed, s);
    state = state.copyWith(speed: s);
    if (state.active) await _p.setPlaybackRate(s);
  }

  Future<void> _load(Ayah ayah) async {
    final token = ++_token;
    state = state.copyWith(ayah: ayah, loading: true, playing: false, failed: false);
    for (final url in state.reciter.urls(ayah.sura, ayah.ayah)) {
      try {
        await _p.stop();
        await _p.setPlaybackRate(state.speed);
        await _p.play(UrlSource(url));
        if (token != _token) return;
        state = state.copyWith(loading: false, playing: true);
        return;
      } catch (e) {
        debugPrint('Recitation: $url failed: $e');
        if (token != _token) return;
      }
    }
    state = state.copyWith(loading: false, playing: false, failed: true);
  }

  Future<void> _ended() async {
    final a = state.ayah;
    if (a == null) return;
    _played++;
    final repeat = state.repeat;
    if (repeat == 0 || _played < repeat) {
      await _load(a);
      return;
    }
    _played = 0;
    final q = ref.read(quranProvider).value;
    final next = q?.after(a);
    if (next == null) {
      await stop();
    } else {
      await _load(next);
    }
  }

  void _dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _player?.dispose();
  }
}

final recitationProvider = NotifierProvider<RecitationController, RecitationState>(RecitationController.new);
