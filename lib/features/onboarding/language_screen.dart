import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/settings.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';

/// 2 · Choose language. Shown in both languages at once.
class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key});

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  String? _code;

  @override
  void initState() {
    super.initState();
    _code = ref.read(settingsProvider).locale?.languageCode;
  }

  void _continue() {
    final n = ref.read(settingsProvider.notifier);
    n.update((s) => s.copyWith(locale: Locale(_code!)));
    context.go(nextStep(ref.read(settingsProvider)));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    Widget letter(String l) => Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: t.tint, shape: BoxShape.circle),
      child: Text(
        l,
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: t.primary, fontFamily: 'Tajawal'),
      ),
    );
    return StepScaffold(
      center: true,
      content: [
        Center(
          child: Illustration(size: 112, child: SIcon(SIcons.language, size: 56, color: t.primary)),
        ),
        const SizedBox(height: 20),
        Text(
          S.chooseLanguageAr,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyle(fontFamily: 'Tajawal', fontSize: 28, fontWeight: FontWeight.w700, color: t.heading),
        ),
        Text(
          S.chooseLanguageEn,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontFamilyFallback: const ['Tajawal'],
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: t.heading,
          ),
        ),
        const SizedBox(height: 24),
        Directionality(
          textDirection: TextDirection.rtl,
          child: ChoiceCard(
            leading: letter('ع'),
            title: 'العربية',
            subtitle: 'Arabic',
            selected: _code == 'ar',
            onTap: () => setState(() => _code = 'ar'),
          ),
        ),
        const SizedBox(height: 12),
        Directionality(
          textDirection: TextDirection.ltr,
          child: ChoiceCard(
            leading: letter('A'),
            title: 'English',
            subtitle: 'الإنجليزية',
            selected: _code == 'en',
            onTap: () => setState(() => _code = 'en'),
          ),
        ),
      ],
      bottom: [
        BigButton(
          label: S.continueBoth,
          trailingIcon: Icons.arrow_forward_rounded,
          onPressed: _code == null ? null : _continue,
        ),
      ],
    );
  }
}
