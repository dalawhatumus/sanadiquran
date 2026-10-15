part 'countries_data.dart';

/// A country: for nationality, and the calling code of a phone number.
class Country {
  const Country(this.code, this.dial, this.en, this.ar, this.minDigits, this.maxDigits, this.example);

  /// ISO 3166 two-letter code, e.g. "SA".
  final String code;

  /// International calling code, e.g. 966.
  final int dial;
  final String en;
  final String ar;

  /// How many digits a number has here, without the calling code or a
  /// leading 0.
  final int minDigits;
  final int maxDigits;

  /// A sample mobile number (without the calling code), shown as a hint.
  final String example;

  String name(bool arabic) => arabic ? ar : en;

  /// The flag, drawn by the phone from the two letters.
  String get flag => String.fromCharCodes(code.codeUnits.map((c) => 0x1F1E6 + c - 0x41));

  static const all = _data;

  static Country? byCode(String? code) => code == null ? null : _byCode[code.toUpperCase()];
  static final _byCode = {for (final c in _data) c.code: c};

  /// The country a saved number belongs to: [prefer] if its calling code
  /// fits, otherwise the one with the longest matching code.
  static Country? forPhone(String? phone, {String? prefer}) {
    if (phone == null || !phone.startsWith('+')) return byCode(prefer);
    final p = byCode(prefer);
    if (p != null && phone.startsWith('+${p.dial}')) return p;
    Country? best;
    for (final c in _data) {
      if (phone.startsWith('+${c.dial}') && (best == null || '${c.dial}'.length > '${best.dial}'.length)) best = c;
    }
    return best;
  }

  /// All countries in alphabetical order for the language.
  static List<Country> sorted(bool arabic) {
    // In Arabic, "ال" at the start is ignored and the forms of alef sort
    // together, as in printed lists.
    String key(Country c) => arabic ? c.ar.replaceFirst(RegExp('^ال'), '').replaceAll(RegExp('[أإآ]'), 'ا') : c.en;
    return [...all]..sort((a, b) => key(a).compareTo(key(b)));
  }
}

/// A phone number in international form: "+" and up to 15 digits.
final phonePattern = RegExp(r'^\+[1-9][0-9]{6,14}$');

/// Builds the international number from the digits someone typed for
/// [country] (spaces, dashes and a leading 0 are dropped). Returns null
/// if it can't be a number there.
String? fullPhone(Country country, String typed) {
  var digits = typed.replaceAll(RegExp(r'[\s\-().]'), '');
  // Arabic-Indic and Persian digits count too.
  digits = digits.replaceAllMapped(RegExp('[٠-٩۰-۹]'), (m) {
    final c = m[0]!.codeUnitAt(0);
    return '${c >= 0x06F0 ? c - 0x06F0 : c - 0x0660}';
  });
  if (digits.startsWith('+')) {
    // Typed with the calling code already.
    final full = digits;
    return phonePattern.hasMatch(full) && full.startsWith('+${country.dial}') ? full : null;
  }
  if (digits.startsWith('00${country.dial}')) digits = digits.substring(2 + '${country.dial}'.length);
  digits = digits.replaceFirst(RegExp(r'^0+'), '');
  if (!RegExp(r'^[0-9]+$').hasMatch(digits)) return null;
  if (digits.length < country.minDigits || digits.length > country.maxDigits) return null;
  final full = '+${country.dial}$digits';
  return phonePattern.hasMatch(full) ? full : null;
}

/// The digits after the calling code, for editing a saved number.
String localPart(Country country, String? phone) {
  final prefix = '+${country.dial}';
  if (phone == null || !phone.startsWith(prefix)) return '';
  return phone.substring(prefix.length);
}
