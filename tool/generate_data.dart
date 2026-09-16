// ignore_for_file: avoid_print

// Offline tool to generate const data files from IANA timezone database,
// ISO 3166-1 country data and the CLDR Windows timezone mapping.
//
// Usage:
//   dart run tool/generate_data.dart <zone1970.tab> <zone.tab> <backward> <etcetera> <iso_3166-1.json> <windowsZones.xml> <metaZones.xml> <en.xml> <bcp47/timezone.xml> [--version <v>]
import 'dart:io';

import 'parse_source_data.dart';

String _header(String? ianaVersion) {
  final versionLine = ianaVersion != null
      ? '// IANA version: $ianaVersion\n'
      : '';
  return '// GENERATED FILE - DO NOT EDIT\n'
      '// Generated from IANA Time Zone Database, ISO 3166-1 and CLDR\n'
      '$versionLine'
      '// Generator: tool/generate_data.dart\n';
}

void main(List<String> args) {
  String? ianaVersion;
  final positional = <String>[];
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--version' && i + 1 < args.length) {
      ianaVersion = args[++i];
    } else {
      positional.add(args[i]);
    }
  }

  if (positional.length < 9) {
    print(
      'Usage: dart run tool/generate_data.dart '
      '<zone1970.tab> <zone.tab> <backward> <etcetera> <iso_3166-1.json> '
      '<windowsZones.xml> <metaZones.xml> <en.xml> <bcp47/timezone.xml> '
      '[--version <iana-version>]',
    );
    exit(1);
  }

  final sources = [
    for (final path in positional.take(9)) File(path).readAsStringSync(),
  ];

  final misplaced = validateZoneTables(
    zone1970Tab: sources[0],
    zoneTab: sources[1],
  );
  if (misplaced.isNotEmpty) {
    for (final problem in misplaced) {
      print('ERROR: $problem.');
    }
    print('Check the order of the arguments against the usage above.');
    exit(1);
  }

  final data = parseSources(
    zone1970Tab: sources[0],
    zoneTab: sources[1],
    backward: sources[2],
    etcetera: sources[3],
    isoJson: sources[4],
    windowsZonesXml: sources[5],
    metaZonesXml: sources[6],
    enXml: sources[7],
    bcp47Xml: sources[8],
  );

  final problems = validate(data);
  if (problems.isNotEmpty) {
    for (final problem in problems) {
      print('ERROR: $problem.');
    }
    print('The input files may be empty or malformed.');
    exit(1);
  }

  // Surfaced, not fatal: the data is usable, a human just has to decide
  // whether the name needs an override.
  for (final warning in data.warnings) {
    print('::warning::$warning');
  }

  const dataDir = 'lib/src/data';
  final header = _header(ianaVersion);

  void writeStringMap(
    String file,
    String name,
    Map<String, String> map,
    String doc,
  ) => _writeFile(
    '$dataDir/$file',
    _genMap(header, 'String', name, _sortByKey(map), doc, _quote),
  );

  void writeStringListMap(
    String file,
    String name,
    Map<String, List<String>> map,
    String doc,
  ) => _writeFile(
    '$dataDir/$file',
    _genMap(
      header,
      'List<String>',
      name,
      _sortByKey(map),
      doc,
      (list) => '[${list.map(_quote).join(', ')}]',
    ),
  );

  writeStringMap(
    'timezone_to_country_data.dart',
    'timezoneToCountry',
    data.timezoneToCountry,
    'Mapping from IANA timezone identifier to primary '
        'ISO 3166-1 alpha-2 country code.',
  );

  writeStringListMap(
    'timezone_to_countries_data.dart',
    'timezoneToCountries',
    data.timezoneToCountries,
    'Mapping from IANA timezone identifier to all '
        'ISO 3166-1 alpha-2 country codes.',
  );

  writeStringListMap(
    'country_to_timezones_data.dart',
    'countryToTimezones',
    data.countryToTimezones,
    'Mapping from ISO 3166-1 alpha-2 country code to '
        'IANA timezone identifiers.',
  );

  writeStringMap(
    'legacy_timezones_data.dart',
    'legacyTimezones',
    data.allAliases,
    'Mapping from deprecated/legacy timezone names to '
        'canonical IANA identifiers.',
  );

  writeStringMap(
    'alpha2_to_alpha3_data.dart',
    'alpha2ToAlpha3',
    data.alpha2ToAlpha3,
    'Mapping from ISO 3166-1 alpha-2 to alpha-3 country codes.',
  );

  writeStringMap('alpha3_to_alpha2_data.dart', 'alpha3ToAlpha2', {
    for (final e in data.alpha2ToAlpha3.entries) e.value: e.key,
  }, 'Mapping from ISO 3166-1 alpha-3 to alpha-2 country codes.');

  writeStringMap(
    'country_names_data.dart',
    'countryNames',
    data.countryNames,
    'Mapping from ISO 3166-1 alpha-2 country code to English country name.',
  );

  writeStringMap(
    'alpha2_to_numeric_data.dart',
    'alpha2ToNumeric',
    data.alpha2ToNumeric,
    'Mapping from ISO 3166-1 alpha-2 to numeric country codes.',
  );

  writeStringMap('numeric_to_alpha2_data.dart', 'numericToAlpha2', {
    for (final e in data.alpha2ToNumeric.entries) e.value: e.key,
  }, 'Mapping from ISO 3166-1 numeric to alpha-2 country codes.');

  writeStringMap(
    'timezone_comments_data.dart',
    'timezoneComments',
    data.timezoneComments,
    'Mapping from IANA timezone identifier to the English description in '
        'the zone tables.',
  );

  writeStringMap(
    'timezone_to_windows_data.dart',
    'timezoneToWindows',
    data.timezoneToWindows,
    'Mapping from IANA timezone identifier to Windows timezone identifier.',
  );

  _writeFile(
    '$dataDir/timezone_coordinates_data.dart',
    _genMap(
      header,
      '(double, double)',
      'timezoneCoordinates',
      _sortByKey(data.timezoneCoordinates),
      'Mapping from IANA timezone identifier to the latitude and longitude '
          'of its principal location, in degrees.',
      (point) => '(${point.$1}, ${point.$2})',
    ),
  );

  _writeFile(
    '$dataDir/windows_to_timezone_data.dart',
    _genMap(
      header,
      'Map<String, List<String>>',
      'windowsToTimezones',
      _sortByKey(data.windowsToTimezones),
      'Mapping from Windows timezone identifier to territory to the IANA '
          'timezone identifiers CLDR groups under it, preferred one first. '
          "Territory '001' is the worldwide default.",
      (byTerritory) =>
          '{${_sortByKey(byTerritory).entries.map((e) => '${_quote(e.key)}: [${e.value.map(_quote).join(', ')}]').join(', ')}}',
    ),
  );

  _writeFile(
    '$dataDir/etc_timezones_data.dart',
    _genMap(
      header,
      'int',
      'etcTimezoneOffsets',
      _sortByKey(data.etcTimezoneOffsets),
      'Mapping from fixed-offset IANA timezone identifier to its offset from '
          'UTC in seconds, positive east. The sign in the identifier is '
          'POSIX-style and points the other way.',
      (seconds) => '$seconds',
    ),
  );

  _writeFile(
    '$dataDir/backward_timezones_data.dart',
    _genStringSet(
      header,
      'backwardTimezones',
      data.backwardTimezones,
      'The IANA timezone identifiers the `backward` file declares as zones in '
          'their own right. They have no country and no canonical form to '
          'resolve to.',
    ),
  );

  writeStringMap(
    'timezone_metazone_data.dart',
    'timezoneToMetazone',
    data.timezoneToMetazone,
    'Mapping from IANA timezone identifier to the CLDR metazone it currently '
        'belongs to.',
  );

  writeStringMap(
    'primary_timezones_data.dart',
    'primaryTimezones',
    data.primaryTimezones,
    'Mapping from ISO 3166-1 alpha-2 country code to the one IANA timezone '
        'that stands for the country.',
  );

  writeStringMap(
    'timezone_cities_data.dart',
    'timezoneCities',
    data.timezoneCities,
    'Mapping from IANA timezone identifier to the English exemplar city CLDR '
        'gives it in place of the one its last path segment spells.',
  );

  writeStringMap(
    'timezone_generic_names_data.dart',
    'timezoneGenericNames',
    data.timezoneGenericNames,
    'Mapping from IANA timezone identifier to the English generic name CLDR '
        'gives the zone itself, overriding its metazone.',
  );

  writeStringMap(
    'timezone_standard_names_data.dart',
    'timezoneStandardNames',
    data.timezoneStandardNames,
    'Mapping from IANA timezone identifier to the English standard-time name '
        'CLDR gives the zone itself, overriding its metazone.',
  );

  writeStringMap(
    'timezone_daylight_names_data.dart',
    'timezoneDaylightNames',
    data.timezoneDaylightNames,
    'Mapping from IANA timezone identifier to the English daylight-time name '
        'CLDR gives the zone itself, overriding its metazone.',
  );

  writeStringMap(
    'metazone_generic_names_data.dart',
    'metazoneGenericNames',
    data.metazoneGenericNames,
    'Mapping from CLDR metazone to its English generic name.',
  );

  writeStringMap(
    'metazone_standard_names_data.dart',
    'metazoneStandardNames',
    data.metazoneStandardNames,
    'Mapping from CLDR metazone to its English standard-time name.',
  );

  writeStringMap(
    'metazone_daylight_names_data.dart',
    'metazoneDaylightNames',
    data.metazoneDaylightNames,
    'Mapping from CLDR metazone to its English daylight-time name.',
  );

  _writeFile(
    '$dataDir/iana_version_data.dart',
    _genVersionFile(
      header,
      ianaVersion,
      data.windowsZonesVersion,
      data.windowsZonesIanaVersion,
    ),
  );

  print(
    'Generated ${data.timezoneToCountry.length} timezone->country mappings',
  );
  print(
    'Generated ${data.countryToTimezones.length} country->timezone mappings',
  );
  print('Generated ${data.allAliases.length} legacy alias mappings');
  print('Generated ${data.alpha2ToAlpha3.length} alpha-2<->alpha-3 mappings');
  print('Generated ${data.timezoneCoordinates.length} timezone coordinates');
  print(
    'Generated ${data.windowsToTimezones.length} Windows timezone mappings',
  );
  print('Generated ${data.etcTimezoneOffsets.length} fixed-offset zones');
  print('Generated ${data.backwardTimezones.length} backward-only zones');
  print('Generated ${data.timezoneToMetazone.length} metazone assignments');
  print('Generated ${data.metazoneStandardNames.length} metazone names');
  print('Generated ${data.primaryTimezones.length} primary timezones');
  if (ianaVersion != null) print('IANA version: $ianaVersion');
  print('CLDR Windows mapping version: ${data.windowsZonesVersion}');
  print('CLDR Windows mapping IANA version: ${data.windowsZonesIanaVersion}');
}

