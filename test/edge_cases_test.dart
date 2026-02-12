import 'package:test/test.dart';
import 'package:timezone_country/timezone_country.dart';

void main() {
  group('Edge cases', () {
    test('empty string for timezoneToCountryCode', () {
      expect(TimezoneConvert.timezoneToCountryCode(''), isNull);
    });

    test('empty string for countryToTimezones', () {
      expect(TimezoneConvert.countryToTimezones(''), isNull);
    });

    test('empty string for resolveTimezone returns unchanged', () {
      expect(TimezoneConvert.resolveTimezone(''), '');
    });

    test('empty string for isValidTimezone', () {
      expect(TimezoneConvert.isValidTimezone(''), isFalse);
    });

    test('empty string for isValidCountryCode', () {
      expect(TimezoneConvert.isValidCountryCode(''), isFalse);
    });

    test('whitespace-only strings return null/false', () {
      expect(TimezoneConvert.timezoneToCountryCode('  '), isNull);
      expect(TimezoneConvert.countryToTimezones('  '), isNull);
      expect(TimezoneConvert.isValidTimezone('  '), isFalse);
      expect(TimezoneConvert.isValidCountryCode('  '), isFalse);
    });

    test('very long strings return null/false', () {
      final longString = 'A' * 1000;
      expect(TimezoneConvert.timezoneToCountryCode(longString), isNull);
      expect(TimezoneConvert.countryToTimezones(longString), isNull);
      expect(TimezoneConvert.isValidTimezone(longString), isFalse);
      expect(TimezoneConvert.isValidCountryCode(longString), isFalse);
    });

    test('partial timezone name returns null', () {
      expect(TimezoneConvert.timezoneToCountryCode('Asia/'), isNull);
      expect(TimezoneConvert.timezoneToCountryCode('America'), isNull);
      expect(TimezoneConvert.timezoneToCountryCode('Europe/L'), isNull);
    });

    test('three-letter non-alpha-3 country code for country lookup', () {
      // 'ABC' is 3 letters but not a valid alpha-3 code
      expect(TimezoneConvert.countryToTimezones('ABC'), isNull);
    });

    test('four+ letter string for country lookup returns null', () {
      expect(TimezoneConvert.countryToTimezones('ABCD'), isNull);
      expect(TimezoneConvert.countryToTimezones('JAPAN'), isNull);
    });

    test('single letter for country lookup returns null', () {
      expect(TimezoneConvert.countryToTimezones('A'), isNull);
    });

    test('timezone IDs are case-sensitive', () {
      // IANA timezone IDs are case-sensitive
      expect(TimezoneConvert.timezoneToCountryCode('asia/tokyo'), isNull);
      expect(TimezoneConvert.timezoneToCountryCode('ASIA/TOKYO'), isNull);
      expect(TimezoneConvert.timezoneToCountryCode('Asia/Tokyo'), 'JP');
    });

    test('alpha2ToAlpha3 with empty string', () {
      expect(TimezoneConvert.alpha2ToAlpha3(''), isNull);
    });

    test('alpha3ToAlpha2 with empty string', () {
      expect(TimezoneConvert.alpha3ToAlpha2(''), isNull);
    });

    test('special characters return null', () {
      expect(TimezoneConvert.timezoneToCountryCode('Asia/Tokyo!'), isNull);
      expect(TimezoneConvert.countryToTimezones('U@'), isNull);
    });
  });
}
