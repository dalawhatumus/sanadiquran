import 'package:flutter/material.dart';

import '../../core/strings.dart';
import '../../widgets/ui.dart';

/// Teacher "Students" tab (screens 35–36 are in the next design batch).
class StudentsScreen extends StatelessWidget {
  const StudentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      body: SafeArea(
        child: EmptyState(
          icon: const SIcon(SIcons.students, size: 52),
          title: s.studentsSoonTitle,
          body: s.studentsSoonBody,
        ),
      ),
    );
  }
}
