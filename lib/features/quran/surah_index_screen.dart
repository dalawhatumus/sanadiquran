import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/settings.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';
import 'quran_data.dart';
import 'surah_search.dart';
import '../../core/digits.dart';

part 'surah_lists.dart';

/// Quran tab: a surah search, then Surahs (with juz' markers), Juz' and
/// Bookmarks.
class SurahIndexScreen extends ConsumerStatefulWidget {
  const SurahIndexScreen({super.key});

  @override
  ConsumerState<SurahIndexScreen> createState() => _SurahIndexScreenState();
}

class _SurahIndexScreenState extends ConsumerState<SurahIndexScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final settings = ref.watch(settingsProvider);
    final quran = ref.watch(quranProvider);
    final teacher = settings.role == UserRole.teacher;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: WordSafeText(s.navQuran, maxLines: 1, style: tt.headlineMedium),
                        ),
                      ),
                    ),
                    if (teacher) ...[_AthkarPill(onTap: () => context.push(Routes.athkar)), const SizedBox(width: 8)],
                    // Teachers also have the athkar button here, so settings
                    // shows just the picture and every word stays whole.
                    SettingsChip(compact: teacher),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: TextField(
                  key: const ValueKey('surah-search'),
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: t.text),
                  decoration: InputDecoration(
                    hintText: s.searchSurah,
                    prefixIcon: Icon(Icons.search_rounded, color: t.muted, size: 28),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: s.clear,
                            icon: Icon(Icons.close_rounded, color: t.muted, size: 26),
                            onPressed: () => setState(_search.clear),
                          ),
                  ),
                ),
              ),
              if (_search.text.trim().isNotEmpty)
                Expanded(
                  child: quran.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('$e')),
                    data: (q) => _SearchResults(q: q, query: _search.text),
                  ),
                )
              else ...[
                MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.3,
                  child: TabBar(
                    labelColor: t.primary,
                    unselectedLabelColor: t.muted,
                    indicatorColor: t.primary,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    tabs: [
                      Tab(height: kMinTap, child: WordSafeText(s.surahs, maxLines: 1)),
                      Tab(height: kMinTap, child: WordSafeText(s.juzTab, maxLines: 1)),
                      Tab(
                        height: kMinTap,
                        child: Semantics(
                          label: s.bookmarks,
                          excludeSemantics: true,
                          child: const Icon(Icons.bookmarks_rounded, size: 28),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: quran.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('$e')),
                    data: (q) => TabBarView(
                      children: [
                        _SurahList(q: q),
                        _JuzList(q: q),
                        _BookmarkList(q: q),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Surahs matching the search, best first, and the page with that number
/// when a number is typed.
class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.q, required this.query});

  final QuranData q;
  final String query;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final found = searchSurahs(q, query);
    final digits = westernDigits(query.trim());
    final page = RegExp(r'^[0-9]{1,3}$').hasMatch(digits) ? int.parse(digits) : null;
    final showPage = page != null && page >= 1 && page <= QuranData.pageCount;
    if (found.isEmpty && !showPage) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(s.noSurahFound, style: tt.bodyLarge, textAlign: TextAlign.center),
      );
    }
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final sura in found) SurahTile(sura: sura),
        if (showPage)
          ListTile(
            minTileHeight: kMinTap + 8,
            leading: Icon(Icons.menu_book_rounded, color: t.primary, size: 30),
            title: WordSafeText(s.page(page), style: tt.titleMedium!.copyWith(color: t.heading)),
            trailing: Icon(Arrows.next, color: t.primary, size: 30),
            onTap: () => context.push(Routes.mushafAt(page: page)),
          ),
      ],
    );
  }
}

class _AthkarPill extends StatelessWidget {
  const _AthkarPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Material(
        color: t.tint,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kMinTap),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SIcon(SIcons.misbaha, size: 24, color: t.primary),
                  const SizedBox(width: 6),
                  Text(
                    S.of(context).athkarTitle,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.heading),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
