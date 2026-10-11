import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../core/theme.dart';

/// Asks a yes/no question. Returns true only if [confirmLabel] was tapped
/// (Cancel, Back or tapping outside all count as no). A [destructive]
/// action's button is shown in the warning colour.
Future<bool> confirm(
  BuildContext context, {
  String? title,
  String? body,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final s = S.of(context);
  final t = context.t;
  const big = TextStyle(fontSize: 18);
  final yes = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: title == null ? null : Text(title),
      content: body == null ? null : Text(body, style: big),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(s.cancel, style: big),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            confirmLabel,
            style: big.copyWith(fontWeight: FontWeight.w700, color: destructive ? t.warn : t.primary),
          ),
        ),
      ],
    ),
  );
  return yes == true;
}
