import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../backend/sessions.dart';
import '../../core/connectivity.dart';
import '../../core/settings.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';
import 'large_text_view.dart';
import 'mushaf_page.dart';
import 'quran_data.dart';
import 'recitation.dart';
import 'surah_index_screen.dart';

/// 39 · The mushaf. Mushaf page mode shows the exact Madani 15-line pages
/// (two side by side on wide landscape screens); Large text mode reflows the
/// text in big type. Tap the page to show or hide the bars; long-press an
/// ayah for its actions (40).
class MushafScreen extends ConsumerStatefulWidget {
  const MushafScreen({super.key, this.sura, this.ayah, this.page});

  final int? sura;
  final int? ayah;
  final int? page;

  @override
  ConsumerState<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends ConsumerState<MushafScreen> {
  final _page = ValueNotifier<int>(1);
  final _selected = ValueNotifier<String?>(null);
  Ayah? _selAyah;
  Offset _selAt = Offset.zero;
  bool _chrome = true;
  bool _started = false;
  int _jump = 0;
  PageController? _pc;
  bool? _spreadMode;
  Timer? _hide;

  @override
  void initState() {
    super.initState();
    // Bars show on opening, then step aside so the whole page is visible.
    // A tap on the page brings them back.
    _hide = Timer(const Duration(seconds: 4), () {
      if (!mounted || !_chrome) return;
      setState(() => _chrome = false);
      final prefs = ref.read(sharedPreferencesProvider);
      if (prefs.getBool('mushafHint') != true) {
        prefs.setBool('mushafHint', true);
        toast(context, S.of(context).tapToShowBars);
      }
    });
  }

  @override
  void deactivate() {
    // Leaving the mushaf stops the recitation.
    final r = ref.read(recitationProvider);
    if (r.active) ref.read(recitationProvider.notifier).stop();
    super.deactivate();
  }

  @override
  void dispose() {
    _hide?.cancel();
    _pc?.dispose();
    _page.dispose();
    _selected.dispose();
    super.dispose();
  }

  void _start(QuranData q) {
    if (_started) return;
    _started = true;
    final a = widget.sura == null ? null : q.ayah(widget.sura!, widget.ayah ?? 1);
    _page.value = a != null ? q.pageOf(a) : (widget.page ?? ref.read(lastPageProvider));
    if (a != null && widget.ayah != null && widget.ayah! > 1) _selected.value = a.key;
  }

  void _onPage(int p) {
    if (p == _page.value) return;
    _page.value = p;
    ref.read(lastPageProvider.notifier).set(p);
    if (_selAyah != null) _clearSelection();
  }

  /// Turns one page forward (+1) or back (-1) with a short slide.
  void _turn(int delta) {
    final pc = _pc;
    if (pc == null || !pc.hasClients) return;
    final current = (pc.page ?? pc.initialPage.toDouble()).round();
    final last = (_spreadMode ?? false) ? QuranData.pageCount ~/ 2 - 1 : QuranData.pageCount - 1;
    final target = (current + delta).clamp(0, last);
    if (target != current) {
      pc.animateToPage(target, duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
    }
  }

  void _goTo(int p) {
    _clearSelection();
    _page.value = p;
    ref.read(lastPageProvider.notifier).set(p);
    final spread = _spreadMode ?? false;
    if (_pc != null && _pc!.hasClients) {
      _pc!.jumpToPage(spread ? (p - 1) ~/ 2 : p - 1);
    }
    setState(() => _jump++);
  }

  /// Forgets the page controller so the next one opens at the current page.
  /// The old one is disposed after the frame, once nothing uses it.
  void _dropController() {
    final old = _pc;
    _pc = null;
    if (old != null) WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  /// Recites from [from], or from the selected ayah, or from the top of
  /// the page on screen.
  Future<void> _play(QuranData q, {Ayah? from}) async {
    final s = S.of(context);
    final start = from ?? _selAyah ?? q.firstOn(_page.value);
    _clearSelection();
    if (!await ref.read(onlineCheckProvider)()) {
      if (mounted) toast(context, s.recitationFailed);
      return;
    }
    await ref.read(recitationProvider.notifier).playFrom(start);
  }

  /// Follows the recitation: highlights the ayah and turns to its page.
  void _follow(QuranData q, Ayah? a) {
    if (a == null) {
      if (_selAyah == null) _selected.value = null;
      return;
    }
    _selected.value = a.key;
    final p = q.pageOf(a);
    if (p == _page.value) return;
    final spread = _spreadMode ?? false;
    final mode = ref.read(settingsProvider).mushafMode;
    if (mode == MushafMode.page && !spread && p == _page.value + 1) {
      _turn(1);
    } else if (!(spread && (p - 1) ~/ 2 == (_page.value - 1) ~/ 2)) {
      _goTo(p);
      _selected.value = a.key;
    }
  }

  void _onAyah(Ayah a, Offset at) {
    HapticFeedback.selectionClick();
    _selected.value = a.key;
    setState(() {
      _selAyah = a;
      _selAt = at;
    });
  }

  void _clearSelection() {
    _selected.value = null;
    if (_selAyah != null) setState(() => _selAyah = null);
  }

  /// A tap shows or hides the bars (or closes an ayah's menu). Pages turn
  /// only with a swipe, so a tap never moves the page by accident.
  void _onTapPage([Offset? _]) {
    if (_selAyah != null) {
      _clearSelection();
      return;
    }
    _hide?.cancel();
    setState(() => _chrome = !_chrome);
  }

  @override
  Widget build(BuildContext context) {
    final quran = ref.watch(quranProvider);
    final t = context.t;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: dark ? t.bg : const Color(0xFFFFFCF2),
      body: quran.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (q) {
          if (!_started) _start(q);
          ref.listen(recitationProvider.select((r) => r.ayah), (_, a) => _follow(q, a));
          return _body(context, q);
        },
      ),
    );
  }

  Widget _body(BuildContext context, QuranData q) {
    final mode = ref.watch(settingsProvider.select((x) => x.mushafMode));
    final size = MediaQuery.sizeOf(context);
    final landscape = size.width > size.height;
    final spread = mode == MushafMode.page && landscape && size.width >= 840;
    if (_spreadMode != spread) {
      _dropController();
      _spreadMode = spread;
    }

    final Widget content;
    if (mode == MushafMode.large) {
      content = LargeTextView(
        key: ValueKey('large-$_jump'),
        q: q,
        startPage: _page.value,
        selected: _selected,
        onAyah: _onAyah,
        onPage: _onPage,
        onTap: () => _onTapPage(),
      );
    } else {
      _pc ??= PageController(initialPage: spread ? (_page.value - 1) ~/ 2 : _page.value - 1);
      content = Directionality(
        // Mushaf pages always turn right-to-left.
        textDirection: TextDirection.rtl,
        child: PageView.builder(
          controller: _pc,
          // Keep the pages either side built, so a swipe never waits.
          allowImplicitScrolling: true,
          // PageView's own snapping would replace [EasyPagePhysics] (and
          // ignore short swipes), so the physics does the snapping itself.
          pageSnapping: false,
          physics: const EasyPagePhysics(),
          itemCount: spread ? QuranData.pageCount ~/ 2 : QuranData.pageCount,
          onPageChanged: (i) => _onPage(spread ? i * 2 + 1 : i + 1),
          itemBuilder: (_, i) {
            Widget page(int p) => MushafPage(
              q: q,
              page: p,
              selected: _selected,
              onAyah: _onAyah,
              onTap: _onTapPage,
              scrollable: landscape && !spread,
            );
            // A thin edge between pages, so two pages never look like one
            // while they slide.
            if (!spread) {
              return RepaintBoundary(
                child: DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: const BoxDecoration(
                    border: BorderDirectional(
                      start: BorderSide(color: Color(0x33000000)),
                      end: BorderSide(color: Color(0x33000000)),
                    ),
                  ),
                  child: page(i + 1),
                ),
              );
            }
            // Right-to-left row: the odd page sits on the right.
            return RepaintBoundary(
              child: Row(
                children: [
                  Expanded(child: page(i * 2 + 1)),
                  Container(width: 1, color: const Color(0x22000000)),
                  Expanded(child: page(i * 2 + 2)),
                ],
              ),
            );
          },
        ),
      );
    }

    return Stack(
      children: [
        // Clear of the status bar and of the phone's own navigation buttons
        // or gesture bar, so no line is ever hidden behind them.
        Positioned.fill(child: SafeArea(child: content)),
        _TopBar(
          visible: _chrome,
          q: q,
          page: _page,
          mode: mode,
          onMode: () {
            ref
                .read(settingsProvider.notifier)
                .update((x) => x.copyWith(mushafMode: mode == MushafMode.page ? MushafMode.large : MushafMode.page));
            _clearSelection();
            // The pages reopen where Large text was left.
            _dropController();
            setState(() => _jump++);
          },
          onGoTo: () => _showGoTo(context, q),
        ),
        _BottomBar(visible: _chrome && _selAyah == null, onPlay: () => _play(q)),
        if (_selAyah != null)
          _AyahToolbar(
            ayah: _selAyah!,
            at: _selAt,
            q: q,
            onClose: _clearSelection,
            onPlay: (a) => _play(q, from: a),
          ),
      ],
    );
  }

