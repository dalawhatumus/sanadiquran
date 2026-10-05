import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Temporary wordmark until the logo is ready. The Arabic name is always
/// written with its vowel marks (سَنَدي) so it isn't read as "Sindi".
class AppTitle extends StatelessWidget {
  const AppTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        CircleAvatar(
          radius: 52,
          backgroundColor: SanadiColors.green,
          child: const Icon(Icons.menu_book, size: 52, color: SanadiColors.gold),
        ),
        const SizedBox(height: 20),
        Text(
          'سَنَدي',
          textDirection: TextDirection.rtl,
          style: theme.textTheme.headlineLarge?.copyWith(
            fontFamily: 'IBMPlexSansArabic',
            color: SanadiColors.green,
            fontSize: 44,
          ),
        ),
        Text(
          'Sanadi',
          textDirection: TextDirection.ltr,
          style: theme.textTheme.titleLarge?.copyWith(
            fontFamily: 'AtkinsonHyperlegible',
            color: SanadiColors.gold,
          ),
        ),
      ],
    );
  }
}
