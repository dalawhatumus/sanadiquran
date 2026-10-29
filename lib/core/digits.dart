/// Western digits (0-9) for Arabic-Indic (٠-٩) and Persian (۰-۹) ones, so a
/// number typed on an Arabic keyboard reads the same.
String westernDigits(String s) => s.replaceAllMapped(RegExp('[٠-٩۰-۹]'), (m) {
  final c = m[0]!.codeUnitAt(0);
  return '${c >= 0x06F0 ? c - 0x06F0 : c - 0x0660}';
});
