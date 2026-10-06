import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../core/strings.dart';
import '../core/theme.dart';

/// Custom Sanadi icons from the design system (filled, 24dp grid).
enum SIcons { rehal, misbaha, students, prayerMat, moonPillow, bars3, bars1, bars0, language }

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

enum ButtonKind { primary, warn, outline, tint }

/// Full-width 64dp button with an optional leading icon.
class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.label,
    this.icon,
    this.iconWidget,
    this.onPressed,
    this.kind = ButtonKind.primary,
    this.trailingIcon,
    this.busy = false,
    this.compact = false,
  });

  /// Keeps the label on one line, shrinking it if needed (for side-by-side
  /// buttons).
  final bool compact;

  final String label;
  final IconData? icon;
  final Widget? iconWidget;
  final IconData? trailingIcon;
  final VoidCallback? onPressed;
  final ButtonKind kind;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final enabled = onPressed != null && !busy;
    final (bg, fg, border) = switch (kind) {
      ButtonKind.primary => (t.primary, t.onPrimary, null),
      ButtonKind.warn => (t.warn, t.onWarn, null),
      ButtonKind.outline => (t.surface, t.text, t.text),
      ButtonKind.tint => (t.tint, t.heading, null),
    };
    final bgc = enabled || busy ? bg : t.disabledBg;
    final fgc = enabled || busy ? fg : t.disabledInk;
    final textStyle = Theme.of(context).textTheme.labelLarge!.copyWith(color: fgc);

    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: bgc,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: border == null ? BorderSide.none : BorderSide(color: enabled ? border : t.offLine, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kButtonHeight, minWidth: double.infinity),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: compact
                  ? FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[Icon(icon, size: 26, color: fgc), const SizedBox(width: 8)],
                          Text(label, style: textStyle, maxLines: 1),
                          if (trailingIcon != null) ...[
                            const SizedBox(width: 8),
                            Icon(trailingIcon, size: 26, color: fgc),
                          ],
                        ],
                      ),
                    )
                  : Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        if (busy)
                          SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: fgc))
                        else if (iconWidget != null)
                          IconTheme(
                            data: IconThemeData(color: fgc, size: 28),
                            child: iconWidget!,
                          )
                        else if (icon != null)
                          Icon(icon, size: 28, color: fgc),
                        Text(label, style: textStyle, textAlign: TextAlign.center),
                        if (trailingIcon != null) Icon(trailingIcon, size: 26, color: fgc),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

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

/// Initials in a circle.
class Avatar extends StatelessWidget {
  const Avatar(this.initials, {super.key, this.size = 56, this.ring = false});

  final String initials;
  final double size;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: dark ? t.heading : t.deep,
        border: ring ? Border.all(color: t.sage, width: 3) : null,
      ),
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

/// "Settings" pill with the user's initial; opens settings.
class SettingsChip extends StatelessWidget {
  const SettingsChip({super.key, required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final s = S.of(context);
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Material(
        color: t.surface,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => context.push('/settings'),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kMinTap),
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 16, end: 6, top: 4, bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.settings,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.text),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: t.primary, shape: BoxShape.circle),
                    child: Text(
                      initial,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: t.onPrimary, height: 1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Greeting on the start side, settings pill on the end side.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.top, required this.title, required this.initial});

  final String top;
  final String title;
  final String initial;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final big = MediaQuery.textScalerOf(context).scale(10) > 15;
    final greeting = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(top, style: tt.bodySmall!.copyWith(color: context.t.muted)),
        Text(title, style: tt.titleLarge),
      ],
    );
    if (big) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          greeting,
          const SizedBox(height: 8),
          SettingsChip(initial: initial),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: greeting),
        SettingsChip(initial: initial),
      ],
    );
  }
}

/// Outlined "← Back" pill. The arrow follows the reading direction.
class BackPill extends StatelessWidget {
  const BackPill({super.key, this.onTap, this.icon});

  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.6,
      child: Material(
        color: Colors.transparent,
        shape: StadiumBorder(side: BorderSide(color: t.text, width: 2)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap ?? () => context.canPop() ? context.pop() : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kMinTap),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon ?? Icons.arrow_back_rounded, size: 26, color: t.text),
                  const SizedBox(width: 8),
                  Text(
                    S.of(context).back,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: t.text),
                  ),
                ],
              ),
            ),
          ),
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
                        Text(title, style: tt.titleMedium!.copyWith(color: t.heading)),
                        if (subtitle != null) ...[const SizedBox(height: 4), Text(subtitle!, style: tt.bodySmall)],
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

/// Small rounded chip for multi-choice lists (countries, languages, times).
class PickChip extends StatelessWidget {
  const PickChip({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? t.primary : t.surface,
        shape: StadiumBorder(side: BorderSide(color: selected ? t.primary : t.muted, width: 2)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kMinTap),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected) ...[Icon(Icons.check_rounded, size: 22, color: t.onPrimary), const SizedBox(width: 6)],
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: selected ? t.onPrimary : t.text,
                      ),
                    ),
                  ),
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

/// A screen with a scrolling body and buttons pinned at the bottom.
class StepScaffold extends StatelessWidget {
  const StepScaffold({
    super.key,
    this.showBack = false,
    this.onBack,
    this.step,
    required this.content,
    this.bottom = const [],
    this.center = false,
    this.topTrailing,
  });

  final bool showBack;
  final VoidCallback? onBack;
  final String? step;
  final List<Widget> content;
  final List<Widget> bottom;
  final bool center;
  final Widget? topTrailing;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final hasTop = showBack || step != null || topTrailing != null;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasTop)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    if (showBack) ...[BackPill(onTap: onBack), const SizedBox(width: 12)],
                    Expanded(
                      child: step == null
                          ? const SizedBox()
                          : Text(
                              step!,
                              textAlign: TextAlign.end,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.muted),
                            ),
                    ),
                    if (topTrailing != null) Flexible(child: topTrailing!),
                  ],
                ),
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: center ? c.maxHeight - 32 : 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: center ? MainAxisAlignment.center : MainAxisAlignment.start,
                      children: content,
                    ),
                  ),
                ),
              ),
            ),
            if (bottom.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < bottom.length; i++) ...[if (i > 0) const SizedBox(height: 10), bottom[i]],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Plain text link-style button with a 56dp target.
class LinkButton extends StatelessWidget {
  const LinkButton({super.key, required this.label, required this.onPressed, this.icon, this.color});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.t.text;
    return TextButton.icon(
      onPressed: onPressed,
      icon: icon == null ? null : Icon(icon, size: 24, color: c),
      style: TextButton.styleFrom(minimumSize: const Size(kMinTap, kMinTap), foregroundColor: c),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: c,
          decoration: TextDecoration.underline,
          decorationColor: c,
        ),
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

void showSoon(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(S.of(context).comingSoon)));
}

void toast(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
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
