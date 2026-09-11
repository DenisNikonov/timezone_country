import 'package:test/test.dart';
import 'package:timezone_country/timezone_country.dart';

void main() {
  group('Country-specific link zones (zone.tab)', () {
    test('Nordic zones map to their own country, not Germany', () {
      expect(TimezoneConvert.timezoneToCountryCode('Europe/Oslo'), 'NO');
      expect(TimezoneConvert.timezoneToCountryCode('Europe/Copenhagen'), 'DK');
      expect(TimezoneConvert.timezoneToCountryCode('Europe/Stockholm'), 'SE');
      expect(TimezoneConvert.timezoneToCountryCode('Europe/Berlin'), 'DE');
    });

    test('other merged-away capital zones resolve to their country', () {
      expect(TimezoneConvert.timezoneToCountryCode('Europe/Bratislava'), 'SK');
      expect(TimezoneConvert.timezoneToCountryCode('Europe/Vatican'), 'VA');
      expect(TimezoneConvert.timezoneToCountryCode('Europe/Zagreb'), 'HR');
      expect(TimezoneConvert.timezoneToCountryCode('Europe/Ljubljana'), 'SI');
    });

    test('link zones are valid and enumerable', () {
      expect(TimezoneConvert.isValidTimezone('Europe/Oslo'), isTrue);
      expect(TimezoneConvert.allTimezones, contains('Europe/Oslo'));
      expect(TimezoneConvert.countryToTimezones('NO'), contains('Europe/Oslo'));
    });

    test('multi-country zones keep their full country list', () {
      expect(TimezoneConvert.timezoneToCountryCodes('Europe/Brussels'), [
        'BE',
        'LU',
        'NL',
      ]);
      expect(
        TimezoneConvert.timezoneToCountryCodes('Europe/Berlin'),
        containsAll(['DE', 'DK', 'NO']),
      );
    });
  });

  group('Deprecated identifiers resolve on lookup', () {
    test('timezoneToCountryCode resolves legacy aliases', () {
      expect(TimezoneConvert.timezoneToCountryCode('US/Eastern'), 'US');
      expect(TimezoneConvert.timezoneToCountryCode('Asia/Calcutta'), 'IN');
      expect(TimezoneConvert.timezoneToCountryCode('Japan'), 'JP');
      expect(
        TimezoneConvert.timezoneToCountryCode(
          'US/Eastern',
          format: CountryCodeFormat.alpha3,
        ),
        'USA',
      );
    });

    test('timezoneToCountryCodes resolves legacy aliases', () {
      expect(TimezoneConvert.timezoneToCountryCodes('Asia/Calcutta'), ['IN']);
    });

    test('isValidTimezone accepts legacy aliases', () {
      expect(TimezoneConvert.isValidTimezone('US/Eastern'), isTrue);
      expect(TimezoneConvert.isValidTimezone('Asia/Calcutta'), isTrue);
    });

    test('aliases of a country-specific zone stay in that country', () {
      expect(TimezoneConvert.resolveTimezone('Iceland'), 'Atlantic/Reykjavik');
      expect(TimezoneConvert.timezoneToCountryCode('Iceland'), 'IS');
      expect(TimezoneConvert.timezoneToCountryCode('Africa/Asmera'), 'ER');
      expect(TimezoneConvert.timezoneToCountryCode('America/Virgin'), 'VI');
      expect(TimezoneConvert.timezoneToCountryCode('Pacific/Ponape'), 'FM');
      expect(TimezoneConvert.timezoneToCountryCode('Pacific/Truk'), 'FM');
    });

    test('Etc aliases still have no country', () {
      expect(TimezoneConvert.timezoneToCountryCode('UTC'), isNull);
      expect(TimezoneConvert.timezoneToCountryCode('Etc/UTC'), isNull);
      expect(TimezoneConvert.isValidTimezone('UTC'), isFalse);
    });

    test('unknown identifiers still return null', () {
      expect(TimezoneConvert.timezoneToCountryCode('Totally/Unknown'), isNull);
      expect(TimezoneConvert.isValidTimezone('Totally/Unknown'), isFalse);
    });

    test('extensions resolve legacy aliases too', () {
      expect('US/Eastern'.toCountryCode, 'US');
      expect('Europe/Oslo'.toCountryCode, 'NO');
    });
  });
}
