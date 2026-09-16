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

const _etcetera = '''
# Comment
Zone\tEtc/UTC\t0\t-\tUTC
Zone\tEtc/GMT\t0\t-\tGMT
Link\tEtc/GMT\tGMT
Zone\tEtc/GMT-14\t14\t-\t%z
Zone\tEtc/GMT+12\t-12
Zone\tEtc/Nonsense\tnoon\t-\t%z
#Zone\tGMT\t0\t-\tGMT
''';

const _metaZones = '''
<supplementalData>
  <metaZones>
    <metazoneInfo>
      <timezone type="America/New_York">
        <usesMetazone to="1970-01-01 00:00" mzone="America_Colonial"/>
        <usesMetazone from="1970-01-01 00:00" mzone="America_Eastern"/>
      </timezone>
      <timezone type="Europe/Brussels">
        <usesMetazone mzone="Europe_Central"/>
      </timezone>
      <timezone type="Norway">
        <usesMetazone mzone="Europe_Central"/>
      </timezone>
      <timezone type="Europe/Berlin">
        <usesMetazone to="1980-01-01 00:00" mzone="Europe_Central"/>
        <usesMetazone from="1980-01-01 00:00"/>
      </timezone>
      <timezone type="Etc/GMT">
        <usesMetazone mzone="GMT"/>
      </timezone>
      <timezone type="Etc/Unknown">
        <usesMetazone mzone="GMT"/>
      </timezone>
    </metazoneInfo>
  </metaZones>
  <primaryZones>
    <primaryZone iso3166="NO">Norway</primaryZone>
    <primaryZone iso3166="XX">America/Nowhere</primaryZone>
  </primaryZones>
</supplementalData>''';

const _en = '''
<ldml>
  <dates>
    <timeZoneNames>
      <regionFormat>{0} Time</regionFormat>
      <zone type="Etc/UTC">
        <long>
          <standard>Coordinated Universal Time</standard>
        </long>
      </zone>
      <zone type="Etc/Unknown">
        <exemplarCity>Unknown Location</exemplarCity>
      </zone>
      <zone type="Europe/Brussels">
        <long>
          <daylight>Brussels Summer Time</daylight>
        </long>
      </zone>
      <zone type="Europe/Berlin">
        <exemplarCity>Berlin &amp; Bonn</exemplarCity>
      </zone>
      <zone type="Norway">
        <exemplarCity>Oslo City</exemplarCity>
      </zone>
      <metazone type="Europe_Central">
        <long>
          <generic>Central European Time</generic>
          <standard>Central European Standard Time</standard>
          <daylight>Central European Summer Time</daylight>
        </long>
        <short>
          <generic>CET</generic>
        </short>
      </metazone>
      <metazone type="America_Eastern">
        <long>
          <generic>Eastern Time</generic>
        </long>
      </metazone>
      <metazone type="GMT">
        <long>
          <standard>Greenwich Mean Time</standard>
        </long>
        <short>
          <standard>GMT</standard>
        </short>
      </metazone>
    </timeZoneNames>
  </dates>
</ldml>''';

const _bcp47 = '''
<ldmlBCP47>
  <keyword>
    <key name="tz">
      <type name="noosl" description="Oslo, Norway" alias="Europe/Oslo Atlantic/Jan_Mayen"/>
      <type name="cayzs" description="Atikokan, Canada" alias="America/Coral_Harbour America/Atikokan" iana="America/Atikokan"/>
      <type name="unk" description="Unknown"/>
    </key>
  </keyword>
</ldmlBCP47>''';

