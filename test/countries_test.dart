import 'package:flutter_test/flutter_test.dart';
import 'package:sanadi/core/countries.dart';

/// The country list (nationality and calling codes) and phone numbers.
void main() {
  test('every country has a code, names and a calling code', () {
    expect(Country.all.length, greaterThan(200));
    final codes = <String>{};
    for (final c in Country.all) {
      expect(RegExp(r'^[A-Z]{2}$').hasMatch(c.code), isTrue, reason: c.code);
      expect(codes.add(c.code), isTrue, reason: 'duplicate ${c.code}');
      expect(c.en, isNotEmpty);
      expect(c.ar, isNotEmpty);
      expect(c.dial, greaterThan(0));
      expect(c.minDigits, lessThanOrEqualTo(c.maxDigits));
      expect(c.flag.runes.length, 2);
    }
  });

  test('Arabic names come from the standard (CLDR) list', () {
    expect(Country.byCode('SA')!.ar, 'المملكة العربية السعودية');
    expect(Country.byCode('EG')!.ar, 'مصر');
    expect(Country.byCode('AT')!.ar, 'النمسا');
    expect(Country.byCode('AU')!.ar, 'أستراليا');
    expect(Country.byCode('PS')!.en, 'Palestine');
    expect(Country.byCode('PS')!.ar, 'فلسطين');
    expect(Country.byCode('gb')!.dial, 44);
  });

  test('a typed number becomes an international one', () {
    final sa = Country.byCode('SA')!;
    expect(fullPhone(sa, '0512345678'), '+966512345678');
    expect(fullPhone(sa, '05 1234-5678'), '+966512345678');
    expect(fullPhone(sa, '٠٥١٢٣٤٥٦٧٨'), '+966512345678');
    expect(fullPhone(sa, '+966512345678'), '+966512345678');
    expect(fullPhone(sa, '00966512345678'), '+966512345678');
    expect(fullPhone(sa, '51234'), isNull); // too short
    expect(fullPhone(sa, '5123456789012'), isNull); // too long
    expect(fullPhone(sa, '+201000000000'), isNull); // another country's code
    expect(fullPhone(sa, 'abc'), isNull);
    expect(fullPhone(Country.byCode('GB')!, '07400 123456'), '+447400123456');
  });

  test('a saved number finds its country again', () {
    expect(Country.forPhone('+966512345678')!.code, 'SA');
    expect(Country.forPhone('+447400123456', prefer: 'GB')!.code, 'GB');
    // The nationality is preferred when the code fits.
    expect(Country.forPhone('+12025550123', prefer: 'CA')!.code, 'CA');
    expect(Country.forPhone(null, prefer: 'EG')!.code, 'EG');
    expect(localPart(Country.byCode('SA')!, '+966512345678'), '512345678');
    expect(localPart(Country.byCode('SA')!, '+201000000000'), '');
  });
}
