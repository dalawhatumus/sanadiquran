import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/reminders.dart';
import '../../core/router.dart';
import '../../core/settings.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';

/// 1 · Splash: vertical cream logo on Deep Green.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (!mounted) return;
      final next = nextStep(ref.read(settingsProvider));
      context.go(next);
      // Started from an athkar reminder: open it over the home screen.
      final reminder = Reminders.instance.takeLaunchRoute();
      if (reminder != null && (next == Routes.studentHome || next == Routes.teacherHome)) {
        GoRouter.of(context).push(reminder);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SanadiTokens.light.deep,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Logo('sanadi-vertical-cream', height: 150),
            const SizedBox(height: 48),
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 3, color: SanadiTokens.light.bg),
            ),
          ],
        ),
      ),
    );
  }
}
