part of 'surah_index_screen.dart';

// The Quran tab's lists: continue reading, surahs (with juz' rows), juz' and
// bookmarks.

/// Continue-reading card shown above the surah list.
class _ContinueCard extends ConsumerWidget {
  const _ContinueCard({required this.q});

  final QuranData q;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.t;
    final page = ref.watch(lastPageProvider);
    final first = q.firstOn(page);
    return SCard(
      color: t.primary,
      onTap: () => context.push(Routes.mushafAt(page: page)),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: t.onPrimary.withValues(alpha: 0.18), shape: BoxShape.circle),
            child: SIcon(SIcons.rehal, color: t.onPrimary, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.continueReading,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: t.onPrimary),
                ),
                Text(
                  q.sura(first.sura).name(s.ar),
                  style: nameFont(context, TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: t.onPrimary)),
                ),
                Text(
                  s.juzPage(first.juz, page),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: t.onPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SurahList extends StatelessWidget {
  const _SurahList({required this.q});

  final QuranData q;

  @override
  Widget build(BuildContext context) {
    // Surahs in order, with a juz' row wherever a new juz' begins: before a
    // surah that opens the juz', or after the surah it starts inside.
    final rows = <Object>[];
    var next = 1; // juz' 1 starts with the list itself
    for (final sura in q.suras) {
      while (next < q.juzStarts.length) {
        final js = q.juzStarts[next];
        if (js.sura < sura.number || (js.sura == sura.number && js.ayah == 1)) {
          rows.add(js);
          next++;
        } else {
          break;
        }
      }
      rows.add(sura);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: rows.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: _ContinueCard(q: q),
          );
        }
        final r = rows[i - 1];
        return r is Sura ? SurahTile(sura: r) : _JuzRow(js: r as JuzStart, q: q);
      },
    );
  }
}

/// A surah in the list: number, name, Makki/Madani and ayah count, page.
class SurahTile extends StatelessWidget {
  const SurahTile({super.key, required this.sura, this.onTap});

  final Sura sura;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    // With large text there isn't room for three things side by side, so
    // the Arabic name moves under the English one.
    final big = MediaQuery.textScalerOf(context).scale(10) > 13;
    final arabicName = Text(
      sura.ar,
      textDirection: TextDirection.rtl,
      style: nameFont(context, TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: t.primary), arabic: true),
    );
    return InkWell(
      onTap: onTap ?? () => context.push(Routes.mushafAt(sura: sura.number, ayah: 1)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    s.n(sura.number),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: t.muted),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WordSafeText(sura.name(s.ar), style: nameFont(context, tt.titleMedium!.copyWith(color: t.heading))),
                    if (!s.ar && big)
                      WordSafeText(
                        sura.ar,
                        style: nameFont(
                          context,
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: t.primary),
                          arabic: true,
                        ),
                      ),
                    WordSafeText(
                      '${sura.madani ? s.madani : s.makki} · ${s.ayahsCount(sura.count)}',
                      style: tt.bodySmall,
                    ),
                  ],
                ),
              ),
              if (!s.ar && !big) ...[const SizedBox(width: 10), arabicName],
              const SizedBox(width: 12),
              Text(
                s.n(sura.page),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: t.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JuzRow extends StatelessWidget {
  const _JuzRow({required this.js, required this.q});

  final JuzStart js;
  final QuranData q;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    return Material(
      color: t.tint,
      child: InkWell(
        onTap: () => context.push(Routes.mushafAt(page: js.page)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kMinTap),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    s.juz(js.juz),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: t.heading),
                  ),
                ),
                Text(
                  s.n(js.page),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: t.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JuzList extends StatelessWidget {
  const _JuzList({required this.q});

  final QuranData q;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: q.juzStarts.length,
      separatorBuilder: (_, _) => Divider(height: 1, color: t.line),
      itemBuilder: (context, i) {
        final js = q.juzStarts[i];
        return InkWell(
          onTap: () => context.push(Routes.mushafAt(page: js.page)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: t.tint, borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      s.n(js.juz),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: t.primary),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.juz(js.juz), style: tt.titleMedium!.copyWith(color: t.heading)),
                        Text(s.ayahTitle(q.sura(js.sura).name(s.ar), js.ayah), style: nameFont(context, tt.bodySmall!)),
                      ],
                    ),
                  ),
                  Text(
                    s.n(js.page),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: t.muted),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BookmarkList extends ConsumerWidget {
  const _BookmarkList({required this.q});

  final QuranData q;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final settings = ref.watch(settingsProvider);
    final current = ref.watch(lastPageProvider);

    Widget header(String text) => Container(
      width: double.infinity,
      color: t.tint,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        text,
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: t.heading),
      ),
    );
    Widget row(IconData icon, String title, String sub, int page, VoidCallback onTap, {Color? iconColor}) => InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: iconColor ?? t.heading, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: nameFont(context, tt.titleMedium!.copyWith(color: t.heading))),
                    Text(sub, style: tt.bodySmall),
                  ],
                ),
              ),
              Text(
                s.n(page),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: t.muted),
              ),
            ],
          ),
        ),
      ),
    );

    String subFor(int page) => s.juzPage(q.juzOfPage(page), page);
    final ayahMarks = [
      for (final m in settings.bookmarks.reversed) ?q.ayah(int.parse(m.split(':')[0]), int.parse(m.split(':')[1])),
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        header(s.currentPage),
        row(
          Icons.auto_stories_rounded,
          q.sura(q.firstOn(current).sura).name(s.ar),
          subFor(current),
          current,
          () => context.push(Routes.mushafAt(page: current)),
        ),
        header(s.pageBookmarks),
        if (settings.pageBookmarks.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(s.noPageBookmarks, style: tt.bodyMedium),
          )
        else
          for (final p in settings.pageBookmarks.reversed)
            row(
              Icons.bookmark_rounded,
              q.sura(q.firstOn(p).sura).name(s.ar),
              subFor(p),
              p,
              () => context.push(Routes.mushafAt(page: p)),
            ),
        header(s.ayahBookmarks),
        if (ayahMarks.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(s.noAyahBookmarks, style: tt.bodyMedium),
          )
        else
          for (final a in ayahMarks)
            row(
              Icons.bookmark_rounded,
              s.ayahTitle(q.sura(a.sura).name(s.ar), a.ayah),
              subFor(q.pageOf(a)),
              q.pageOf(a),
              () => context.push(Routes.mushafAt(sura: a.sura, ayah: a.ayah)),
              iconColor: t.primary,
            ),
      ],
    );
  }
}
