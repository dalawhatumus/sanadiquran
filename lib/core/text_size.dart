import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings.dart';

/// Text size inside Sanadi: null follows the phone's setting; otherwise a
/// fixed size from 100% to 200% (every screen is checked at 200%).
class TextSize extends Notifier<double?> {
  static const _key = 'textScale';
  static const choices = [1.0, 1.25, 1.5, 1.75, 2.0];

  @override
  double? build() {
    final v = ref.read(sharedPreferencesProvider).getDouble(_key);
    return v?.clamp(1.0, 2.0).toDouble();
  }

  void set(double? scale) {
    state = scale;
    final p = ref.read(sharedPreferencesProvider);
    scale == null ? p.remove(_key) : p.setDouble(_key, scale);
  }
}

final textSizeProvider = NotifierProvider<TextSize, double?>(TextSize.new);

/// Applies the chosen text size below it (or leaves the phone's).
class AppTextSize extends ConsumerWidget {
  const AppTextSize({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = ref.watch(textSizeProvider);
    if (scale == null) return child;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
      child: child,
    );
  }
}
