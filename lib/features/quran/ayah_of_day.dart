import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/reminders.dart';
import '../../core/router.dart';
import '../../core/settings.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';
import 'daily_ayahs.dart';
import 'quran_data.dart';

/// "Ayah of the day" notification: on or off, and the time (minutes after
/// midnight). Kept on this phone.
class AyahOfDaySetting {
  const AyahOfDaySetting(this.on, this.minutes);

  final bool on;
  final int minutes;

  TimeOfDay get time => TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
}

class AyahOfDayNotifier extends Notifier<AyahOfDaySetting> {
  static const _kOn = 'ayahOfDay.on';
  static const _kTime = 'ayahOfDay.time';

  @override
  AyahOfDaySetting build() {
    final p = ref.read(sharedPreferencesProvider);
    return AyahOfDaySetting(p.getBool(_kOn) ?? true, p.getInt(_kTime) ?? 9 * 60);
  }

  void setOn(bool on) {
    ref.read(sharedPreferencesProvider).setBool(_kOn, on);
    state = AyahOfDaySetting(on, state.minutes);
  }

  void setTime(TimeOfDay t) {
    final m = t.hour * 60 + t.minute;
    ref.read(sharedPreferencesProvider).setInt(_kTime, m);
    state = AyahOfDaySetting(state.on, m);
  }
}

final ayahOfDayProvider = NotifierProvider<AyahOfDayNotifier, AyahOfDaySetting>(AyahOfDayNotifier.new);

/// The Arabic of a daily ayah, as printed (with its ayah markers).
String ayahText(QuranData q, DailyAyah d) =>
    [for (var a = d.from; a <= d.to; a++) q.ayah(d.sura, a)?.text ?? ''].where((x) => x.isNotEmpty).join(' ');

/// The same without the markers, for a notification (drawn in the phone's
/// own font), with each ayah's number in brackets.
String ayahPlainText(QuranData q, DailyAyah d) => [
  for (var a = d.from; a <= d.to; a++)
    if (q.ayah(d.sura, a) case final x?) '${x.plain} ﴿${x.number}﴾',
].join(' ');

/// The translation or tafsir text: in Arabic, the Naskh font (the tafsir
/// uses marks such as ﷺ that the interface font lacks).
TextStyle meaningStyle(BuildContext context, TextStyle base) =>
    S.of(context).ar ? base.copyWith(fontFamily: SanadiFonts.naskh, height: 1.8) : base;

/// Where the ayah is, e.g. "Al-Baqarah, ayah 153".
String ayahReference(S s, QuranData q, DailyAyah d) => s.ayahRef(q.sura(d.sura).name(s.ar), d.from, d.to);

/// Keeps the next days' notifications scheduled (on/off, time, language).
/// Watched once, by the app.
final ayahOfDaySyncProvider = Provider<void>((ref) {
  final setting = ref.watch(ayahOfDayProvider);
  final (locale, female, signedIn) = ref.watch(settingsProvider.select((s) => (s.locale, s.female, s.signedIn)));
  final q = ref.watch(quranProvider).value;
  final on = setting.on && locale != null && signedIn;
  if (on && q == null) return; // Scheduled once the text has loaded.
  final s = S(ar: locale?.languageCode == 'ar', female: female);
  Reminders.instance.applyAyahOfDay(
    on: on,
    minutes: setting.minutes,
    s: s,
    content: (day) {
      final d = ayahForDay(day);
      return (
        '${s.ayahOfDay} · ${d.theme(s.ar)}',
        d.meaning(s.ar),
        '${ayahPlainText(q!, d)}\n\n${d.meaning(s.ar)}\n\n${ayahReference(s, q, d)} · ${s.ayahSource}',
      );
    },
  );
});

