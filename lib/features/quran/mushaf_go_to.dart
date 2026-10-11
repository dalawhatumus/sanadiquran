part of 'mushaf_screen.dart';

// The "Go to" sheet: a page number or a surah.

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
