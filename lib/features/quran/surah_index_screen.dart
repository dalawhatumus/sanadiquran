import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/settings.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';
import 'quran_data.dart';

/// Quran tab: continue reading, bookmarks and the 114 surahs.
class SurahIndexScreen extends ConsumerWidget {
  const SurahIndexScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final settings = ref.watch(settingsProvider);
    final quran = ref.watch(quranProvider);
    final initial = settings.name.isEmpty ? '' : settings.name.characters.first.toUpperCase();
    final teacher = settings.role == UserRole.teacher;

    return Scaffold(
      body: SafeArea(
        child: quran.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (q) => CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverList.list(
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(s.navQuran, style: tt.headlineMedium)),
                        SettingsChip(initial: initial),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _ContinueCard(q: q, page: settings.lastPage),
                    if (teacher) ...[
                      const SizedBox(height: 12),
                      SCard(
                        onTap: () => context.push(Routes.athkar),
                        child: Row(
                          children: [
                            TintBox(child: SIcon(SIcons.misbaha, color: t.primary)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(s.athkarTitle, style: tt.titleLarge!.copyWith(color: t.text)),
                            ),
                            Icon(
                              context.isAr ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                              color: t.primary,
                              size: 32,
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (settings.bookmarks.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SCard(
                        onTap: () => showBookmarks(context, ref, q),
                        child: Row(
                          children: [
                            TintBox(child: Icon(Icons.bookmark_rounded, color: t.primary)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(s.bookmarks, style: tt.titleLarge!.copyWith(color: t.text)),
                            ),
                            Text(s.n(settings.bookmarks.length), style: tt.titleMedium),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(s.surahs, style: tt.titleLarge),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverList.separated(
                  itemCount: q.suras.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => SurahTile(sura: q.suras[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.q, required this.page});

  final QuranData q;
  final int page;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    final first = q.page(page).first;
    final sura = q.sura(first.sura);
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: t.onPrimary),
                ),
                Text(
                  sura.name(s.ar),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: t.onPrimary),
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

class SurahTile extends StatelessWidget {
  const SurahTile({super.key, required this.sura, this.onTap});

  final Sura sura;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    return SCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap ?? () => context.push(Routes.mushafAt(sura: sura.number, ayah: 1)),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: t.tint, borderRadius: BorderRadius.circular(12)),
            child: Text(
              s.n(sura.number),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: t.primary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sura.name(s.ar), style: tt.titleMedium!.copyWith(color: t.heading)),
                Text('${s.ayahsCount(sura.count)} · ${s.page(sura.page)}', style: tt.bodySmall),
              ],
            ),
          ),
          if (!s.ar) ...[
            const SizedBox(width: 10),
            Text(
              sura.ar,
              textDirection: TextDirection.rtl,
              style: TextStyle(fontFamily: 'Tajawal', fontSize: 22, fontWeight: FontWeight.w700, color: t.primary),
            ),
          ],
        ],
      ),
    );
  }
}

void showBookmarks(BuildContext context, WidgetRef ref, QuranData q, {void Function(Ayah a)? onOpen}) {
  final s = S.of(context);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final marks = ref.read(settingsProvider).bookmarks;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.7),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              Text(s.bookmarks, style: Theme.of(ctx).textTheme.headlineSmall),
              const SizedBox(height: 12),
              for (final m in marks.reversed)
                if (q.ayah(int.parse(m.split(':')[0]), int.parse(m.split(':')[1])) case final a?)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SCard(
                      color: ctx.t.bg,
                      onTap: () {
                        Navigator.pop(ctx);
                        if (onOpen != null) {
                          onOpen(a);
                        } else {
                          context.push(Routes.mushafAt(sura: a.sura, ayah: a.ayah));
                        }
                      },
                      child: Row(
                        children: [
                          Icon(Icons.bookmark_rounded, color: ctx.t.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              s.ayahTitle(q.sura(a.sura).name(s.ar), a.ayah),
                              style: Theme.of(ctx).textTheme.titleSmall,
                            ),
                          ),
                          Text(s.page(a.page), style: Theme.of(ctx).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      );
    },
  );
}
