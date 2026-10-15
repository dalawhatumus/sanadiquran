import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/countries.dart';
import '../../core/router.dart';
import '../../core/settings.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';

/// 6b · A little about you (Step 4 of 5): age group, nationality and phone
/// number, and the optional WhatsApp community. Also opened from Settings
/// ([editing]) to change them, and shown once to people who signed up
/// before it was asked.
class DetailsScreen extends ConsumerStatefulWidget {
  const DetailsScreen({super.key, this.editing = false});

  final bool editing;

  @override
  ConsumerState<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends ConsumerState<DetailsScreen> {
  late final AppSettings _start = ref.read(settingsProvider);
  late String? _age = _start.ageGroup;
  late Country? _nationality = Country.byCode(_start.nationality);
  late Country? _dial = Country.forPhone(_start.phone, prefer: _start.nationality);
  late final _phone = TextEditingController(text: _dial == null ? '' : localPart(_dial!, _start.phone));
  late bool _whatsapp = _start.whatsapp;
  bool _tried = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  String? get _fullPhone => _dial == null ? null : fullPhone(_dial!, _phone.text);

  void _save() {
    final phone = _fullPhone;
    if (_age == null || _nationality == null || phone == null) {
      setState(() => _tried = true);
      return;
    }
    ref
        .read(settingsProvider.notifier)
        .update((x) => x.copyWith(ageGroup: _age, nationality: _nationality!.code, phone: phone, whatsapp: _whatsapp));
    if (widget.editing) {
      context.pop();
    } else {
      context.go(nextStep(ref.read(settingsProvider)));
    }
  }

  Future<void> _pickNationality() async {
    final c = await pickCountry(context, title: S.of(context).nationalityL);
    if (c == null || !mounted) return;
    setState(() {
      _nationality = c;
      // Most people's number is from their own country; it can be changed.
      if (_phone.text.trim().isEmpty) _dial = c;
    });
  }

  Future<void> _pickDial() async {
    final c = await pickCountry(context, title: S.of(context).countryCodeL, showDial: true);
    if (c != null && mounted) setState(() => _dial = c);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final phoneBad = _tried && _fullPhone == null;
    Widget error(String text) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.warn),
      ),
    );

    return StepScaffold(
      showBack: true,
      onBack: () => context.canPop() ? context.pop() : context.go(Routes.name),
      step: widget.editing ? null : s.stepOf(4, 5),
      content: [
        WordSafeText(widget.editing ? s.yourDetails : s.detailsTitle, style: tt.headlineMedium),
        const SizedBox(height: 8),
        Text(s.detailsSub, style: tt.bodyMedium),
        const SizedBox(height: 24),

        // Age group.
        WordSafeText(s.ageGroupL, style: tt.titleMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final g in ageGroups)
              PickChip(label: s.ageLabel(g), selected: _age == g, onTap: () => setState(() => _age = g)),
          ],
        ),
        if (_tried && _age == null) error(s.needAge),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.child_care_rounded, color: t.muted, size: 26),
            const SizedBox(width: 8),
            Expanded(child: Text(s.under18Note, style: tt.bodySmall)),
          ],
        ),
        const SizedBox(height: 24),

        // Nationality.
        WordSafeText(s.nationalityL, style: tt.titleMedium),
        const SizedBox(height: 10),
        SCard(
          key: const ValueKey('nationality'),
          onTap: _pickNationality,
          border: _tried && _nationality == null ? t.warn : null,
          child: Row(
            children: [
              if (_nationality != null) ...[
                Text(_nationality!.flag, style: const TextStyle(fontSize: 30)),
                const SizedBox(width: 12),
              ] else ...[
                Icon(Icons.public_rounded, color: t.muted, size: 30),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: WordSafeText(
                  _nationality?.name(s.ar) ?? s.chooseNationality,
                  style: tt.titleMedium!.copyWith(color: _nationality == null ? t.muted : t.text),
                ),
              ),
              Icon(Arrows.next, color: t.primary, size: 30),
            ],
          ),
        ),
        if (_tried && _nationality == null) error(s.needNationality),
        const SizedBox(height: 24),

        // Phone.
        WordSafeText(s.phoneL, style: tt.titleMedium),
        const SizedBox(height: 6),
        Text(s.phoneSub, style: tt.bodySmall),
        const SizedBox(height: 10),
        // Numbers read left to right in every language. At large text sizes
        // the code sits above the number, so the number has the full width.
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              final dial = Semantics(
                button: true,
                label: '${s.countryCodeL}: ${_dial == null ? s.chooseNationality : '+${_dial!.dial}'}',
                excludeSemantics: true,
                child: Material(
                  color: t.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: t.muted, width: 2),
                  ),
                  child: InkWell(
                    key: const ValueKey('dial'),
                    customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onTap: _pickDial,
                    child: SizedBox(
                      height: 64,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_dial != null) Text(_dial!.flag, style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 6),
                            Text(
                              _dial == null ? '+' : '+${_dial!.dial}',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: t.text),
                            ),
                            Icon(Icons.arrow_drop_down_rounded, color: t.muted, size: 28),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
              final field = TextField(
                key: const ValueKey('phone'),
                controller: _phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                maxLength: 20,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹+\s\-]'))],
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _save(),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: t.text),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: _dial?.example,
                  errorText: phoneBad ? s.phoneInvalid : null,
                  errorMaxLines: 3,
                ),
              );
              if (MediaQuery.textScalerOf(context).scale(1) > 1.3) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [dial, const SizedBox(height: 10), field],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  dial,
                  const SizedBox(width: 10),
                  Expanded(child: field),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        // WhatsApp community (optional).
        SCard(
          onTap: () => setState(() => _whatsapp = !_whatsapp),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WordSafeText(s.whatsappL, style: tt.titleMedium!.copyWith(color: t.heading)),
                    const SizedBox(height: 4),
                    Text(s.whatsappSub, style: tt.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch(value: _whatsapp, onChanged: (v) => setState(() => _whatsapp = v)),
            ],
          ),
        ),
      ],
      bottom: [
        BigButton(
          label: widget.editing ? s.save : s.next,
          trailingIcon: widget.editing ? null : Arrows.forward,
          icon: widget.editing ? Icons.check_rounded : null,
          onPressed: _save,
        ),
      ],
    );
  }
}

