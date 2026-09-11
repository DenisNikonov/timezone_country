import 'package:test/test.dart';
import 'package:timezone_country/timezone_country.dart';

void main() {
  group('CountryCode', () {
    test('parses alpha-2, alpha-3 and lower case to the same value', () {
      expect(CountryCode.tryParse('US'), CountryCode.tryParse('usa'));
      expect(CountryCode.tryParse('us')!.alpha2, 'US');
    });

    test('returns null for anything that is not ISO 3166-1', () {
      expect(CountryCode.tryParse('ZZ'), isNull);
      expect(CountryCode.tryParse('ZZZ'), isNull);
      expect(CountryCode.tryParse(''), isNull);
      expect(CountryCode.tryParse('UNITED STATES'), isNull);
    });

    test('exposes the country without null checks', () {
      final country = CountryCode.tryParse('JP')!;
      expect(country.alpha3, 'JPN');
      expect(country.numeric, '392');
      expect(country.name, 'Japan');
      expect(country.flag, '\u{1f1ef}\u{1f1f5}');
    });

    test('lists its timezones', () {
      expect(CountryCode.tryParse('JP')!.timezones.map((t) => t.id), [
        'Asia/Tokyo',
      ]);
    });

    test('gives an empty list for a country with no timezone', () {
      expect(CountryCode.tryParse('BV')!.timezones, isEmpty);
    });

    test('is a String at runtime', () {
      expect(CountryCode.tryParse('JP'), isA<String>());
    });
  });

  group('TimezoneId', () {
    test('canonicalises deprecated identifiers', () {
      expect(TimezoneId.tryParse('US/Eastern')!.id, 'America/New_York');
      expect(
        TimezoneId.tryParse('Asia/Calcutta'),
        TimezoneId.tryParse('Asia/Kolkata'),
      );
    });

    test('returns null for unknown identifiers and Etc zones', () {
      expect(TimezoneId.tryParse('Invalid/Zone'), isNull);
      expect(TimezoneId.tryParse('Etc/UTC'), isNull);
    });

    test('exposes the primary country', () {
      expect(TimezoneId.tryParse('Asia/Tokyo')!.country.name, 'Japan');
    });

    test('exposes every country a shared zone serves', () {
      expect(
        TimezoneId.tryParse('Europe/Brussels')!.countries.map((c) => c.alpha2),
        ['BE', 'LU', 'NL'],
      );
    });

    test('exposes coordinates, description and the Windows identifier', () {
      final zone = TimezoneId.tryParse('America/New_York')!;
      final (latitude, longitude) = zone.coordinates;
      expect(latitude, closeTo(40.71, 0.5));
      expect(longitude, closeTo(-74.01, 0.5));
      expect(zone.comment, isNotEmpty);
      expect(zone.windowsId, 'Eastern Standard Time');
    });

    test('agrees with the String API for every known timezone', () {
      for (final timezone in TimezoneConvert.allTimezones) {
        final zone = TimezoneId.tryParse(timezone)!;
        expect(zone.id, timezone, reason: '$timezone was rewritten');
        expect(
          zone.country.alpha2,
          TimezoneConvert.timezoneToCountryCode(timezone),
          reason: '$timezone got a different country',
        );
      }
    });

    test('round trips through CountryCode', () {
      final zone = TimezoneId.tryParse('Europe/Oslo')!;
      expect(zone.id, 'Europe/Oslo');
      expect(zone.country.alpha2, 'NO');
      expect(zone.country.timezones, contains(zone));
    });

    test('returned lists are unmodifiable', () {
      expect(
        () => TimezoneId.tryParse('Europe/Brussels')!.countries.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => CountryCode.tryParse('JP')!.timezones.clear(),
        throwsUnsupportedError,
      );
    });
  });
}