  Future<void> _showGoTo(BuildContext context, QuranData q) async {
    final page = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _GoToSheet(q: q),
    );
    if (page != null && mounted) _goTo(page);
  }
}

/// Go to a page number or a surah. Returns the chosen page.
class _GoToSheet extends StatefulWidget {
  const _GoToSheet({required this.q});

  final QuranData q;

  @override
  State<_GoToSheet> createState() => _GoToSheetState();
}

class _GoToSheetState extends State<_GoToSheet> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _submit() {
    final p = int.tryParse(_c.text.trim());
    if (p != null && p >= 1 && p <= QuranData.pageCount) Navigator.pop(context, p);
  }

  @override
  Widget build(BuildContext ctx) {
    final s = S.of(ctx);
    final q = widget.q;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(ctx).height * 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  WordSafeText(s.goToPage, style: Theme.of(ctx).textTheme.headlineSmall),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _c,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onSubmitted: (_) => _submit(),
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: ctx.t.text),
                          decoration: InputDecoration(hintText: s.pageNumberHint),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 110,
                        child: BigButton(label: s.go, onPressed: _submit),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  WordSafeText(s.surahs, style: Theme.of(ctx).textTheme.titleLarge),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: q.suras.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) => SurahTile(sura: q.suras[i], onTap: () => Navigator.pop(ctx, q.suras[i].page)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dark translucent bar over the top of the page, like a reading app.
class _TopBar extends ConsumerWidget {
  const _TopBar({
    required this.visible,
    required this.q,
    required this.page,
    required this.mode,
    required this.onMode,
    required this.onGoTo,
  });

  final bool visible;
  final QuranData q;
  final ValueNotifier<int> page;
  final MushafMode mode;
  final VoidCallback onMode;
  final VoidCallback onGoTo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    const fg = Colors.white;
    final marks = ref.watch(settingsProvider.select((x) => x.pageBookmarks));
    Widget action(IconData icon, String label, VoidCallback onTap) => Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 68,
          height: kMinTap + 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: fg, size: 26),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            color: const Color(0xFF101C19),
            child: SafeArea(
              bottom: false,
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                  child: ValueListenableBuilder<int>(
                    valueListenable: page,
                    builder: (context, p, _) {
                      final first = q.firstOn(p);
                      final marked = marks.contains(p);
                      return Row(
                        children: [
                          IconButton(
                            tooltip: s.back,
                            onPressed: () => context.pop(),
                            icon: const Icon(Arrows.back, color: fg, size: 28),
                            style: IconButton.styleFrom(minimumSize: const Size(kMinTap, kMinTap)),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  q.sura(first.sura).name(s.ar),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: nameFont(
                                    context,
                                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: fg),
                                  ),
                                ),
                                Text(
                                  '${s.page(p)} · ${s.juz(first.juz)}',
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFFDDE8E1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          action(marked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, s.bookmark, () {
                            ref.read(settingsProvider.notifier).togglePageBookmark(p);
                            if (!marked) toast(context, s.bookmarked);
                          }),
                          action(
                            mode == MushafMode.page ? Icons.format_size_rounded : Icons.menu_book_rounded,
                            mode == MushafMode.page ? s.segLarge : s.segPage,
                            onMode,
                          ),
                          action(Icons.list_alt_rounded, s.goTo, onGoTo),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Listening bar: play from this page (or the chosen ayah), pause, stop,
/// and the recitation settings. Stays on screen while reciting.
class _BottomBar extends ConsumerWidget {
  const _BottomBar({required this.visible, required this.onPlay});

  final bool visible;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    const fg = Colors.white;
    const sub = Color(0xFFDDE8E1);
    final r = ref.watch(recitationProvider);
    final c = ref.read(recitationProvider.notifier);
    final q = ref.watch(quranProvider).value;
    final show = visible || r.active;
    Widget iconBtn(IconData icon, String tip, VoidCallback onTap) => IconButton(
      tooltip: tip,
      onPressed: onTap,
      icon: Icon(icon, color: fg, size: 32),
      style: IconButton.styleFrom(minimumSize: const Size(kMinTap, kMinTap)),
    );
    final a = r.ayah;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        ignoring: !show,
        child: AnimatedOpacity(
          opacity: show ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            color: const Color(0xFF101C19),
            child: SafeArea(
              top: false,
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.3,
                child: SizedBox(
                  height: 64,
                  child: a == null
                      ? InkWell(
                          onTap: onPlay,
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              const Icon(Icons.play_arrow_rounded, color: fg, size: 34),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${s.play} · ${r.reciter.name(s.ar)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: fg),
                                ),
                              ),
                              iconBtn(Icons.tune_rounded, s.recitationSettings, () => _showSettings(context)),
                              const SizedBox(width: 4),
                            ],
                          ),
                        )
                      : Row(
                          children: [
                            const SizedBox(width: 4),
                            r.loading
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 26,
                                      height: 26,
                                      child: CircularProgressIndicator(strokeWidth: 3, color: fg),
                                    ),
                                  )
                                : iconBtn(
                                    r.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    r.playing ? s.pause : s.play,
                                    c.toggle,
                                  ),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    q == null ? '' : s.ayahTitle(q.sura(a.sura).name(s.ar), a.ayah),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: nameFont(
                                      context,
                                      const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: fg),
                                    ),
                                  ),
                                  Text(
                                    r.failed
                                        ? s.recitationFailed
                                        : '${r.reciter.name(s.ar)} · ${s.repeatTimes(r.repeat)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: sub),
                                  ),
                                ],
                              ),
                            ),
                            iconBtn(Icons.tune_rounded, s.recitationSettings, () => _showSettings(context)),
                            iconBtn(Icons.stop_rounded, s.stop, c.stop),
                            const SizedBox(width: 4),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Reciter, repeat and speed.
void _showSettings(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Consumer(
      builder: (ctx, ref, _) {
        final s = S.of(ctx);
        final tt = Theme.of(ctx).textTheme;
        final r = ref.watch(recitationProvider);
        final c = ref.read(recitationProvider.notifier);
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.85),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WordSafeText(s.recitationSettings, style: tt.headlineSmall),
                const SizedBox(height: 14),
                WordSafeText(s.repeatL, style: tt.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final n in repeatChoices)
                      PickChip(label: s.repeatTimes(n), selected: r.repeat == n, onTap: () => c.setRepeat(n)),
                  ],
                ),
                const SizedBox(height: 16),
                WordSafeText(s.speedL, style: tt.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final v in speedChoices)
                      PickChip(label: s.n('×$v'), selected: r.speed == v, onTap: () => c.setSpeed(v)),
                  ],
                ),
                const SizedBox(height: 16),
                WordSafeText(s.reciterL, style: tt.titleMedium),
                const SizedBox(height: 8),
                for (final rc in reciters) ...[
                  ChoiceCard(title: rc.name(s.ar), selected: r.reciterId == rc.id, onTap: () => c.setReciter(rc.id)),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        );
      },
    ),
  );
}

