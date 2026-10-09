import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/settings.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';
import '../quran/mushaf_page.dart';
import '../quran/quran_data.dart';
import 'athkar_data.dart';
import 'athkar_menu_screen.dart';

/// 46 · Dhikr counter, then 47 · Set complete.
class DhikrScreen extends ConsumerStatefulWidget {
  const DhikrScreen({super.key, required this.setId});

  final String setId;

  @override
  ConsumerState<DhikrScreen> createState() => _DhikrScreenState();
}

class _DhikrScreenState extends ConsumerState<DhikrScreen> {
  late final AthkarSet set = athkarSet(widget.setId);
  int _i = 0;
  int _count = 0;
  bool _translit = false;
  bool _finished = false;
  bool _advancing = false;

  Dhikr get _d => set.items[_i];

  void _go(int i) {
    if (i >= set.items.length) {
      ref.read(settingsProvider.notifier).markAthkarDone(set.id);
      setState(() => _finished = true);
      return;
    }
    setState(() {
      _i = i.clamp(0, set.items.length - 1);
      _count = 0;
      _advancing = false;
    });
  }

  void _tap() {
    if (_advancing) return;
    HapticFeedback.lightImpact();
    setState(() => _count++);
    if (_count >= _d.count) {
      HapticFeedback.mediumImpact();
      setState(() => _advancing = true);
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted && _advancing) _go(_i + 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (_finished) return _complete(context, s);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final title = s.ar ? set.ar : set.en;
    final done = _count >= _d.count;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 20, 8),
              child: Row(
                children: [
                  const BackPill(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(s.ofN(_i + 1, set.total), textAlign: TextAlign.end, style: tt.titleSmall),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (_i + (done ? 1 : 0)) / set.total,
                  minHeight: 8,
                  color: t.primary,
                  backgroundColor: t.tint,
                ),
              ),
            ),
            Expanded(
              child: _FadingScroll(
                key: ValueKey(_i),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: WordSafeText(title, style: tt.titleLarge!.copyWith(color: t.primary)),
                    ),
                    _text(context, s),
                  ],
                ),
              ),
            ),
            _counterPanel(context, s, done),
          ],
        ),
      ),
    );
  }

  Widget _text(BuildContext context, S s) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final quran = ref.watch(quranProvider).value;
    final q = _d.quran;
    Widget arabic;
    if (q != null) {
      final ayahs = quran?.range(q.$1, q.$2, q.$3) ?? const <Ayah>[];
      final showBasmala = q.$1 != 2 && q.$1 != 9;
      arabic = Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: t.tint, borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SIcon(SIcons.rehal, size: 18, color: t.primary),
                const SizedBox(width: 6),
                Text(
                  s.quranLabel,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (showBasmala && quran != null) Basmala(color: t.text, text: quran.basmala, height: 56),
          Text(
            ayahs.map((a) => a.text).join(' '),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: SanadiFonts.quran, fontSize: 28, color: t.text, height: 2.1),
          ),
        ],
      );
    } else {
      arabic = Text(
        _d.ar!,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: SanadiFonts.naskh,
          fontSize: 28,
          fontWeight: FontWeight.w500,
          color: t.text,
          height: 2,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          arabic,
          const SizedBox(height: 12),
          if ((s.ar ? _d.fadlAr : _d.fadlEn).isNotEmpty) ...[
            _FadlNote(text: s.ar ? _d.fadlAr : _d.fadlEn, label: s.virtue),
            const SizedBox(height: 12),
          ],
          if (s.ar)
            Text(_d.sourceAr, style: tt.bodySmall, textAlign: TextAlign.start)
          else ...[
            Divider(color: t.line, height: 28),
            if (_d.translit.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(child: WordSafeText(s.showTranslit, style: tt.titleSmall)),
                  Switch(value: _translit, onChanged: (v) => setState(() => _translit = v)),
                ],
              ),
              if (_translit) ...[
                const SizedBox(height: 8),
                Text(_d.translit, style: tt.bodyMedium!.copyWith(fontStyle: FontStyle.italic)),
              ],
              const SizedBox(height: 12),
            ],
            if (_d.meaning.isNotEmpty) Text(_d.meaning, style: tt.bodyMedium),
            const SizedBox(height: 8),
            Text(_d.sourceEn, style: tt.bodySmall),
          ],
        ],
      ),
    );
  }

  Widget _counterPanel(BuildContext context, S s, bool done) {
    final t = context.t;
    final big = MediaQuery.textScalerOf(context).scale(10) > 14;
    final size = big ? 136.0 : 172.0;
    final buttons = [
      BigButton(
        label: s.previous,
        icon: Arrows.back,
        kind: ButtonKind.outline,
        compact: true,
        onPressed: _i == 0 ? null : () => _go(_i - 1),
      ),
      BigButton(
        label: s.next,
        trailingIcon: Arrows.forward,
        kind: ButtonKind.outline,
        compact: true,
        onPressed: () => _go(_i + 1),
      ),
    ];
    // The counter shrinks at large text sizes so the dhikr keeps its space.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Container(
        color: t.surface,
        padding: EdgeInsets.fromLTRB(20, big ? 10 : 16, 20, big ? 10 : 16),
        child: Column(
          children: [
            Semantics(
              button: true,
              label: '${s.tapToCount}, ${s.n(_count)} / ${s.n(_d.count)}',
              child: GestureDetector(
                onTap: _tap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? t.deep : t.primary,
                    border: Border.all(color: t.tint, width: 8),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (done)
                          Icon(
                            Icons.check_rounded,
                            size: 56,
                            color: Theme.of(context).brightness == Brightness.dark ? t.onPrimary : Colors.white,
                          )
                        else
                          FittedBox(
                            child: Text(
                              '${s.n(_count)} / ${s.n(_d.count)}',
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontFamilyFallback: const ['Tajawal'],
                                fontSize: 44,
                                fontWeight: FontWeight.w700,
                                color: t.onPrimary,
                                height: 1,
                              ),
                            ),
                          ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            done ? s.nextDhikr : s.tapToCount,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: done && Theme.of(context).brightness != Brightness.dark
                                  ? Colors.white
                                  : t.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: big ? 10 : 14),
            // Previous (←) on the left, Next (→) on the right, in every language.
            Row(
              textDirection: TextDirection.ltr,
              children: [
                Expanded(child: buttons[0]),
                const SizedBox(width: 10),
                Expanded(child: buttons[1]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _complete(BuildContext context, S s) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    return StepScaffold(
      center: true,
      content: [
        Center(child: Illustration(size: 128, child: AthkarMenuScreen.iconFor(set.id, t.primary))),
        const SizedBox(height: 24),
        WordSafeText(s.setDoneTitle, style: tt.headlineMedium, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(s.setDoneBody(s.ar ? set.ar : set.en), style: tt.bodyLarge, textAlign: TextAlign.center),
      ],
      bottom: [
        BigButton(label: s.backToAthkar, iconWidget: const SIcon(SIcons.misbaha), onPressed: () => context.pop()),
        BigButton(
          label: s.resetCount,
          kind: ButtonKind.outline,
          onPressed: () => setState(() {
            _finished = false;
            _go(0);
          }),
        ),
      ],
    );
  }
}

/// Scroll area that fades at the bottom with a "Scroll for more" hint when
/// the text is longer than the space, so no line looks cut off.
class _FadingScroll extends StatefulWidget {
  const _FadingScroll({super.key, required this.child});

  final Widget child;

  @override
  State<_FadingScroll> createState() => _FadingScrollState();
}

class _FadingScrollState extends State<_FadingScroll> {
  final _c = ScrollController();
  bool _more = false;

  @override
  void initState() {
    super.initState();
    _c.addListener(_update);
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  void _update() {
    if (!_c.hasClients) return;
    final more = _c.position.extentAfter > 8;
    if (more != _more) setState(() => _more = more);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (_) {
        _update();
        return false;
      },
      // The "scroll for more" hint sits under the text, never on top of it.
      // It always keeps its space, so the text doesn't jump when it fades.
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(controller: _c, child: widget.child),
                if (_more)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Container(
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [t.bg.withValues(alpha: 0), t.bg],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ExcludeSemantics(
            excluding: !_more,
            child: AnimatedOpacity(
              opacity: _more ? 1 : 0,
              duration: const Duration(milliseconds: 150),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        S.of(context).scrollMore,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.muted),
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down_rounded, color: t.muted),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The reward or benefit of a dhikr, from the hadith.
class _FadlNote extends StatelessWidget {
  const _FadlNote({required this.text, required this.label});

  final String text;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(14),
        border: BorderDirectional(start: BorderSide(color: t.gold, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium_rounded, color: t.gold, size: 22),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.heading),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
