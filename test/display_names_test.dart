import 'package:test/test.dart';
import 'package:timezone_country/timezone_country.dart';

void main() {
  group('isKnownTimezone', () {
    test('accepts a zone with a country', () {
      expect(TimezoneConvert.isKnownTimezone('America/Denver'), isTrue);
    });

    test('accepts a fixed-offset zone that has no country', () {
      expect(TimezoneConvert.isKnownTimezone('Etc/UTC'), isTrue);
      expect(TimezoneConvert.isKnownTimezone('Etc/GMT-1'), isTrue);
    });

    test('accepts a deprecated alias of a fixed-offset zone', () {
      expect(TimezoneConvert.isKnownTimezone('UTC'), isTrue);
      expect(TimezoneConvert.isKnownTimezone('Zulu'), isTrue);
      expect(TimezoneConvert.isKnownTimezone('GMT'), isTrue);
    });

    test('accepts the System V names, whichever form tzdb gives them', () {
      for (final zone in ['CST6CDT', 'EST5EDT', 'MST7MDT', 'PST8PDT']) {
        expect(TimezoneConvert.isKnownTimezone(zone), isTrue, reason: zone);
        expect(TimezoneConvert.isValidTimezone(zone), isFalse, reason: zone);
        expect(TimezoneConvert.allTimezones, isNot(contains(zone)));
      }
    });

    test('rejects an identifier the package does not carry', () {
      expect(TimezoneConvert.isKnownTimezone('Nowhere/Else'), isFalse);
    });
  });

  group('isValidTimezone', () {
    test('still answers only for zones that have a country', () {
      expect(TimezoneConvert.isValidTimezone('America/Denver'), isTrue);
      expect(TimezoneConvert.isValidTimezone('Etc/UTC'), isFalse);
      expect(TimezoneConvert.isValidTimezone('Etc/GMT-1'), isFalse);
    });
  });

  group('timezoneFixedOffset', () {
    test('reads the real offset, not the one the identifier spells', () {
      expect(
        TimezoneConvert.timezoneFixedOffset('Etc/GMT-1'),
        const Duration(hours: 1),
      );
      expect(
        TimezoneConvert.timezoneFixedOffset('Etc/GMT+5'),
        const Duration(hours: -5),
      );
      expect(TimezoneConvert.timezoneFixedOffset('Etc/UTC'), Duration.zero);
    });

    test('resolves a deprecated alias', () {
      expect(TimezoneConvert.timezoneFixedOffset('Zulu'), Duration.zero);
    });

    test('returns null for a zone whose offset changes with the date', () {
      expect(TimezoneConvert.timezoneFixedOffset('America/Denver'), isNull);
    });

    test('returns null for an unknown identifier', () {
      expect(TimezoneConvert.timezoneFixedOffset('Nowhere/Else'), isNull);
    });
  });

  group('fixedOffsetTimezones', () {
    test('lists the fixed-offset zones and nothing else', () {
      expect(TimezoneConvert.fixedOffsetTimezones, contains('Etc/UTC'));
      expect(
        TimezoneConvert.fixedOffsetTimezones,
        everyElement(startsWith('Etc/')),
      );
    });

    test('is disjoint from allTimezones', () {
      expect(
        TimezoneConvert.fixedOffsetTimezones.toSet().intersection(
          TimezoneConvert.allTimezones.toSet(),
        ),
        isEmpty,
      );
      expect(TimezoneConvert.allTimezones, isNot(contains('GMT')));
    });

    test('is sorted and unmodifiable', () {
      final sorted = [...TimezoneConvert.fixedOffsetTimezones]..sort();
      expect(TimezoneConvert.fixedOffsetTimezones, sorted);
      expect(
        () => TimezoneConvert.fixedOffsetTimezones.add('x'),
        throwsUnsupportedError,
      );
    });
  });

  group('timezoneCity', () {
    test('derives the city from the last path segment', () {
      expect(TimezoneConvert.timezoneCity('America/New_York'), 'New York');
      expect(
        TimezoneConvert.timezoneCity('America/Argentina/Buenos_Aires'),
        'Buenos Aires',
      );
    });

    test('prefers the CLDR override', () {
      expect(TimezoneConvert.timezoneCity('Atlantic/Faroe'), isNot('Faroe'));
    });

    test('resolves a deprecated alias before looking up the override', () {
      expect(
        TimezoneConvert.timezoneCity('Pacific/Enderbury'),
        allOf(isNotNull, TimezoneConvert.timezoneCity('Pacific/Kanton')),
      );
      expect(TimezoneConvert.timezoneCity('US/Mountain'), 'Denver');
    });

    test('returns null for a zone that names no place', () {
      expect(TimezoneConvert.timezoneCity('Etc/UTC'), isNull);
    });

    test('returns null for an unknown identifier', () {
      expect(TimezoneConvert.timezoneCity('Nowhere/Else'), isNull);
    });
  });

  group('metazone', () {
    test('returns the metazone the zone is in now', () {
      expect(TimezoneConvert.metazone('America/Denver'), 'America_Mountain');
    });

    test('resolves a deprecated alias', () {
      expect(TimezoneConvert.metazone('Asia/Calcutta'), 'India');
    });

    test('returns null for a zone CLDR has taken out of every metazone', () {
      expect(TimezoneConvert.metazone('Africa/Casablanca'), isNull);
    });

    test('returns null for an unknown identifier', () {
      expect(TimezoneConvert.metazone('Nowhere/Else'), isNull);
    });
  });

  group('display names', () {
    test('names a zone after its metazone', () {
      expect(
        TimezoneConvert.timezoneGenericName('America/Denver'),
        'Mountain Time',
      );
      expect(
        TimezoneConvert.timezoneStandardName('America/Denver'),
        'Mountain Standard Time',
      );
      expect(
        TimezoneConvert.timezoneDaylightName('America/Denver'),
        'Mountain Daylight Time',
      );
    });

    test('prefers the name CLDR gives the zone itself', () {
      expect(
        TimezoneConvert.timezoneDaylightName('Europe/London'),
        'British Summer Time',
      );
      expect(
        TimezoneConvert.timezoneDaylightName('Europe/Dublin'),
        'Irish Standard Time',
      );
      expect(
        TimezoneConvert.timezoneStandardName('Etc/UTC'),
        'Coordinated Universal Time',
      );
    });

    test(
      'resolves a deprecated alias to the name of the zone it stands for',
      () {
        expect(
          TimezoneConvert.timezoneGenericName('US/Mountain'),
          TimezoneConvert.timezoneGenericName('America/Denver'),
        );
        expect(
          TimezoneConvert.timezoneStandardName('Asia/Calcutta'),
          'India Standard Time',
        );
      },
    );

    test('returns null where the metazone has no name of that kind', () {
      expect(TimezoneConvert.timezoneGenericName('Europe/London'), isNull);
      expect(TimezoneConvert.timezoneDaylightName('Asia/Calcutta'), isNull);
    });

    test('returns null for a zone with no metazone', () {
      expect(TimezoneConvert.timezoneGenericName('Africa/Casablanca'), isNull);
      expect(TimezoneConvert.timezoneStandardName('Africa/Casablanca'), isNull);
      expect(TimezoneConvert.timezoneDaylightName('Africa/Casablanca'), isNull);
    });

    test('returns null for an unknown identifier', () {
      expect(TimezoneConvert.timezoneGenericName('Nowhere/Else'), isNull);
      expect(TimezoneConvert.timezoneStandardName('Nowhere/Else'), isNull);
      expect(TimezoneConvert.timezoneDaylightName('Nowhere/Else'), isNull);
    });
  });

  group('primaryTimezone', () {
    test('uses the zone CLDR designates', () {
      expect(TimezoneConvert.primaryTimezone('DE'), 'Europe/Berlin');
    });

    test('resolves a deprecated identifier CLDR still names', () {
      expect(TimezoneConvert.primaryTimezone('UA'), 'Europe/Kyiv');
    });

    test("uses a country's only zone", () {
      expect(TimezoneConvert.primaryTimezone('JP'), 'Asia/Tokyo');
    });

    test('accepts alpha-3 and either letter case', () {
      expect(TimezoneConvert.primaryTimezone('jpn'), 'Asia/Tokyo');
    });

    test('returns null for a many-zone country CLDR does not rank', () {
      expect(TimezoneConvert.primaryTimezone('US'), isNull);
    });

    test('returns null for an unknown country code', () {
      expect(TimezoneConvert.primaryTimezone('ZZ'), isNull);
    });
  });

  group('raw maps', () {
    test('resolve each zone to its name, leaving the unnamed ones out', () {
      expect(
        TimezoneConvert.timezoneCitiesMap.keys,
        TimezoneConvert.allTimezones.toSet(),
      );
      expect(
        TimezoneConvert.timezoneGenericNamesMap['America/Denver'],
        'Mountain Time',
      );
      expect(
        TimezoneConvert.timezoneStandardNamesMap['Etc/UTC'],
        'Coordinated Universal Time',
      );
      expect(
        TimezoneConvert.timezoneDaylightNamesMap['Europe/London'],
        'British Summer Time',
      );
      expect(
        TimezoneConvert.timezoneGenericNamesMap.containsKey(
          'Africa/Casablanca',
        ),
        isFalse,
      );
    });

    test('expose the metazone tables', () {
      expect(
        TimezoneConvert.timezoneToMetazoneMap['America/Denver'],
        'America_Mountain',
      );
      expect(
        TimezoneConvert.metazoneGenericNamesMap['America_Mountain'],
        'Mountain Time',
      );
      expect(
        TimezoneConvert.metazoneStandardNamesMap['America_Mountain'],
        'Mountain Standard Time',
      );
      expect(
        TimezoneConvert.metazoneDaylightNamesMap['America_Mountain'],
        'Mountain Daylight Time',
      );
    });

    test('expose the fixed offsets and the primary zones', () {
      expect(
        TimezoneConvert.timezoneFixedOffsetsMap['Etc/GMT+5'],
        const Duration(hours: -5),
      );
      expect(TimezoneConvert.primaryTimezonesMap['DE'], 'Europe/Berlin');
      expect(TimezoneConvert.primaryTimezonesMap.containsKey('US'), isFalse);
    });

    test('are unmodifiable', () {
      expect(
        () => TimezoneConvert.timezoneCitiesMap['x'] = 'y',
        throwsUnsupportedError,
      );
      expect(
        () => TimezoneConvert.timezoneGenericNamesMap['x'] = 'y',
        throwsUnsupportedError,
      );
      expect(
        () => TimezoneConvert.timezoneStandardNamesMap['x'] = 'y',
        throwsUnsupportedError,
      );
      expect(
        () => TimezoneConvert.timezoneDaylightNamesMap['x'] = 'y',
        throwsUnsupportedError,
      );
      expect(
        () => TimezoneConvert.timezoneFixedOffsetsMap['x'] = Duration.zero,
        throwsUnsupportedError,
      );
      expect(
        () => TimezoneConvert.timezoneToMetazoneMap['x'] = 'y',
        throwsUnsupportedError,
      );
      expect(
        () => TimezoneConvert.metazoneGenericNamesMap['x'] = 'y',
        throwsUnsupportedError,
      );
      expect(
        () => TimezoneConvert.metazoneStandardNamesMap['x'] = 'y',
        throwsUnsupportedError,
      );
      expect(
        () => TimezoneConvert.metazoneDaylightNamesMap['x'] = 'y',
        throwsUnsupportedError,
      );
      expect(
        () => TimezoneConvert.primaryTimezonesMap['x'] = 'y',
        throwsUnsupportedError,
      );
    });
  });

  group('TimezoneId', () {
    final zone = TimezoneId.tryParse('US/Mountain')!;

    test('carries the display names of the zone it resolved to', () {
      expect(zone.city, 'Denver');
      expect(zone.metazone, 'America_Mountain');
      expect(zone.genericName, 'Mountain Time');
      expect(zone.standardName, 'Mountain Standard Time');
      expect(zone.daylightName, 'Mountain Daylight Time');
    });

    test('leaves the names null where CLDR has none', () {
      final casablanca = TimezoneId.tryParse('Africa/Casablanca')!;
      expect(casablanca.city, 'Casablanca');
      expect(casablanca.metazone, isNull);
      expect(casablanca.genericName, isNull);
      expect(casablanca.standardName, isNull);
      expect(casablanca.daylightName, isNull);
    });
  });

  group('CountryCode.primaryTimezone', () {
    test('returns the designated zone', () {
      expect(CountryCode.tryParse('DE')!.primaryTimezone?.id, 'Europe/Berlin');
    });

    test('returns null for a many-zone country CLDR does not rank', () {
      expect(CountryCode.tryParse('US')!.primaryTimezone, isNull);
    });
  });
}
