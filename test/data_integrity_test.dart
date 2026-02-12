import 'package:test/test.dart';
import 'package:timezone_country/timezone_country.dart';

void main() {
  group('Data integrity', () {
    test(
      'timezoneToCountry primary matches timezoneToCountries first element',
      () {
        final tzToCountry = TimezoneConvert.timezoneToCountryMap;
        final tzToCountries = TimezoneConvert.timezoneToCountriesMap;

        for (final tz in tzToCountry.keys) {
          expect(
            tzToCountries[tz],
            isNotNull,
            reason:
                '$tz exists in timezoneToCountry but not timezoneToCountries',
          );
          expect(
            tzToCountry[tz],
            tzToCountries[tz]!.first,
            reason: 'Primary country mismatch for $tz',
          );
        }
      },
    );

    test('bidirectional: tz→cc implies cc→tz contains tz', () {
      final tzToCountry = TimezoneConvert.timezoneToCountryMap;
      final countryToTzs = TimezoneConvert.countryToTimezonesMap;

      for (final MapEntry(:key, :value) in tzToCountry.entries) {
        expect(
          countryToTzs[value],
          isNotNull,
          reason: 'Country $value from tz $key not in countryToTimezones',
        );
        expect(
          countryToTzs[value],
          contains(key),
          reason: 'countryToTimezones[$value] does not contain $key',
        );
      }
    });

    test('reverse bidirectional: cc→tzs all map back', () {
      final tzToCountries = TimezoneConvert.timezoneToCountriesMap;
      final countryToTzs = TimezoneConvert.countryToTimezonesMap;

      for (final MapEntry(:key, value: tzs) in countryToTzs.entries) {
        for (final tz in tzs) {
          expect(
            tzToCountries[tz],
            isNotNull,
            reason: 'Timezone $tz from country $key not in timezoneToCountries',
          );
          expect(
            tzToCountries[tz],
            contains(key),
            reason:
                'timezoneToCountries[$tz] does not contain country code $key',
          );
        }
      }
    });

    test('all country codes are exactly 2 uppercase ASCII letters', () {
      final regex = RegExp(r'^[A-Z]{2}$');
      for (final code in TimezoneConvert.countryToTimezonesMap.keys) {
        expect(
          regex.hasMatch(code),
          isTrue,
          reason: 'Invalid country code format: $code',
        );
      }
    });

    test('all timezone IDs contain a slash', () {
      for (final tz in TimezoneConvert.timezoneToCountryMap.keys) {
        expect(
          tz.contains('/'),
          isTrue,
          reason: 'Timezone ID missing slash: $tz',
        );
      }
    });

    test('no empty lists in countryToTimezones', () {
      for (final MapEntry(:key, :value)
          in TimezoneConvert.countryToTimezonesMap.entries) {
        expect(value, isNotEmpty, reason: 'Empty timezone list for $key');
      }
    });

    test('no empty lists in timezoneToCountries', () {
      for (final MapEntry(:key, :value)
          in TimezoneConvert.timezoneToCountriesMap.entries) {
        expect(value, isNotEmpty, reason: 'Empty country list for $key');
      }
    });

    test('no duplicate entries in country timezone lists', () {
      for (final MapEntry(:key, :value)
          in TimezoneConvert.countryToTimezonesMap.entries) {
        expect(
          value.toSet().length,
          value.length,
          reason: 'Duplicate timezones in country $key',
        );
      }
    });

    test('no duplicate entries in timezone country lists', () {
      for (final MapEntry(:key, :value)
          in TimezoneConvert.timezoneToCountriesMap.entries) {
        expect(
          value.toSet().length,
          value.length,
          reason: 'Duplicate countries in timezone $key',
        );
      }
    });

    test('alpha2ToAlpha3 and alpha3ToAlpha2 are inverse mappings', () {
      final a2ToA3 = TimezoneConvert.alpha2ToAlpha3Map;
      final a3ToA2 = TimezoneConvert.alpha3ToAlpha2Map;

      for (final MapEntry(:key, :value) in a2ToA3.entries) {
        expect(a3ToA2[value], key, reason: 'alpha3ToAlpha2[$value] != $key');
      }

      for (final MapEntry(:key, :value) in a3ToA2.entries) {
        expect(a2ToA3[value], key, reason: 'alpha2ToAlpha3[$value] != $key');
      }
    });

    test('alpha2ToAlpha3 and alpha3ToAlpha2 have same size', () {
      expect(
        TimezoneConvert.alpha2ToAlpha3Map.length,
        TimezoneConvert.alpha3ToAlpha2Map.length,
      );
    });

    test('all country codes in timezone maps have alpha-3 entry', () {
      final a2ToA3 = TimezoneConvert.alpha2ToAlpha3Map;
      final countryToTzs = TimezoneConvert.countryToTimezonesMap;

      for (final code in countryToTzs.keys) {
        expect(
          a2ToA3.containsKey(code),
          isTrue,
          reason: 'Country code $code has no alpha-3 mapping',
        );
      }
    });

    test('non-Etc legacy aliases resolve to known canonical timezones', () {
      final aliases = TimezoneConvert.legacyTimezoneAliases;
      final knownTzs = TimezoneConvert.timezoneToCountryMap;

      for (final MapEntry(:key, :value) in aliases.entries) {
        // Etc/* zones (UTC, GMT, etc.) are not in zone1970.tab since
        // they have no country association. Skip them.
        if (value.startsWith('Etc/')) continue;

        expect(
          knownTzs.containsKey(value),
          isTrue,
          reason: 'Legacy alias $key resolves to unknown timezone $value',
        );
      }
    });

    test('Etc zone targets match expected patterns', () {
      final etcPattern = RegExp(r'^Etc/(GMT([+-]\d+)?|UTC)$');
      final aliases = TimezoneConvert.legacyTimezoneAliases;
      for (final MapEntry(:key, :value) in aliases.entries) {
        if (value.startsWith('Etc/')) {
          expect(
            etcPattern.hasMatch(value),
            isTrue,
            reason: '$key resolves to unexpected Etc target: $value',
          );
        }
      }
    });

    test('allTimezones length matches timezoneToCountry map size', () {
      expect(
        TimezoneConvert.allTimezones.length,
        TimezoneConvert.timezoneToCountryMap.length,
      );
    });

    test('allCountryCodes length matches countryToTimezones map size', () {
      expect(
        TimezoneConvert.allCountryCodes.length,
        TimezoneConvert.countryToTimezonesMap.length,
      );
    });

    test('timezoneToCountry and timezoneToCountries have same keys', () {
      final keys1 = TimezoneConvert.timezoneToCountryMap.keys.toSet();
      final keys2 = TimezoneConvert.timezoneToCountriesMap.keys.toSet();
      expect(keys1, keys2);
    });
  });
}
