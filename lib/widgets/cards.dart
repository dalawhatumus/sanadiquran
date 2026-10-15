import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../backend/photos.dart';
import '../core/theme.dart';
import 'ui.dart';

// Cards, banners, avatars and other building blocks.

/// White rounded card.
class SCard extends StatelessWidget {
  const SCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.color,
    this.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? context.t.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: border == null ? BorderSide.none : BorderSide(color: border!, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// 48dp tinted square holding an icon.
class TintBox extends StatelessWidget {
  const TintBox({super.key, required this.child, this.size = 48, this.circle = false});

  final Widget child;
  final double size;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.t.tint,
        borderRadius: circle ? null : BorderRadius.circular(12),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
      ),
      child: IconTheme(
        data: IconThemeData(color: context.t.primary, size: size * 0.58),
        child: child,
      ),
    );
  }
}

/// Big illustration: an icon inside a tinted circle (no people or faces).
class Illustration extends StatelessWidget {
  const Illustration({super.key, required this.child, this.size = 128});

  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: context.t.tint, shape: BoxShape.circle),
      child: IconTheme(
        data: IconThemeData(color: context.t.primary, size: size * 0.45),
        child: child,
      ),
    );
  }
}

/// A profile picture: the person's own photo, one of the Sanadi avatars,
/// or initials in a circle (also while a photo loads, or if it can't).
class Avatar extends StatelessWidget {
  const Avatar(this.initials, {super.key, this.size = 56, this.ring = false, this.image});

  final String initials;
  final double size;
  final bool ring;

  /// Avatar id (e.g. "fs2") or photo ("photo:…"); null shows the initials.
  final String? image;

  static final _drawn = RegExp(r'^[fm][st][1-6]$');

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final border = ring ? Border.all(color: t.sage, width: 3) : null;
    final image = this.image;
    if (image != null && photoOwner(image) != null) {
      return Consumer(
        builder: (context, ref, initials) {
          final bytes = ref.watch(photoProvider(image)).value;
          if (bytes == null) return initials!;
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(shape: BoxShape.circle, border: border),
            child: ClipOval(
              child: Image.memory(
                bytes,
                width: size,
                height: size,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
                errorBuilder: (_, _, _) => initials!,
              ),
            ),
          );
        },
        child: Avatar(initials, size: size, ring: ring),
      );
    }
    if (image != null && _drawn.hasMatch(image)) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, border: border),
        child: ClipOval(
          child: SvgPicture.asset('assets/avatars/$image.svg', width: size, height: size),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: dark ? t.heading : t.deep, border: border),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
          color: dark ? t.onPrimary : Colors.white,
          height: 1,
        ),
      ),
    );
  }
}

/// A selectable card with a radio or checkbox mark on the end side.
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    required this.selected,
    required this.onTap,
    this.multi = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool selected;
  final bool multi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final mark = multi
        ? (selected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded)
        : (selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded);
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: !multi,
      child: Material(
        color: selected ? t.tint : t.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: selected ? t.primary : t.muted, width: selected ? 3 : 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 14)],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        WordSafeText(title, style: tt.titleMedium!.copyWith(color: t.heading)),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          WordSafeText(subtitle!, style: tt.bodySmall),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(mark, size: 32, color: selected ? t.primary : t.muted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Warning-tinted banner (no internet, missed calls). Never bright red.
class WarnBanner extends StatelessWidget {
  const WarnBanner({super.key, required this.icon, required this.text, this.title, this.action});

  final IconData icon;
  final String? title;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.warnTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.warn, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: t.warn, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null) Text(title!, style: tt.titleSmall),
                    Text(
                      text,
                      style: tt.bodyMedium!.copyWith(fontWeight: title == null ? FontWeight.w700 : FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    );
  }
}

/// Status line with a coloured dot ("3 teachers available now").
class StatusLine extends StatelessWidget {
  const StatusLine({super.key, required this.text, this.on = true});

  final String text;
  final bool on;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: on ? t.primary : Colors.transparent,
              border: Border.all(color: on ? t.primary : t.muted, width: 2.5),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: on ? t.primary : t.muted),
          ),
        ),
      ],
    );
  }
}

/// Centered icon, title and body for empty or "coming soon" states.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.body, this.action});

  final Widget icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Illustration(size: 112, child: icon),
            const SizedBox(height: 20),
            Text(title, style: tt.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              body,
              style: tt.bodyMedium!.copyWith(color: context.t.muted),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

/// Logo from the official SVG files only.
class Logo extends StatelessWidget {
  const Logo(this.file, {super.key, this.height = 80, this.label = 'Sanadi'});

  final String file;
  final double height;
  final String label;

  @override
  Widget build(BuildContext context) =>
      SvgPicture.asset('assets/logo/$file.svg', height: height, semanticsLabel: label);
}
