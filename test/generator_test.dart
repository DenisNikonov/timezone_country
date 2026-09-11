import 'package:test/test.dart';

import '../tool/parse_source_data.dart';

const _isoJson = '''
{"3166-1": [
  {"alpha_2": "NO", "alpha_3": "NOR", "numeric": "578", "name": "Norway"},
  {"alpha_2": "BO", "alpha_3": "BOL", "numeric": "068",
   "name": "Bolivia, Plurinational State of", "common_name": "Bolivia"},
  {"alpha_2": "CD", "alpha_3": "COD", "numeric": "180",
   "name": "Congo, The Democratic Republic of the"},
  {"alpha_2": "BQ", "alpha_3": "BES", "numeric": "535",
   "name": "Bonaire, Sint Eustatius and Saba"},
  {"alpha_2": "XX", "alpha_3": "XXX", "numeric": "999",
   "name": "Newland, Republic of"}
]}''';

// Trailing description column deliberately absent from one row: most
// single-zone countries have none.
const _zone1970Tab = '''
#code\tcoordinates\tTZ\tcomments
BE,LU,NL\t+5050+00420\tEurope/Brussels
DE,NO,SJ\t+5230+01322\tEurope/Berlin
US\t+404251-0740023\tAmerica/New_York\tEastern (most areas)
''';

const _zoneTab = '''
# comment line
NO\t+5955+01045\tEurope/Oslo
US\t+404251-0740023\tAmerica/New_York\tEastern (most areas)
''';

const _backward = '''
# Comment
Link\tAmerica/New_York\tUS/Eastern
Link\tAsia/Kolkata\tAsia/Calcutta
Link\tEurope/Berlin\tEurope/Oslo
Link\tEurope/Berlin\tNorway\t#= Europe/Oslo
Link\tAmerica/New_York\tUS/Capital\t#= America/Washington
Zone\tCST6CDT\t-6:00\tUS\tC%sT
''';

const _windowsZones = '''
<supplementalData>
  <mapZone other="Romance Standard Time" territory="001" type="Europe/Paris"/>
  <mapZone other="Romance Standard Time" territory="BE" type="Europe/Brussels"/>
  <mapZone other="W. Europe Standard Time" territory="NO" type="Europe/Oslo Arctic/Longyearbyen"/>
  <mapZone other="India Standard Time" territory="001" type="Asia/Calcutta"/>
</supplementalData>''';

