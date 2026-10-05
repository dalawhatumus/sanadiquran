import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/common.dart';

class QuranScreen extends StatelessWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: SanadiAppBar(title: l10n.quranTitle),
      body: EmptyState(icon: Icons.menu_book, message: l10n.quranPlaceholder),
    );
  }
}
