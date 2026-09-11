// ignore_for_file: avoid_print

// Offline tool to generate const data files from IANA timezone database,
// ISO 3166-1 country data and the CLDR Windows timezone mapping.
//
// Usage:
//   dart run tool/generate_data.dart <zone1970.tab> <zone.tab> <backward> <iso_3166-1.json> <windowsZones.xml> [--version <v>]
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

  if (positional.length < 5) {
    print(
      'Usage: dart run tool/generate_data.dart '
      '<zone1970.tab> <zone.tab> <backward> <iso_3166-1.json> '
      '<windowsZones.xml> [--version <iana-version>]',
    );
    exit(1);
  }

  final data = parseSources(
    zone1970Tab: File(positional[0]).readAsStringSync(),
    zoneTab: File(positional[1]).readAsStringSync(),
    backward: File(positional[2]).readAsStringSync(),
    isoJson: File(positional[3]).readAsStringSync(),
    windowsZonesXml: File(positional[4]).readAsStringSync(),
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
    data.legacyTimezones,
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
      'Map<String, String>',
      'windowsToTimezone',
      _sortByKey(data.windowsToTimezone),
      'Mapping from Windows timezone identifier to territory to IANA '
          "timezone identifier. Territory '001' is the worldwide default.",
      (byTerritory) =>
          '{${_sortByKey(byTerritory).entries.map((e) => '${_quote(e.key)}: ${_quote(e.value)}').join(', ')}}',
    ),
  );

  _writeFile(
    '$dataDir/iana_version_data.dart',
    _genVersionFile(header, ianaVersion),
  );

  print(
    'Generated ${data.timezoneToCountry.length} timezone->country mappings',
  );
  print(
    'Generated ${data.countryToTimezones.length} country->timezone mappings',
  );
  print('Generated ${data.legacyTimezones.length} legacy alias mappings');
  print('Generated ${data.alpha2ToAlpha3.length} alpha-2<->alpha-3 mappings');
  print('Generated ${data.timezoneCoordinates.length} timezone coordinates');
  print('Generated ${data.windowsToTimezone.length} Windows timezone mappings');
  if (ianaVersion != null) print('IANA version: $ianaVersion');
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

String _genVersionFile(String header, String? ianaVersion) {
  final value = ianaVersion == null ? 'null' : _quote(ianaVersion);
  final type = ianaVersion == null ? 'String?' : 'String';
  return '$header\n'
      '/// IANA Time Zone Database version used to generate data files.\n'
      'const $type ianaVersion = $value;\n';
}
