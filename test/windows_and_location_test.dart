import 'package:test/test.dart';
import 'package:timezone_country/timezone_country.dart';

void main() {
  group('Windows timezones', () {
    test('resolves the worldwide default without a country', () {
      expect(
        TimezoneConvert.windowsToTimezone('Romance Standard Time'),
        'Europe/Paris',
      );
    });

    test('prefers the country-specific zone', () {
      expect(
        TimezoneConvert.windowsToTimezone(
          'Romance Standard Time',
          countryCode: 'BE',
        ),
        'Europe/Brussels',
      );
    });

    test('accepts alpha-3 country codes', () {
      expect(
        TimezoneConvert.windowsToTimezone(
          'Romance Standard Time',
          countryCode: 'BEL',
        ),
        TimezoneConvert.windowsToTimezone(
          'Romance Standard Time',
          countryCode: 'BE',
        ),
      );
    });

    test('falls back to the default for a country CLDR does not list', () {
      expect(
        TimezoneConvert.windowsToTimezone(
          'Tokyo Standard Time',
          countryCode: 'NO',
        ),
        TimezoneConvert.windowsToTimezone('Tokyo Standard Time'),
      );
    });

    test('returns null for an unknown Windows identifier', () {
      expect(
        TimezoneConvert.windowsToTimezone('Nowhere Standard Time'),
        isNull,
      );
    });

    test('maps back from IANA', () {
      expect(
        TimezoneConvert.timezoneToWindows('Asia/Tokyo'),
        'Tokyo Standard Time',
      );
    });

    test('maps back from a deprecated identifier', () {
      expect(TimezoneConvert.timezoneToWindows('Asia/Kolkata'), isNotNull);
      expect(
        TimezoneConvert.timezoneToWindows('Asia/Calcutta'),
        TimezoneConvert.timezoneToWindows('Asia/Kolkata'),
      );
    });

    test('returns null for a country code that is not a country', () {
      expect(
        TimezoneConvert.windowsToTimezone(
          'Romance Standard Time',
          countryCode: 'ZZ',
        ),
        isNull,
      );
    });

    test('keeps the country-specific zone CLDR names for a territory', () {
      expect(
        TimezoneConvert.windowsToTimezone(
          'W. Europe Standard Time',
          countryCode: 'NO',
        ),
        'Europe/Oslo',
      );
    });

    test('keeps the country-specific zone CLDR names by an old spelling', () {
      expect(
        TimezoneConvert.windowsToTimezone(
          'E. Africa Standard Time',
          countryCode: 'ER',
        ),
        'Africa/Asmara',
      );
      expect(
        TimezoneConvert.timezoneToWindows('Africa/Asmara'),
        'E. Africa Standard Time',
      );
    });

    test('never answers with a zone outside the country asked for', () {
      for (final MapEntry(value: byTerritory)
          in TimezoneConvert.windowsToTimezoneMap.entries) {
        for (final MapEntry(key: territory, value: timezone)
            in byTerritory.entries) {
          if (!TimezoneConvert.isValidCountryCode(territory)) continue;
          expect(
            TimezoneConvert.timezoneToCountryCodes(timezone),
            contains(territory),
            reason: '$territory is served by $timezone',
          );
        }
      }
    });

    test('covers every known timezone but the ones CLDR omits', () {
      final missing = [
        for (final timezone in TimezoneConvert.allTimezones)
          if (TimezoneConvert.timezoneToWindows(timezone) == null) timezone,
      ];
      expect(missing, ['Antarctica/Troll']);
    });

    test('keys are canonical identifiers or Etc zones', () {
      for (final timezone in TimezoneConvert.timezoneToWindowsMap.keys) {
        expect(
          TimezoneConvert.timezoneToCountryMap.containsKey(timezone) ||
              timezone.startsWith('Etc/'),
          isTrue,
          reason: '$timezone is neither canonical nor an Etc zone',
        );
      }
    });

    test('returns null when CLDR has no equivalent', () {
      expect(TimezoneConvert.timezoneToWindows('Invalid/Zone'), isNull);
    });

    test('the two directions agree', () {
      for (final MapEntry(key: timezone, value: windowsId)
          in TimezoneConvert.timezoneToWindowsMap.entries) {
        expect(
          TimezoneConvert.windowsToTimezoneMap[windowsId],
          isNotNull,
          reason: '$timezone maps to unknown $windowsId',
        );
      }
    });

    test('every worldwide default names a known timezone', () {
      for (final MapEntry(key: windowsId, value: byTerritory)
          in TimezoneConvert.windowsToTimezoneMap.entries) {
        expect(
          byTerritory.keys,
          contains('001'),
          reason: '$windowsId has no worldwide default',
        );
        for (final timezone in byTerritory.values) {
          expect(
            TimezoneConvert.isValidTimezone(timezone) ||
                timezone.startsWith('Etc/'),
            isTrue,
            reason: '$windowsId maps to unknown $timezone',
          );
        }
      }
    });
  });
}
