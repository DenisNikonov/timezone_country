import 'package:test/test.dart';
import 'package:timezone_country/timezone_country.dart';

void main() {
  group('Numeric country codes', () {
    test('alpha-2 and alpha-3 map to the numeric code', () {
      expect(TimezoneConvert.countryNumericCode('JP'), '392');
      expect(TimezoneConvert.countryNumericCode('JPN'), '392');
      expect(TimezoneConvert.countryNumericCode('us'), '840');
      expect(TimezoneConvert.countryNumericCode('AF'), '004');
    });

    test('numeric maps back, with or without leading zeros', () {
      expect(TimezoneConvert.numericToCountryCode('392'), 'JP');
      expect(TimezoneConvert.numericToCountryCode('004'), 'AF');
      expect(TimezoneConvert.numericToCountryCode('4'), 'AF');
      expect(
        TimezoneConvert.numericToCountryCode(
          '392',
          format: CountryCodeFormat.alpha3,
        ),
        'JPN',
      );
    });

    test('unknown input returns null', () {
      expect(TimezoneConvert.countryNumericCode('XX'), isNull);
      expect(TimezoneConvert.countryNumericCode('LONG'), isNull);
      expect(TimezoneConvert.numericToCountryCode('999'), isNull);
      expect(TimezoneConvert.numericToCountryCode('abc'), isNull);
    });

    test('numeric maps are inverse and cover every country', () {
      final a2ToNum = TimezoneConvert.alpha2ToNumericMap;
      final numToA2 = TimezoneConvert.numericToAlpha2Map;
      expect(a2ToNum.length, numToA2.length);
      expect(a2ToNum.length, TimezoneConvert.alpha2ToAlpha3Map.length);
      for (final MapEntry(:key, :value) in a2ToNum.entries) {
        expect(numToA2[value], key);
        expect(RegExp(r'^\d{3}$').hasMatch(value), isTrue, reason: value);
      }
    });

    test('extensions', () {
      expect('JP'.toNumericCode, '392');
      expect('392'.fromNumericCode, 'JP');
    });
  });

  group('Flag emoji round trip', () {
    test('flag maps back to its country code', () {
      final flag = TimezoneConvert.countryFlag('JP')!;
      expect(TimezoneConvert.countryCodeFromFlag(flag), 'JP');
      expect(
        TimezoneConvert.countryCodeFromFlag(
          flag,
          format: CountryCodeFormat.alpha3,
        ),
        'JPN',
      );
    });

    test('round trip holds for every country code', () {
      for (final code in TimezoneConvert.alpha2ToAlpha3Map.keys) {
        final flag = TimezoneConvert.countryFlag(code);
        expect(flag, isNotNull, reason: code);
        expect(TimezoneConvert.countryCodeFromFlag(flag!), code);
      }
    });

    test('non-flag input returns null', () {
      expect(TimezoneConvert.countryCodeFromFlag(''), isNull);
      expect(TimezoneConvert.countryCodeFromFlag('JP'), isNull);
      expect(TimezoneConvert.countryCodeFromFlag('\u{1f1ef}'), isNull);
      // Regional indicators that spell no assigned country (ZZ).
      expect(TimezoneConvert.countryCodeFromFlag('\u{1f1ff}\u{1f1ff}'), isNull);
    });

    test('extension', () {
      expect('\u{1f1ef}\u{1f1f5}'.fromFlag, 'JP');
    });
  });

  group('Country code validity', () {
    test('ISO-only codes have no timezone but are known', () {
      final isoOnly = TimezoneConvert.alpha2ToAlpha3Map.keys.where(
        (c) => !TimezoneConvert.countryToTimezonesMap.containsKey(c),
      );
      expect(isoOnly, isNotEmpty);
      for (final code in isoOnly) {
        expect(TimezoneConvert.isValidCountryCode(code), isFalse, reason: code);
        expect(TimezoneConvert.isKnownCountryCode(code), isTrue, reason: code);
        expect(TimezoneConvert.countryName(code), isNotNull, reason: code);
      }
    });

    test('ordinary codes are both known and valid', () {
      expect(TimezoneConvert.isValidCountryCode('JP'), isTrue);
      expect(TimezoneConvert.isKnownCountryCode('JPN'), isTrue);
      expect(TimezoneConvert.isKnownCountryCode('XX'), isFalse);
      expect(TimezoneConvert.isKnownCountryCode(''), isFalse);
    });
  });
}
