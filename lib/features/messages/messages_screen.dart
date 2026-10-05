import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/common.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: SanadiAppBar(title: l10n.messagesTitle),
      body: EmptyState(icon: Icons.chat_bubble_outline, message: l10n.messagesEmpty),
    );
  }
}