void main() {
  final known = parseZoneTables([
    _zone1970Tab,
    _zoneTab,
  ]).timezoneToCountry.keys.toSet();

  group('parseIso3166', () {
    final iso = parseIso3166(_isoJson);

    test('maps alpha-2 to alpha-3 and numeric', () {
      expect(iso.alpha2ToAlpha3['NO'], 'NOR');
      expect(iso.alpha2ToNumeric['NO'], '578');
    });

    test('prefers common_name over the long form', () {
      expect(iso.countryNames['BO'], 'Bolivia');
    });

    test('applies the inverted-name overrides', () {
      expect(iso.countryNames['CD'], 'Democratic Republic of the Congo');
    });

    test('leaves list-form names alone without warning', () {
      expect(iso.countryNames['BQ'], 'Bonaire, Sint Eustatius and Saba');
      expect(iso.warnings.any((w) => w.startsWith('BQ')), isFalse);
    });

    test('warns about an unknown inverted name', () {
      expect(iso.warnings, contains(contains('Newland, Republic of')));
    });
  });

  group('parseZoneTables', () {
    final zones = parseZoneTables([_zone1970Tab, _zoneTab]);

    test('skips comments and the header', () {
      expect(zones.timezoneToCountry.containsKey('TZ'), isFalse);
    });

    test('keeps the multi-country list from the first table', () {
      expect(zones.timezoneToCountries['Europe/Brussels'], ['BE', 'LU', 'NL']);
      expect(zones.timezoneToCountry['Europe/Brussels'], 'BE');
    });

    test('adds country-specific zones from the second table', () {
      expect(zones.timezoneToCountry['Europe/Oslo'], 'NO');
    });

    test("puts a country's own zone before a zone it merely shares", () {
      expect(zones.countryToTimezones['NO']!.first, 'Europe/Oslo');
      expect(zones.countryToTimezones['NO'], contains('Europe/Berlin'));
    });

    test('lists a country that appears only as a secondary code', () {
      expect(zones.countryToTimezones['LU'], ['Europe/Brussels']);
    });

    test('captures the description column when present', () {
      expect(zones.comments['America/New_York'], 'Eastern (most areas)');
      expect(zones.comments.containsKey('Europe/Oslo'), isFalse);
    });

    test('captures coordinates', () {
      final (latitude, longitude) = zones.coordinates['Europe/Brussels']!;
      expect(latitude, closeTo(50.833, 0.001));
      expect(longitude, closeTo(4.333, 0.001));
    });
  });

  group('parseIso6709', () {
    test('parses the minutes form', () {
      final (latitude, longitude) = parseIso6709('+5050+00420')!;
      expect(latitude, closeTo(50.833, 0.001));
      expect(longitude, closeTo(4.333, 0.001));
    });

    test('parses the seconds form', () {
      final (latitude, longitude) = parseIso6709('+404251-0740023')!;
      expect(latitude, closeTo(40.714, 0.001));
      expect(longitude, closeTo(-74.006, 0.001));
    });

    test('keeps the sign of a southern or western point', () {
      final (latitude, longitude) = parseIso6709('-3352+01825')!;
      expect(latitude, lessThan(0));
      expect(longitude, greaterThan(0));
    });

    test('keeps the sign when the degrees field is zero', () {
      final (latitude, _) = parseIso6709('-0002+10920')!;
      expect(latitude, lessThan(0));
    });

    test('returns null for anything else', () {
      expect(parseIso6709('nonsense'), isNull);
      expect(parseIso6709(''), isNull);
    });
  });

  group('parseBackward', () {
    final legacy = parseBackward(_backward, known);

    test('maps alias to canonical identifier', () {
      expect(legacy['US/Eastern'], 'America/New_York');
      expect(legacy['Asia/Calcutta'], 'Asia/Kolkata');
    });

    test('ignores Zone entries, which are real zones and not aliases', () {
      expect(legacy.containsKey('CST6CDT'), isFalse);
    });

    test('prefers the zone-table zone a #= comment names', () {
      expect(legacy['Norway'], 'Europe/Oslo');
    });

    test('keeps the link target when the #= zone is not in the tables', () {
      expect(legacy['US/Capital'], 'America/New_York');
    });
  });

  group('parseWindowsZones', () {
    final windows = parseWindowsZones(
      _windowsZones,
      parseBackward(_backward, known),
      known,
    );

    test('does not rename a zone-table zone that backward also links', () {
      expect(
        windows.windowsToTimezone['W. Europe Standard Time']!['NO'],
        'Europe/Oslo',
      );
      expect(windows.timezoneToWindows.containsKey('Europe/Oslo'), isTrue);
    });

    test('renames zones CLDR still lists under a deprecated identifier', () {
      expect(
        windows.windowsToTimezone['India Standard Time']!['001'],
        'Asia/Kolkata',
      );
      expect(windows.timezoneToWindows['Asia/Calcutta'], isNull);
    });

    test('keys by Windows identifier, then territory', () {
      expect(windows.windowsToTimezone['Romance Standard Time'], {
        '001': 'Europe/Paris',
        'BE': 'Europe/Brussels',
      });
    });

    test('takes the first zone of a multi-zone territory', () {
      expect(
        windows.windowsToTimezone['W. Europe Standard Time']!['NO'],
        'Europe/Oslo',
      );
    });

    test('reverses every zone of a multi-zone territory', () {
      expect(
        windows.timezoneToWindows['Arctic/Longyearbyen'],
        'W. Europe Standard Time',
      );
    });
  });

  group('validate', () {
    SourceData parse({
      String zone1970Tab = _zone1970Tab,
      String zoneTab = _zoneTab,
      String backward = _backward,
      String windowsZonesXml = _windowsZones,
    }) => parseSources(
      zone1970Tab: zone1970Tab,
      zoneTab: zoneTab,
      backward: backward,
      isoJson: _isoJson,
      windowsZonesXml: windowsZonesXml,
    );

    test('rejects the fixtures, which are far too small to ship', () {
      expect(validate(parse()), isNotEmpty);
    });

    test('reports empty zone tables', () {
      expect(
        validate(parse(zone1970Tab: '', zoneTab: '')),
        anyElement(contains('zero timezone mappings')),
      );
    });

    test('reports an empty backward file', () {
      expect(
        validate(parse(backward: '')),
        anyElement(contains('zero legacy aliases')),
      );
    });
  });
}
