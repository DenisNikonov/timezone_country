import 'package:test/test.dart';
import 'package:timezone_country/timezone_country.dart';

void main() {
  group('Alpha-3 support', () {
    group('timezoneToCountryCode with alpha3', () {
      test('returns correct alpha-3 code', () {
        expect(
          TimezoneConvert.timezoneToCountryCode(
            'Asia/Tokyo',
            format: CountryCodeFormat.alpha3,
          ),
          'JPN',
        );
        expect(
          TimezoneConvert.timezoneToCountryCode(
            'America/New_York',
            format: CountryCodeFormat.alpha3,
          ),
          'USA',
        );
        expect(
          TimezoneConvert.timezoneToCountryCode(
            'Europe/London',
            format: CountryCodeFormat.alpha3,
          ),
          'GBR',
        );
      });

      test('returns null for unknown timezone', () {
        expect(
          TimezoneConvert.timezoneToCountryCode(
            'Invalid/Zone',
            format: CountryCodeFormat.alpha3,
          ),
          isNull,
        );
      });
    });

    group('timezoneToCountryCodes with alpha3', () {
      test('returns all codes in alpha-3 format', () {
        final codes = TimezoneConvert.timezoneToCountryCodes(
          'Europe/Brussels',
          format: CountryCodeFormat.alpha3,
        );
        expect(codes, isNotNull);
        expect(codes, contains('BEL'));
        expect(codes, contains('LUX'));
        expect(codes, contains('NLD'));
      });
    });

    group('countryToTimezones with alpha-3 input', () {
      test('alpha-3 input returns same result as alpha-2', () {
        expect(
          TimezoneConvert.countryToTimezones('USA'),
          TimezoneConvert.countryToTimezones('US'),
        );
        expect(
          TimezoneConvert.countryToTimezones('JPN'),
          TimezoneConvert.countryToTimezones('JP'),
        );
        expect(
          TimezoneConvert.countryToTimezones('DEU'),
          TimezoneConvert.countryToTimezones('DE'),
        );
      });

      test('alpha-3 input is case-insensitive', () {
        expect(
          TimezoneConvert.countryToTimezones('usa'),
          TimezoneConvert.countryToTimezones('US'),
        );
        expect(
          TimezoneConvert.countryToTimezones('jpn'),
          TimezoneConvert.countryToTimezones('JP'),
        );
      });

      test('unknown alpha-3 code returns null', () {
        expect(TimezoneConvert.countryToTimezones('ZZZ'), isNull);
        expect(TimezoneConvert.countryToTimezones('XXX'), isNull);
      });
    });

    group('alpha2ToAlpha3', () {
      test('converts common codes correctly', () {
        expect(TimezoneConvert.alpha2ToAlpha3('US'), 'USA');
        expect(TimezoneConvert.alpha2ToAlpha3('JP'), 'JPN');
        expect(TimezoneConvert.alpha2ToAlpha3('GB'), 'GBR');
        expect(TimezoneConvert.alpha2ToAlpha3('DE'), 'DEU');
        expect(TimezoneConvert.alpha2ToAlpha3('FR'), 'FRA');
        expect(TimezoneConvert.alpha2ToAlpha3('CN'), 'CHN');
        expect(TimezoneConvert.alpha2ToAlpha3('RU'), 'RUS');
        expect(TimezoneConvert.alpha2ToAlpha3('IN'), 'IND');
      });

      test('is case-insensitive', () {
        expect(TimezoneConvert.alpha2ToAlpha3('us'), 'USA');
        expect(TimezoneConvert.alpha2ToAlpha3('jp'), 'JPN');
      });

      test('returns null for unknown code', () {
        expect(TimezoneConvert.alpha2ToAlpha3('XX'), isNull);
        expect(TimezoneConvert.alpha2ToAlpha3('ZZ'), isNull);
      });
    });

    group('alpha3ToAlpha2', () {
      test('converts common codes correctly', () {
        expect(TimezoneConvert.alpha3ToAlpha2('USA'), 'US');
        expect(TimezoneConvert.alpha3ToAlpha2('JPN'), 'JP');
        expect(TimezoneConvert.alpha3ToAlpha2('GBR'), 'GB');
        expect(TimezoneConvert.alpha3ToAlpha2('DEU'), 'DE');
        expect(TimezoneConvert.alpha3ToAlpha2('FRA'), 'FR');
      });

      test('is case-insensitive', () {
        expect(TimezoneConvert.alpha3ToAlpha2('usa'), 'US');
        expect(TimezoneConvert.alpha3ToAlpha2('jpn'), 'JP');
      });

      test('returns null for unknown code', () {
        expect(TimezoneConvert.alpha3ToAlpha2('XXX'), isNull);
        expect(TimezoneConvert.alpha3ToAlpha2('ZZZ'), isNull);
      });
    });

    group('isValidCountryCode with alpha-3', () {
      test('accepts valid alpha-3 codes', () {
        expect(TimezoneConvert.isValidCountryCode('USA'), isTrue);
        expect(TimezoneConvert.isValidCountryCode('JPN'), isTrue);
        expect(TimezoneConvert.isValidCountryCode('GBR'), isTrue);
      });

      test('rejects invalid alpha-3 codes', () {
        expect(TimezoneConvert.isValidCountryCode('XXX'), isFalse);
        expect(TimezoneConvert.isValidCountryCode('ZZZ'), isFalse);
      });
    });

    group('allCountryCodesAlpha3', () {
      test('has same length as allCountryCodes alpha2-to-alpha3 map', () {
        expect(
          TimezoneConvert.allCountryCodesAlpha3.length,
          TimezoneConvert.alpha2ToAlpha3Map.length,
        );
      });

      test('contains known alpha-3 codes', () {
        expect(TimezoneConvert.allCountryCodesAlpha3, contains('USA'));
        expect(TimezoneConvert.allCountryCodesAlpha3, contains('JPN'));
        expect(TimezoneConvert.allCountryCodesAlpha3, contains('GBR'));
      });
    });
  });
}