/// Page turning that is easy on the hand: a short swipe in either direction
/// turns the page (no need to drag past halfway), and pages settle quickly.
class EasyPagePhysics extends PageScrollPhysics {
  const EasyPagePhysics({super.parent});

  @override
  EasyPagePhysics applyTo(ScrollPhysics? ancestor) => EasyPagePhysics(parent: buildParent(ancestor));

  @override
  SpringDescription get spring => const SpringDescription(mass: 0.6, stiffness: 260, damping: 25);

  /// Even a gentle flick counts (Flutter's default ignores flicks slower
  /// than 50 pixels a second, which made short swipes snap back).
  @override
  double get minFlingVelocity => 5;

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if ((velocity <= 0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final viewport = position.viewportDimension;
    final page = position.pixels / viewport;
    final tolerance = toleranceFor(position);
    // Any deliberate movement turns the page in that direction.
    final double target;
    if (velocity.abs() > 20) {
      target = velocity > 0 ? page.ceilToDouble() : page.floorToDouble();
    } else {
      target = page.roundToDouble();
    }
    final to = (target * viewport).clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((to - position.pixels).abs() < tolerance.distance) return null;
    return ScrollSpringSimulation(spring, position.pixels, to, velocity, tolerance: tolerance);
  }
}

/// 40 · Floating actions above the long-pressed ayah.
class _AyahToolbar extends ConsumerWidget {
  const _AyahToolbar({
    required this.ayah,
    required this.at,
    required this.q,
    required this.onClose,
    required this.onPlay,
  });