const _windowsZones = '''
<supplementalData>
  <mapTimezones otherVersion="deadbee" typeVersion="1970a">
  <mapZone other="Romance Standard Time" territory="001" type="Europe/Paris"/>
  <mapZone other="Romance Standard Time" territory="BE" type="Europe/Brussels"/>
  <mapZone other="W. Europe Standard Time" territory="NO" type="Europe/Oslo Arctic/Longyearbyen"/>
  <mapZone other="India Standard Time" territory="001" type="Asia/Calcutta"/>
  </mapTimezones>
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
      expect(parseBackwardZones(_backward), contains('CST6CDT'));
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
      expect(windows.windowsToTimezones['W. Europe Standard Time']!['NO'], [
        'Europe/Oslo',
        'Arctic/Longyearbyen',
      ]);
      expect(windows.timezoneToWindows.containsKey('Europe/Oslo'), isTrue);
    });

    test('renames zones CLDR still lists under a deprecated identifier', () {
      expect(windows.windowsToTimezones['India Standard Time']!['001'], [
        'Asia/Kolkata',
      ]);
      expect(windows.timezoneToWindows['Asia/Calcutta'], isNull);
    });

    test('keys by Windows identifier, then territory', () {
      expect(windows.windowsToTimezones['Romance Standard Time'], {
        '001': ['Europe/Paris'],
        'BE': ['Europe/Brussels'],
      });
    });

    test('reverses every zone of a multi-zone territory', () {
      expect(
        windows.timezoneToWindows['Arctic/Longyearbyen'],
        'W. Europe Standard Time',
      );
    });

    test('reads the versions of the mapping itself', () {
      expect(windows.otherVersion, 'deadbee');
      expect(windows.typeVersion, '1970a');
    });

    test('leaves the versions null when the element is absent', () {
      final bare = parseWindowsZones('<supplementalData/>', {}, known);
      expect(bare.otherVersion, isNull);
      expect(bare.typeVersion, isNull);
    });
  });

  group('parseEtcetera', () {
    final etc = parseEtcetera(_etcetera);

    test('reads the offset tzdb states, not the one the name spells', () {
      expect(etc.offsets['Etc/GMT-14'], 14 * 3600);
      expect(etc.offsets['Etc/GMT+12'], -12 * 3600);
      expect(etc.offsets['Etc/UTC'], 0);
    });

    test('skips a zone whose offset field is unrecognised', () {
      expect(etc.offsets.containsKey('Etc/Nonsense'), isFalse);
    });

    test('skips commented-out zones', () {
      expect(etc.offsets.containsKey('GMT'), isFalse);
    });

    test('reads the aliases', () {
      expect(etc.links['GMT'], 'Etc/GMT');
    });
  });

  group('parseTzOffset', () {
    test('parses hours, minutes and seconds', () {
      expect(parseTzOffset('5'), 5 * 3600);
      expect(parseTzOffset('5:30'), 5 * 3600 + 30 * 60);
      expect(parseTzOffset('5:30:20'), 5 * 3600 + 30 * 60 + 20);
    });

    test('keeps a negative sign', () {
      expect(parseTzOffset('-5:30'), -(5 * 3600 + 30 * 60));
    });

    test('returns null for anything else', () {
      expect(parseTzOffset('noon'), isNull);
      expect(parseTzOffset(''), isNull);
    });
  });

  group('parseMetaZones', () {
    final legacy = parseBackward(_backward, known);
    final namable = {...known, 'Etc/GMT'};
    final meta = parseMetaZones(_metaZones, legacy, namable);

    test('takes the open-ended interval and drops the ended ones', () {
      expect(meta.timezoneToMetazone['America/New_York'], 'America_Eastern');
    });

    test('leaves out a zone whose last interval has ended', () {
      expect(meta.timezoneToMetazone.containsKey('Europe/Berlin'), isFalse);
    });

    test('resolves a zone CLDR names by a deprecated identifier', () {
      expect(meta.timezoneToMetazone['Europe/Oslo'], 'Europe_Central');
    });

    test('drops a zone that is not a known identifier', () {
      expect(meta.timezoneToMetazone.containsKey('Etc/Unknown'), isFalse);
    });

    test('keeps the fixed-offset zones', () {
      expect(meta.timezoneToMetazone['Etc/GMT'], 'GMT');
    });

    test('resolves and filters the primary zones', () {
      expect(meta.primaryTimezones, {'NO': 'Europe/Oslo'});
    });
  });

  group('parseTimeZoneNames', () {
    final legacy = parseBackward(_backward, known);
    final names = parseTimeZoneNames(_en, legacy, {...known, 'Etc/UTC'});

    test('reads metazone long names', () {
      expect(
        names.metazoneGenericNames['Europe_Central'],
        'Central European Time',
      );
      expect(
        names.metazoneStandardNames['Europe_Central'],
        'Central European Standard Time',
      );
      expect(
        names.metazoneDaylightNames['Europe_Central'],
        'Central European Summer Time',
      );
    });

    test('leaves out the name kinds a metazone lacks', () {
      expect(names.metazoneGenericNames.containsKey('GMT'), isFalse);
      expect(names.metazoneDaylightNames.containsKey('GMT'), isFalse);
      expect(names.metazoneStandardNames['GMT'], 'Greenwich Mean Time');
    });

    test('ignores the short names', () {
      expect(names.metazoneGenericNames['Europe_Central'], isNot('CET'));
    });

    test('reads names CLDR gives a zone rather than a metazone', () {
      expect(
        names.timezoneStandardNames['Etc/UTC'],
        'Coordinated Universal Time',
      );
      expect(
        names.timezoneDaylightNames['Europe/Brussels'],
        'Brussels Summer Time',
      );
      expect(names.timezoneGenericNames, isEmpty);
    });

    test('reads exemplar cities and resolves deprecated identifiers', () {
      expect(names.timezoneCities['Europe/Oslo'], 'Oslo City');
    });

    test('unescapes XML entities', () {
      expect(names.timezoneCities['Europe/Berlin'], 'Berlin & Bonn');
    });

    test('drops a zone that is not a known identifier', () {
      expect(names.timezoneCities.containsKey('Etc/Unknown'), isFalse);
    });

    test('returns nothing when the block is absent', () {
      final bare = parseTimeZoneNames('<ldml/>', legacy, known);
      expect(bare.timezoneCities, isEmpty);
      expect(bare.metazoneStandardNames, isEmpty);
    });
  });

  group('parseSources', () {
    final data = parseSources(
      zone1970Tab: _zone1970Tab,
      zoneTab: _zoneTab,
      backward: _backward,
      etcetera: _etcetera,
      isoJson: _isoJson,
      windowsZonesXml: _windowsZones,
      metaZonesXml: _metaZones,
      enXml: _en,
      bcp47Xml: _bcp47,
    );

    test('adds the etcetera aliases to the resolvable ones', () {
      expect(data.allAliases['GMT'], 'Etc/GMT');
      expect(data.allAliases['US/Eastern'], 'America/New_York');
      expect(data.legacyTimezones.containsKey('GMT'), isFalse);
    });

    test('prefers the CLDR primary zone over the single-zone rule', () {
      expect(data.primaryTimezones['NO'], 'Europe/Oslo');
    });

    test("uses a country's only zone when CLDR names none", () {
      expect(data.primaryTimezones['LU'], 'Europe/Brussels');
    });

    test('falls back to the zone a country owns when CLDR names none', () {
      final withoutPrimaryZones = parseSources(
        zone1970Tab: _zone1970Tab,
        zoneTab: _zoneTab,
        backward: _backward,
        etcetera: _etcetera,
        isoJson: _isoJson,
        windowsZonesXml: _windowsZones,
        metaZonesXml: '<supplementalData/>',
        enXml: _en,
        bcp47Xml: _bcp47,
      );
      expect(withoutPrimaryZones.primaryTimezones['NO'], 'Europe/Oslo');
    });
  });

  group('parseBcp47Aliases', () {
    final aliases = parseBcp47Aliases(_bcp47);

    test('maps every spelling onto the iana attribute when it is given', () {
      expect(aliases['America/Coral_Harbour'], 'America/Atikokan');
      expect(aliases.containsKey('America/Atikokan'), isFalse);
    });

    test('falls back to the first spelling when iana is absent', () {
      expect(aliases['Atlantic/Jan_Mayen'], 'Europe/Oslo');
      expect(aliases.containsKey('Europe/Oslo'), isFalse);
    });

    test('ignores a type that carries no alias', () {
      expect(aliases.values, isNot(contains('Unknown')));
    });
  });

  group('preferCldrTargets', () {
    const known = {'America/Atikokan', 'America/Panama'};
    const bcp47 = {
      'America/Coral_Harbour': 'America/Atikokan',
      'CST6CDT': 'America/Chicago',
      'Factory': 'Etc/Unknown',
    };

    test('re-points an alias IANA merged into the wrong country', () {
      expect(
        preferCldrTargets(
          {'America/Coral_Harbour': 'America/Panama'},
          bcp47,
          known,
        ),
        {'America/Coral_Harbour': 'America/Atikokan'},
      );
    });

    test('adds nothing, so a zone of its own stays a zone', () {
      expect(preferCldrTargets({}, bcp47, known), isEmpty);
    });

    test('leaves an alias alone when CLDR names a zone off the tables', () {
      expect(preferCldrTargets({'Factory': 'Etc/UTC'}, bcp47, known), {
        'Factory': 'Etc/UTC',
      });
    });
  });

  group('unambiguousZone', () {
    const owners = {
      'Europe/Brussels': 'BE',
      'Europe/Berlin': 'DE',
      'Europe/Oslo': 'NO',
      'America/New_York': 'US',
      'America/Chicago': 'US',
    };

    test('takes a sole zone the country does not own', () {
      expect(
        unambiguousZone('LU', ['Europe/Brussels'], owners),
        'Europe/Brussels',
      );
    });

    test('ignores a shared zone when the country owns one of its own', () {
      expect(
        unambiguousZone('NO', ['Europe/Oslo', 'Europe/Berlin'], owners),
        'Europe/Oslo',
      );
    });

    test('refuses to choose between two zones the country owns', () {
      expect(
        unambiguousZone('US', ['America/New_York', 'America/Chicago'], owners),
        isNull,
      );
    });
  });

  group('validateZoneTables', () {
    test('accepts the tables in the documented order', () {
      expect(
        validateZoneTables(zone1970Tab: _zone1970Tab, zoneTab: _zoneTab),
        isEmpty,
      );
    });

    test('catches the two tables being passed the wrong way round', () {
      expect(
        validateZoneTables(zone1970Tab: _zoneTab, zoneTab: _zone1970Tab),
        containsAll([
          contains('is not zone1970.tab'),
          contains('is not zone.tab'),
        ]),
      );
    });
  });

  group('validate', () {
    SourceData parse({
      String zone1970Tab = _zone1970Tab,
      String zoneTab = _zoneTab,
      String backward = _backward,
      String etcetera = _etcetera,
      String windowsZonesXml = _windowsZones,
      String metaZonesXml = _metaZones,
      String enXml = _en,
    }) => parseSources(
      zone1970Tab: zone1970Tab,
      zoneTab: zoneTab,
      backward: backward,
      etcetera: etcetera,
      isoJson: _isoJson,
      windowsZonesXml: windowsZonesXml,
      metaZonesXml: metaZonesXml,
      enXml: enXml,
      bcp47Xml: _bcp47,
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

    test('reports an empty etcetera file', () {
      expect(
        validate(parse(etcetera: '')),
        anyElement(contains('zero fixed-offset zones')),
      );
    });

    test('reports an empty metazone file', () {
      expect(
        validate(parse(metaZonesXml: '')),
        anyElement(contains('zero metazones')),
      );
    });

    test('reports an empty locale file', () {
      expect(
        validate(parse(enXml: '')),
        anyElement(contains('zero metazone names')),
      );
    });

    test('reports when no primary timezone resolves', () {
      expect(
        validate(parse(zone1970Tab: '', zoneTab: '', metaZonesXml: '')),
        anyElement(contains('zero primary timezones')),
      );
    });
  });
}
