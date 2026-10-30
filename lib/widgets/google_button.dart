import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/theme.dart';

/// "Continue with Google", as Google asks it to look: the real four-colour
/// G on a white (or, in dark mode, near-black) pill with a thin outline. Made
/// larger than Google's minimum, for older eyes.
class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key, required this.label, this.onPressed, this.busy = false});

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Google's colours for its light and dark buttons.
    final fill = dark ? const Color(0xFF131314) : Colors.white;
    final ink = dark ? const Color(0xFFE3E3E3) : const Color(0xFF1F1F1F);
    final line = dark ? const Color(0xFF8E918F) : const Color(0xFF747775);
    return Semantics(
      button: true,
      child: Material(
        color: fill,
        shape: StadiumBorder(side: BorderSide(color: line)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: busy ? null : onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kMinTap + 12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  busy
                      ? SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 3, color: ink))
                      : SvgPicture.asset('assets/icons/google_g.svg', width: 26, height: 26),
                  const SizedBox(width: 14),
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: ink, height: 1.2),
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