  final Ayah ayah;
  final ValueChanged<Ayah> onPlay;
  final Offset at;
  final QuranData q;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final size = MediaQuery.sizeOf(context);
    final marked = ref.watch(settingsProvider.select((x) => x.bookmarks.contains(ayah.key)));
    final student = ref.watch(settingsProvider.select((x) => x.role == UserRole.student));
    final barW = (size.width - 16).clamp(0.0, 360.0);
    const barH = 120.0;
    final left = (at.dx - barW / 2).clamp(8.0, size.width - barW - 8);
    var top = at.dy - barH - 28;
    if (top < MediaQuery.paddingOf(context).top + 8) top = at.dy + 36;

    Widget item(IconData icon, String label, VoidCallback onTap) => Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Positioned(
      left: left,
      top: top,
      width: barW,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.2,
        child: Material(
          color: SanadiTokens.light.primary,
          elevation: 6,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.ayahTitle(q.sura(ayah.sura).name(s.ar), ayah.ayah),
                  style: nameFont(
                    context,
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFDDE8E1)),
                  ),
                ),
                Row(
                  children: [
                    item(marked ? Icons.bookmark_rounded : Icons.bookmark_add_rounded, s.bookmark, () {
                      ref.read(settingsProvider.notifier).toggleBookmark(ayah.sura, ayah.ayah);
                      if (!marked) toast(context, s.bookmarked);
                      onClose();
                    }),
                    item(Icons.content_copy_rounded, s.copy, () {
                      Clipboard.setData(
                        ClipboardData(
                          text: '${ayah.plain}\n[${q.sura(ayah.sura).name(s.ar)} ${ayah.sura}:${ayah.ayah}]',
                        ),
                      );
                      toast(context, s.copied);
                      onClose();
                    }),
                    item(Icons.play_arrow_rounded, s.play, () {
                      onPlay(ayah);
                      onClose();
                    }),
                    if (student)
                      item(Icons.flag_rounded, s.setNextShort, () {
                        final count = q.sura(ayah.sura).count;
                        final to = ayah.ayah + 9 > count ? count : ayah.ayah + 9;
                        ref.read(ownNextPortionProvider.notifier).set(Portion(ayah.sura, ayah.ayah, to));
                        toast(context, s.nextPortionSet);
                        onClose();
                      }),
                    item(Icons.close_rounded, s.close, onClose),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
