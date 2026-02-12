import 'package:test/test.dart';
import 'package:timezone_country/timezone_country.dart';

void main() {
  group('countryName', () {
    test('returns name for alpha-2 code', () {
      expect(TimezoneConvert.countryName('JP'), 'Japan');
      expect(TimezoneConvert.countryName('US'), 'United States');
      expect(TimezoneConvert.countryName('GB'), 'United Kingdom');
      expect(TimezoneConvert.countryName('DE'), 'Germany');
    });

    test('returns name for alpha-3 code', () {
      expect(TimezoneConvert.countryName('JPN'), 'Japan');
      expect(TimezoneConvert.countryName('USA'), 'United States');
      expect(TimezoneConvert.countryName('GBR'), 'United Kingdom');
    });

    test('is case-insensitive', () {
      expect(TimezoneConvert.countryName('jp'), 'Japan');
      expect(TimezoneConvert.countryName('usa'), 'United States');
    });

    test('returns null for invalid code', () {
      expect(TimezoneConvert.countryName('XX'), isNull);
      expect(TimezoneConvert.countryName('XXX'), isNull);
      expect(TimezoneConvert.countryName(''), isNull);
      expect(TimezoneConvert.countryName('ABCD'), isNull);
    });

    test('prefers common_name over official name', () {
      // Bolivia's official ISO name is "Bolivia, Plurinational State of"
      // but common_name should be "Bolivia"
      final name = TimezoneConvert.countryName('BO');
      expect(name, isNotNull);
      expect(name, isNot(contains(',')));
    });
  });

  group('countryFlag', () {
    test('returns flag emoji for alpha-2 code', () {
      // JP flag: Regional Indicator J + Regional Indicator P
      expect(
        TimezoneConvert.countryFlag('JP'),
        equals(String.fromCharCodes([0x1F1EF, 0x1F1F5])),
      );
      // US flag
      expect(
        TimezoneConvert.countryFlag('US'),
        equals(String.fromCharCodes([0x1F1FA, 0x1F1F8])),
      );
      // GB flag
      expect(
        TimezoneConvert.countryFlag('GB'),
        equals(String.fromCharCodes([0x1F1EC, 0x1F1E7])),
      );
    });

    test('returns flag emoji for alpha-3 code', () {
      expect(
        TimezoneConvert.countryFlag('JPN'),
        equals(String.fromCharCodes([0x1F1EF, 0x1F1F5])),
      );
      expect(
        TimezoneConvert.countryFlag('USA'),
        equals(String.fromCharCodes([0x1F1FA, 0x1F1F8])),
      );
    });

    test('is case-insensitive', () {
      expect(
        TimezoneConvert.countryFlag('jp'),
        TimezoneConvert.countryFlag('JP'),
      );
      expect(
        TimezoneConvert.countryFlag('usa'),
        TimezoneConvert.countryFlag('US'),
      );
    });

    test('returns null for invalid code', () {
      expect(TimezoneConvert.countryFlag('XX'), isNull);
      expect(TimezoneConvert.countryFlag('XXX'), isNull);
      expect(TimezoneConvert.countryFlag(''), isNull);
      expect(TimezoneConvert.countryFlag('ABCD'), isNull);
    });

    test('flag has exactly two code points', () {
      final flag = TimezoneConvert.countryFlag('JP')!;
      expect(flag.runes.length, 2);
    });

    test('all regional indicators are in valid range', () {
      final flag = TimezoneConvert.countryFlag('JP')!;
      for (final rune in flag.runes) {
        expect(rune, greaterThanOrEqualTo(0x1F1E6)); // Regional Indicator A
        expect(rune, lessThanOrEqualTo(0x1F1FF)); // Regional Indicator Z
      }
    });
  });

  group('countryNamesMap', () {
    test('is non-empty', () {
      expect(TimezoneConvert.countryNamesMap, isNotEmpty);
    });

    test('contains expected entries', () {
      expect(TimezoneConvert.countryNamesMap['JP'], 'Japan');
      expect(TimezoneConvert.countryNamesMap['US'], 'United States');
    });

    test('all keys are valid alpha-2 codes', () {
      for (final key in TimezoneConvert.countryNamesMap.keys) {
        expect(key.length, 2);
        expect(key, equals(key.toUpperCase()));
      }
    });
  });

  group('String extensions', () {
    test('toCountryName returns name for alpha-2', () {
      expect('JP'.toCountryName, 'Japan');
      expect('US'.toCountryName, 'United States');
    });

    test('toCountryName returns name for alpha-3', () {
      expect('JPN'.toCountryName, 'Japan');
      expect('USA'.toCountryName, 'United States');
    });

    test('toCountryName returns null for invalid', () {
      expect('XX'.toCountryName, isNull);
    });

    test('toFlag returns flag emoji for alpha-2', () {
      expect('JP'.toFlag, equals(String.fromCharCodes([0x1F1EF, 0x1F1F5])));
    });

    test('toFlag returns flag emoji for alpha-3', () {
      expect('JPN'.toFlag, equals(String.fromCharCodes([0x1F1EF, 0x1F1F5])));
    });

    test('toFlag returns null for invalid', () {
      expect('XX'.toFlag, isNull);
    });
  });
}
