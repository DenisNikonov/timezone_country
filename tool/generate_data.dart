// ignore_for_file: avoid_print

// Offline tool to generate const data files from IANA timezone database
// and ISO 3166-1 country data.
//
// Usage:
//   dart run tool/generate_data.dart <zone1970.tab> <backward> <iso_3166-1.json> [--version <v>]
//
// Example:
//   dart run tool/generate_data.dart /tmp/zone1970.tab /tmp/backward /tmp/iso_3166-1.json --version 2024b
import 'dart:convert';
import 'dart:io';

String _header(String? ianaVersion) {
  final versionLine =
      ianaVersion != null ? '// IANA version: $ianaVersion\n' : '';
  return '// GENERATED FILE - DO NOT EDIT\n'
      '// Generated from IANA Time Zone Database and ISO 3166-1\n'
      '$versionLine'
      '// Generator: tool/generate_data.dart\n';
}

void main(List<String> args) {
  // Extract --version flag if present.
  String? ianaVersion;
  final positional = <String>[];
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--version' && i + 1 < args.length) {
      ianaVersion = args[++i];
    } else {
      positional.add(args[i]);
    }
  }

  if (positional.length < 3) {
    print(
      'Usage: dart run tool/generate_data.dart '
      '<zone1970.tab> <backward> <iso_3166-1.json> '
      '[--version <iana-version>]',
    );
    exit(1);
  }

  final zoneTab = File(positional[0]).readAsStringSync();
  final backward = File(positional[1]).readAsStringSync();
  final isoJson = File(positional[2]).readAsStringSync();

  // Parse ISO 3166-1 JSON (Debian iso-codes format)
  final isoData =
      (jsonDecode(isoJson) as Map<String, dynamic>)['3166-1'] as List;

  final alpha2ToAlpha3 = <String, String>{};
  final countryNames = <String, String>{};

  for (final entry in isoData) {
    final map = entry as Map<String, dynamic>;
    final a2 = map['alpha_2'] as String;
    final a3 = map['alpha_3'] as String;
    // Prefer common_name (e.g. "Bolivia") over name ("Bolivia, Plurinational State of")
    final name = (map['common_name'] ?? map['name']) as String;

    alpha2ToAlpha3[a2] = a3;
    countryNames[a2] = name;
  }

  // Parse zone1970.tab
  final tzToCountry = <String, String>{};
  final tzToCountries = <String, List<String>>{};
  final countryToTzs = <String, List<String>>{};

  for (final line in zoneTab.split('\n')) {
    if (line.isEmpty || line.startsWith('#')) continue;
    final parts = line.split('\t');
    if (parts.length < 3) continue;

    final codes = parts[0].split(',');
    final tz = parts[2];

    tzToCountry[tz] = codes.first;
    tzToCountries[tz] = codes;

    for (final code in codes) {
      (countryToTzs[code] ??= []).add(tz);
    }
  }

  // Parse backward
  final legacy = <String, String>{};
  for (final line in backward.split('\n')) {
    if (line.isEmpty || line.startsWith('#')) continue;
    if (!line.startsWith('Link')) continue;
    final parts = line.split(RegExp(r'\s+'));
    if (parts.length < 3) continue;
    // Format: Link <target> <alias> [#comment]
    final target = parts[1];
    final alias = parts[2];
    legacy[alias] = target;
  }

  // Sanity check: abort if zone1970.tab produced no data
  if (tzToCountry.isEmpty) {
    print(
      'ERROR: zone1970.tab produced zero timezone mappings. '
      'The input file may be empty or malformed.',
    );
    exit(1);
  }

  // Sort all maps by key
  final sortedTzToCountry = _sortByKey(tzToCountry);
  final sortedTzToCountries = _sortByKey(tzToCountries);
  final sortedCountryToTzs = _sortByKey(countryToTzs);
  final sortedLegacy = _sortByKey(legacy);
  final sortedAlpha2ToAlpha3 = _sortByKey(alpha2ToAlpha3);

  final alpha3ToAlpha2 = <String, String>{
    for (final e in alpha2ToAlpha3.entries) e.value: e.key,
  };
  final sortedAlpha3ToAlpha2 = _sortByKey(alpha3ToAlpha2);
  final sortedCountryNames = _sortByKey(countryNames);

  const dataDir = 'lib/src/data';

  final header = _header(ianaVersion);

  _writeFile(
    '$dataDir/timezone_to_country_data.dart',
    _genStringMap(
      header,
      'timezoneToCountry',
      sortedTzToCountry,
      'Mapping from IANA timezone identifier to primary '
          'ISO 3166-1 alpha-2 country code.',
    ),
  );

  _writeFile(
    '$dataDir/timezone_to_countries_data.dart',
    _genStringListMap(
      header,
      'timezoneToCountries',
      sortedTzToCountries,
      'Mapping from IANA timezone identifier to all '
          'ISO 3166-1 alpha-2 country codes.',
    ),
  );

  _writeFile(
    '$dataDir/country_to_timezones_data.dart',
    _genStringListMap(
      header,
      'countryToTimezones',
      sortedCountryToTzs,
      'Mapping from ISO 3166-1 alpha-2 country code to '
          'IANA timezone identifiers.',
    ),
  );

  _writeFile(
    '$dataDir/legacy_timezones_data.dart',
    _genStringMap(
      header,
      'legacyTimezones',
      sortedLegacy,
      'Mapping from deprecated/legacy timezone names to '
          'canonical IANA identifiers.',
    ),
  );

  _writeFile(
    '$dataDir/alpha2_to_alpha3_data.dart',
    _genStringMap(
      header,
      'alpha2ToAlpha3',
      sortedAlpha2ToAlpha3,
      'Mapping from ISO 3166-1 alpha-2 to alpha-3 country codes.',
    ),
  );

  _writeFile(
    '$dataDir/alpha3_to_alpha2_data.dart',
    _genStringMap(
      header,
      'alpha3ToAlpha2',
      sortedAlpha3ToAlpha2,
      'Mapping from ISO 3166-1 alpha-3 to alpha-2 country codes.',
    ),
  );

  _writeFile(
    '$dataDir/iana_version_data.dart',
    _genVersionFile(header, ianaVersion),
  );

  _writeFile(
    '$dataDir/country_names_data.dart',
    _genStringMap(
      header,
      'countryNames',
      sortedCountryNames,
      'Mapping from ISO 3166-1 alpha-2 country code to English country name.',
    ),
  );

  print('Generated ${sortedTzToCountry.length} timezone->country mappings');
  print('Generated ${sortedCountryToTzs.length} country->timezone mappings');
  print('Generated ${sortedLegacy.length} legacy alias mappings');
  print('Generated ${sortedAlpha2ToAlpha3.length} alpha-2<->alpha-3 mappings');
  print('Generated ${sortedCountryNames.length} country name mappings');
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

String _genStringMap(
  String header,
  String name,
  Map<String, String> map,
  String doc,
) {
  final buffer =
      StringBuffer()
        ..writeln(header)
        ..writeln('/// $doc')
        ..writeln('const Map<String, String> $name = {');
  for (final MapEntry(:key, :value) in map.entries) {
    final escaped = value.replaceAll("'", r"\'");
    buffer.writeln("  '$key': '$escaped',");
  }
  buffer.writeln('};');
  return buffer.toString();
}

String _genStringListMap(
  String header,
  String name,
  Map<String, List<String>> map,
  String doc,
) {
  final buffer =
      StringBuffer()
        ..writeln(header)
        ..writeln('/// $doc')
        ..writeln('const Map<String, List<String>> $name = {');
  for (final MapEntry(:key, :value) in map.entries) {
    final values = value.map((v) => "'$v'").join(', ');
    buffer.writeln("  '$key': [$values],");
  }
  buffer.writeln('};');
  return buffer.toString();
}

String _genVersionFile(String header, String? ianaVersion) {
  final value = ianaVersion != null ? "'$ianaVersion'" : 'null';
  return '$header\n'
      '/// IANA Time Zone Database version used to generate data files.\n'
      'const String? ianaVersion = $value;\n';
}