/// A searchable list of countries; returns the one tapped. [showDial] adds
/// each calling code.
Future<Country?> pickCountry(BuildContext context, {required String title, bool showDial = false}) =>
    showModalBottomSheet<Country>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CountrySheet(title: title, showDial: showDial),
    );

class _CountrySheet extends StatefulWidget {
  const _CountrySheet({required this.title, required this.showDial});

  final String title;
  final bool showDial;

  @override
  State<_CountrySheet> createState() => _CountrySheetState();
}

class _CountrySheetState extends State<_CountrySheet> {
  String _query = '';

  static String _fold(String x) => x
      .toLowerCase()
      .replaceAll(RegExp('[ًٌٍَُِّْـ]'), '')
      .replaceAll(RegExp('[أإآ]'), 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي');

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final q = _fold(_query.trim()).replaceFirst('+', '');
    final list = [
      for (final c in Country.sorted(s.ar))
        if (q.isEmpty ||
            _fold(c.ar).contains(q) ||
            _fold(c.en).contains(q) ||
            c.code.toLowerCase() == q ||
            (widget.showDial && '${c.dial}'.startsWith(q)))
          c,
    ];
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: WordSafeText(widget.title, style: tt.headlineSmall),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                autofocus: false,
                onChanged: (v) => setState(() => _query = v),
                style: TextStyle(fontSize: 20, color: t.text),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded, color: t.muted, size: 28),
                  hintText: s.search,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SafeArea(
                top: false,
                child: ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final c = list[i];
                    return InkWell(
                      onTap: () => Navigator.pop(context, c),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: kMinTap),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Row(
                            children: [
                              Text(c.flag, style: const TextStyle(fontSize: 28)),
                              const SizedBox(width: 14),
                              Expanded(child: WordSafeText(c.name(s.ar), style: tt.titleMedium)),
                              if (widget.showDial)
                                Text(
                                  '+${c.dial}',
                                  textDirection: TextDirection.ltr,
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: t.muted),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
