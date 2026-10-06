import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings.dart';
import '../../core/strings.dart';
import '../../widgets/ui.dart';

/// Messages tab (screens 48–50 are in a later design batch).
class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final teacher = ref.watch(settingsProvider).role == UserRole.teacher;
    return Scaffold(
      body: SafeArea(
        child: EmptyState(
          icon: const Icon(Icons.chat_bubble_rounded),
          title: s.messagesSoonTitle,
          body: teacher ? s.messagesSoonBodyTeacher : s.messagesSoonBody,
        ),
      ),
    );
  }
}
