import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../backend/sessions.dart';
import '../../core/connectivity.dart';
import '../../core/screen.dart';
import '../../core/settings.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';
import '../call/call_controller.dart';
import 'easy_page_physics.dart';
import 'large_text_view.dart';
import 'mushaf_page.dart';
import 'quran_data.dart';
import 'recitation.dart';
import 'surah_index_screen.dart';

part 'mushaf_bars.dart';
part 'mushaf_ayah_menu.dart';
part 'mushaf_go_to.dart';

/// Auto scroll speed, 1 (slowest) to 10. Kept on this phone.
class AutoScrollSpeed extends Notifier<int> {
  static const _key = 'autoScrollSpeed';
  static const min = 1;
  static const max = 10;

  @override
  int build() => (ref.read(sharedPreferencesProvider).getInt(_key) ?? 3).clamp(min, max);

  void set(int v) {
    state = v.clamp(min, max);
    ref.read(sharedPreferencesProvider).setInt(_key, state);
  }
}

final autoScrollSpeedProvider = NotifierProvider<AutoScrollSpeed, int>(AutoScrollSpeed.new);

/// Large text: how far the text moves each second.
double autoScrollPixels(int speed) => 6.0 + (speed - 1) * 4;

/// Mushaf pages: how long each page stays before turning.
Duration autoTurnAfter(int speed) => Duration(seconds: 150 - (speed - 1) * 12);

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

  // Auto scroll: the text moves (large text) or pages turn (mushaf pages)
  // by themselves, at the chosen speed, until stopped.
  bool _auto = false;
  bool _autoPaused = false;
  final _autoPx = ValueNotifier<double>(0);
  final _autoProgress = ValueNotifier<double>(0);
  Timer? _autoTimer;
  int _autoMs = 0;

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
    _autoTimer?.cancel();
    if (_auto) _keepScreenOn(false);
    _autoPx.dispose();
    _autoProgress.dispose();
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
    // A new page gets its full time before the next turn.
    _autoMs = 0;
    _autoProgress.value = 0;
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

  /// The screen stays on while auto scroll runs (and during a call, which
  /// keeps it on by itself).
  void _keepScreenOn(bool on) {
    if (!on && ref.read(callControllerProvider).inCall) return;
    Screen.keepOn(on);
  }

  void _startAuto() {
    final r = ref.read(recitationProvider);
    if (r.active) ref.read(recitationProvider.notifier).stop();
    _clearSelection();
    _hide?.cancel();
    setState(() {
      _auto = true;
      _autoPaused = false;
      // Out of the way of the text; a tap brings the controls back.
      _chrome = false;
    });
    _autoMs = 0;
    _keepScreenOn(true);
    _applyAuto();
  }

  void _stopAuto() {
    if (!_auto) return;
    _autoTimer?.cancel();
    _autoTimer = null;
    _autoPx.value = 0;
    _autoProgress.value = 0;
    _keepScreenOn(false);
    if (mounted) setState(() => _auto = false);
  }

  void _pauseAuto() {
    setState(() => _autoPaused = !_autoPaused);
    _applyAuto();
  }

  void _autoSpeed(int delta) {
    final n = ref.read(autoScrollSpeedProvider.notifier);
    n.set(ref.read(autoScrollSpeedProvider) + delta);
    _applyAuto();
  }

  /// Sets the large text speed, or runs the page timer, for the mode and
  /// speed now chosen.
  void _applyAuto() {
    final running = _auto && !_autoPaused;
    final speed = ref.read(autoScrollSpeedProvider);
    final large = ref.read(settingsProvider).mushafMode == MushafMode.large;
    _autoPx.value = running && large ? autoScrollPixels(speed) : 0;
    _autoTimer?.cancel();
    _autoTimer = null;
    if (!running || large) return;
    const step = Duration(milliseconds: 250);
    _autoTimer = Timer.periodic(step, (_) {
      // Two pages side by side stay twice as long.
      final total = autoTurnAfter(ref.read(autoScrollSpeedProvider)).inMilliseconds * ((_spreadMode ?? false) ? 2 : 1);
      _autoMs += step.inMilliseconds;
      _autoProgress.value = (_autoMs / total).clamp(0, 1);
      if (_autoMs < total) return;
      _autoMs = 0;
      final last = (_spreadMode ?? false)
          ? (_page.value - 1) ~/ 2 >= QuranData.pageCount ~/ 2 - 1
          : _page.value >= QuranData.pageCount;
      if (last) {
        _stopAuto();
      } else {
        _turn(1);
      }
    });
  }

  /// Recites from [from], or from the selected ayah, or from the top of
  /// the page on screen.
  Future<void> _play(QuranData q, {Ayah? from}) async {
    final s = S.of(context);
    // Reciting turns the pages itself.
    _stopAuto();
    final start = from ?? _selAyah ?? q.firstOn(_page.value);
    _clearSelection();
    // Show the player, so pause and stop are at hand; a tap hides it again.
    _hide?.cancel();
    if (!_chrome) setState(() => _chrome = true);
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
    final t = context.t;
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
        autoScroll: _autoPx,
        onAutoEnd: _stopAuto,
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
            if (_auto) WidgetsBinding.instance.addPostFrameCallback((_) => _applyAuto());
          },
          onGoTo: () => _showGoTo(context, q),
        ),
        if (_auto) ...[
          // A thin line showing when the page will turn, clear of the text.
          if (!_chrome && mode == MushafMode.page)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: ValueListenableBuilder<double>(
                  valueListenable: _autoProgress,
                  builder: (_, v, _) => LinearProgressIndicator(
                    value: v,
                    minHeight: 3,
                    backgroundColor: Colors.transparent,
                    color: t.primary.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          _AutoScrollBar(
            visible: _chrome && _selAyah == null,
            paused: _autoPaused,
            progress: mode == MushafMode.page ? _autoProgress : null,
            onPause: _pauseAuto,
            onSlower: () => _autoSpeed(-1),
            onFaster: () => _autoSpeed(1),
            onStop: _stopAuto,
          ),
        ] else
          _BottomBar(visible: _chrome && _selAyah == null, onPlay: () => _play(q), onAuto: _startAuto),
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
