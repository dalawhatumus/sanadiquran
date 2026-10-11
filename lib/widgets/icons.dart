import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/theme.dart';

// Icons and arrows used across the app.

/// Direction arrows that never flip with the language. App rule: an arrow
/// pointing right always means "proceed", pointing left always "go back",
/// in English and Arabic alike.
abstract final class Arrows {
  static const forward = IconData(0xf57a, fontFamily: 'MaterialIcons'); // →
  static const back = IconData(0xf572, fontFamily: 'MaterialIcons'); // ←
  static const next = IconData(0xf63b, fontFamily: 'MaterialIcons'); // ›
  static const previous = IconData(0xf63a, fontFamily: 'MaterialIcons'); // ‹
}

/// Custom Sanadi icons from the design system (filled, 24dp grid).
enum SIcons { rehal, misbaha, students, prayerMat, moonPillow, waking, bars3, bars1, bars0, language }

class SIcon extends StatelessWidget {
  const SIcon(this.icon, {super.key, this.size = 28, this.color});

  final SIcons icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? context.t.primary;
    return SvgPicture.asset(
      'assets/icons/${icon.name}.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(c, BlendMode.srcIn),
    );
  }
}
