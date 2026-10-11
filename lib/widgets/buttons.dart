import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/strings.dart';
import '../core/theme.dart';
import 'ui.dart';

// Buttons, chips and links: large, easy targets for elderly users.

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
                        textDirection: icon == Arrows.back || trailingIcon == Arrows.forward ? TextDirection.ltr : null,
                        children: [
                          if (iconWidget != null) ...[
                            IconTheme(
                              data: IconThemeData(color: fgc, size: 26),
                              child: iconWidget!,
                            ),
                            const SizedBox(width: 8),
                          ] else if (icon != null) ...[
                            Icon(icon, size: 26, color: fgc),
                            const SizedBox(width: 8),
                          ],
                          Text(label, style: textStyle, maxLines: 1),
                          if (trailingIcon != null) ...[
                            const SizedBox(width: 8),
                            Icon(trailingIcon, size: 26, color: fgc),
                          ],
                        ],
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, c) {
                        final hasIcon = busy || iconWidget != null || icon != null;
                        final iconsW = (hasIcon ? 38.0 : 0) + (trailingIcon != null ? 36.0 : 0);
                        final room = c.maxWidth - iconsW;
                        final longest = longestWordWidth(context, label, textStyle);
                        // No word may break across lines. If the longest word
                        // doesn't fit even slightly smaller, show only the icon.
                        final iconOnly = hasIcon && longest * 0.85 > room;
                        final leading = busy
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 3, color: fgc),
                              )
                            : iconWidget != null
                            ? IconTheme(
                                data: IconThemeData(color: fgc, size: 28),
                                child: iconWidget!,
                              )
                            : icon != null
                            ? Icon(icon, size: 28, color: fgc)
                            : null;
                        if (iconOnly) {
                          return Center(
                            child: Tooltip(message: label, child: leading ?? const SizedBox()),
                          );
                        }
                        // A back arrow sits on the left and a proceed arrow on the
                        // right, whatever the language.
                        final arrows = icon == Arrows.back || trailingIcon == Arrows.forward;
                        return Center(
                          // Icon and label sit on one centred row; a long label
                          // wraps between words, never inside one.
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            textDirection: arrows ? TextDirection.ltr : null,
                            children: [
                              ?leading,
                              if (hasIcon) const SizedBox(width: 10),
                              Flexible(
                                child: WordSafeText(label, style: textStyle, textAlign: TextAlign.center),
                              ),
                              if (trailingIcon != null) ...[
                                const SizedBox(width: 10),
                                Icon(trailingIcon, size: 26, color: fgc),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
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
                textDirection: TextDirection.ltr,
                children: [
                  Icon(icon ?? Arrows.back, size: 26, color: t.text),
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
                    child: WordSafeText(
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