Map<String, V> _sortByKey<V>(Map<String, V> map) => Map.fromEntries(
  map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
);

void _writeFile(String path, String content) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
  print('Wrote $path');
}

/// A Dart single-quoted string literal holding [value].
String _quote(String value) =>
    "'${value.replaceAll(r'\', r'\\').replaceAll("'", r"\'").replaceAll(r'$', r'\$')}'";

String _genMap<V>(
  String header,
  String valueType,
  String name,
  Map<String, V> map,
  String doc,
  String Function(V) renderValue,
) {
  final buffer = StringBuffer()
    ..writeln(header)
    ..writeln('/// $doc')
    ..writeln('const Map<String, $valueType> $name = {');
  for (final MapEntry(:key, :value) in map.entries) {
    buffer.writeln('  ${_quote(key)}: ${renderValue(value)},');
  }
  buffer.writeln('};');
  return buffer.toString();
}

String _genStringSet(
  String header,
  String name,
  Set<String> values,
  String doc,
) {
  final buffer = StringBuffer()
    ..writeln(header)
    ..writeln('/// $doc')
    ..writeln('const Set<String> $name = {');
  for (final value in values.toList()..sort()) {
    buffer.writeln('  ${_quote(value)},');
  }
  buffer.writeln('};');
  return buffer.toString();
}

String _genVersionFile(
  String header,
  String? ianaVersion,
  String? windowsZonesVersion,
  String? windowsZonesIanaVersion,
) {
  String constant(String doc, String name, String? value) =>
      '/// $doc\n'
      'const ${value == null ? 'String?' : 'String'} $name = '
      '${value == null ? 'null' : _quote(value)};\n';

  return '$header\n'
      '${constant('IANA Time Zone Database version used to generate data files.', 'ianaVersion', ianaVersion)}'
      '\n'
      "${constant("CLDR's own version stamp for the Windows timezone mapping.", 'windowsZonesVersion', windowsZonesVersion)}"
      '\n'
      '${constant('IANA Time Zone Database release the CLDR Windows timezone mapping\n/// was last aligned to.', 'windowsZonesIanaVersion', windowsZonesIanaVersion)}';
}
