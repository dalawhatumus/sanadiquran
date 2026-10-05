import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/common.dart';

class StudentsScreen extends StatelessWidget {
  const StudentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: SanadiAppBar(title: l10n.studentsTitle),
      body: EmptyState(icon: Icons.groups, message: l10n.studentsEmpty),
    );
  }
}