/// Today's ayah on the home screen, with its meaning. Tapping opens it in
/// large type; the button opens it in the mushaf.
class AyahOfDayCard extends ConsumerWidget {
  const AyahOfDayCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final q = ref.watch(quranProvider).value;
    if (q == null) return const SizedBox.shrink();
    final day = dayNumber(DateTime.now());
    final d = ayahForDay(day);
    return SCard(
      key: const ValueKey('ayah-of-day'),
      onTap: () => context.push(Routes.ayahOfDay(day)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              TintBox(child: Icon(Icons.wb_sunny_rounded, color: t.primary)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WordSafeText(s.ayahOfDay, style: tt.titleMedium!.copyWith(color: t.heading)),
                    WordSafeText(d.theme(s.ar), style: tt.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ayahText(q, d),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: SanadiFonts.quran, letterSpacing: 0, fontSize: 24, height: 1.9, color: t.text),
          ),
          const SizedBox(height: 8),
          Text(
            d.meaning(s.ar),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: meaningStyle(context, tt.bodyMedium!),
          ),
          const SizedBox(height: 4),
          Text(
            '${ayahReference(s, q, d)} · ${s.ayahSource}',
            style: nameFont(context, tt.bodySmall!.copyWith(color: t.muted)),
          ),
        ],
      ),
    );
  }
}

/// One day's ayah in large type, with its meaning and a button to open it
/// in the mushaf (also where the notification leads).
class AyahOfDayScreen extends ConsumerWidget {
  const AyahOfDayScreen({super.key, this.day});

  /// The day it was for (from the notification); today if null.
  final int? day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final q = ref.watch(quranProvider).value;
    final d = ayahForDay(day ?? dayNumber(DateTime.now()));
    return StepScaffold(
      showBack: true,
      onBack: () => context.canPop() ? context.pop() : context.go(Routes.splash),
      content: [
        WordSafeText(s.ayahOfDay, style: tt.headlineMedium),
        const SizedBox(height: 4),
        WordSafeText(d.theme(s.ar), style: tt.titleMedium!.copyWith(color: t.primary)),
        const SizedBox(height: 16),
        if (q == null)
          const Center(child: CircularProgressIndicator())
        else ...[
          SCard(
            child: Text(
              ayahText(q, d),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: SanadiFonts.quran,
                letterSpacing: 0,
                fontSize: 30,
                height: 2.0,
                color: t.text,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ayahReference(s, q, d),
            textAlign: TextAlign.center,
            style: nameFont(context, tt.bodyMedium!.copyWith(color: t.muted)),
          ),
        ],
        const SizedBox(height: 20),
        WordSafeText(s.ayahMeaningL, style: tt.titleLarge),
        const SizedBox(height: 6),
        Text(d.meaning(s.ar), style: meaningStyle(context, tt.bodyLarge!)),
        const SizedBox(height: 14),
        // What this text is, and where it comes from.
        SCard(
          color: t.tint,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_rounded, color: t.primary, size: 26),
              const SizedBox(width: 10),
              Expanded(child: Text(s.ayahMeaningNote, style: tt.bodyMedium)),
            ],
          ),
        ),
      ],
      bottom: [
        BigButton(
          label: s.openInQuran,
          iconWidget: const SIcon(SIcons.rehal),
          onPressed: () => context.push(Routes.mushafAt(sura: d.sura, ayah: d.from)),
        ),
      ],
    );
  }
}

/// The Ayah of the day notification: on or off, and its time.
void showAyahOfDaySheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Consumer(
      builder: (ctx, ref, _) {
        final s = S.of(ctx);
        final t = ctx.t;
        final tt = Theme.of(ctx).textTheme;
        final setting = ref.watch(ayahOfDayProvider);
        final n = ref.read(ayahOfDayProvider.notifier);
        final l = MaterialLocalizations.of(ctx);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: WordSafeText(s.ayahOfDay, style: tt.headlineSmall)),
                  Switch(value: setting.on, onChanged: n.setOn),
                ],
              ),
              const SizedBox(height: 6),
              Text(s.ayahOfDayHint, style: tt.bodySmall),
              const SizedBox(height: 14),
              SCard(
                onTap: setting.on
                    ? () async {
                        final picked = await showTimePicker(context: ctx, initialTime: setting.time);
                        if (picked != null) n.setTime(picked);
                      }
                    : null,
                child: Row(
                  children: [
                    Expanded(child: WordSafeText(s.ayahTimeL, style: tt.titleMedium)),
                    Text(
                      s.n(l.formatTimeOfDay(setting.time)),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: setting.on ? t.primary : t.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
