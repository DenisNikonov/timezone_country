import 'package:test/test.dart';
import 'package:timezone_country/timezone_country.dart';

void main() {
  group('TimezoneConvert core API', () {
    test('timezoneToCountryCode returns correct alpha-2 code', () {
      expect(TimezoneConvert.timezoneToCountryCode('Asia/Tokyo'), 'JP');
      expect(TimezoneConvert.timezoneToCountryCode('Europe/Paris'), 'FR');
      expect(TimezoneConvert.timezoneToCountryCode('America/New_York'), 'US');
    });

    test('timezoneToCountryCode returns null for unknown timezone', () {
      expect(TimezoneConvert.timezoneToCountryCode('Invalid/Zone'), isNull);
    });

    test('timezoneToCountryCode with alpha3 format', () {
      expect(
        TimezoneConvert.timezoneToCountryCode(
          'Asia/Tokyo',
          format: CountryCodeFormat.alpha3,
        ),
        'JPN',
      );
    });

    test('timezoneToCountryCodes returns list with primary country first', () {
      final codes = TimezoneConvert.timezoneToCountryCodes('Asia/Seoul');
      expect(codes, isNotNull);
      expect(codes, hasLength(1));
      expect(codes, contains('KR'));
    });

    test('timezoneToCountryCodes returns multi-country list', () {
      final codes = TimezoneConvert.timezoneToCountryCodes('Europe/Brussels');
      expect(codes, isNotNull);
      expect(codes!.length, greaterThan(1));
      expect(codes.first, 'BE');
    });

    test('timezoneToCountryCodes returns null for unknown timezone', () {
      expect(TimezoneConvert.timezoneToCountryCodes('Invalid/Zone'), isNull);
    });

    test('countryToTimezones returns timezones for valid country', () {
      final tzs = TimezoneConvert.countryToTimezones('JP');
      expect(tzs, isNotNull);
      expect(tzs, contains('Asia/Tokyo'));
    });

    test('countryToTimezones returns multiple timezones for US', () {
      final tzs = TimezoneConvert.countryToTimezones('US');
      expect(tzs, isNotNull);
      expect(tzs!.length, greaterThan(5));
      expect(tzs, contains('America/New_York'));
      expect(tzs, contains('America/Los_Angeles'));
    });

    test('countryToTimezones returns null for unknown code', () {
      expect(TimezoneConvert.countryToTimezones('XX'), isNull);
    });

    test('resolveTimezone resolves legacy name', () {
      expect(TimezoneConvert.resolveTimezone('US/Eastern'), 'America/New_York');
    });

    test('resolveTimezone returns canonical name unchanged', () {
      expect(TimezoneConvert.resolveTimezone('Asia/Tokyo'), 'Asia/Tokyo');
    });

    test('resolveTimezone returns unknown name unchanged', () {
      expect(TimezoneConvert.resolveTimezone('Invalid/Zone'), 'Invalid/Zone');
    });

    test('isValidTimezone returns true for known timezone', () {
      expect(TimezoneConvert.isValidTimezone('Asia/Tokyo'), isTrue);
      expect(TimezoneConvert.isValidTimezone('America/New_York'), isTrue);
    });

    test('isValidTimezone returns false for unknown timezone', () {
      expect(TimezoneConvert.isValidTimezone('Invalid/Zone'), isFalse);
      expect(TimezoneConvert.isValidTimezone(''), isFalse);
    });

    test('isValidCountryCode returns true for valid codes', () {
      expect(TimezoneConvert.isValidCountryCode('US'), isTrue);
      expect(TimezoneConvert.isValidCountryCode('JP'), isTrue);
      expect(TimezoneConvert.isValidCountryCode('USA'), isTrue);
    });

    test('isValidCountryCode returns false for invalid codes', () {
      expect(TimezoneConvert.isValidCountryCode('XX'), isFalse);
      expect(TimezoneConvert.isValidCountryCode(''), isFalse);
      expect(TimezoneConvert.isValidCountryCode('ABCD'), isFalse);
    });

    test('allTimezones is non-empty and sorted', () {
      expect(TimezoneConvert.allTimezones, isNotEmpty);
      final list = TimezoneConvert.allTimezones;
      for (var i = 1; i < list.length; i++) {
        expect(list[i].compareTo(list[i - 1]), greaterThanOrEqualTo(0));
      }
    });

    test('allCountryCodes is non-empty and sorted', () {
      expect(TimezoneConvert.allCountryCodes, isNotEmpty);
      final list = TimezoneConvert.allCountryCodes;
      for (var i = 1; i < list.length; i++) {
        expect(list[i].compareTo(list[i - 1]), greaterThanOrEqualTo(0));
      }
    });

    test('allCountryCodesAlpha3 is non-empty and sorted', () {
      expect(TimezoneConvert.allCountryCodesAlpha3, isNotEmpty);
      final list = TimezoneConvert.allCountryCodesAlpha3;
      for (var i = 1; i < list.length; i++) {
        expect(list[i].compareTo(list[i - 1]), greaterThanOrEqualTo(0));
      }
    });

    test('ianaVersion is accessible', () {
      // Value depends on generation — may be null or a version string.
      final version = TimezoneConvert.ianaVersion;
      expect(version, anyOf(isNull, isA<String>()));
    });
  });
}
