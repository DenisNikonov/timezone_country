// Pure parsers for the upstream data files. Kept free of dart:io so that
// test/generator_test.dart can drive them with small string fixtures.
import 'dart:convert';

/// Everything parsed out of the upstream sources, before code generation.
class SourceData {
  SourceData({
    required this.alpha2ToAlpha3,
    required this.alpha2ToNumeric,
    required this.countryNames,
    required this.timezoneToCountry,
    required this.timezoneToCountries,
    required this.countryToTimezones,
    required this.timezoneComments,
    required this.timezoneCoordinates,
    required this.legacyTimezones,
    required this.windowsToTimezone,
    required this.timezoneToWindows,
    required this.warnings,
  });

  final Map<String, String> alpha2ToAlpha3;
  final Map<String, String> alpha2ToNumeric;
  final Map<String, String> countryNames;
  final Map<String, String> timezoneToCountry;
  final Map<String, List<String>> timezoneToCountries;
  final Map<String, List<String>> countryToTimezones;
  final Map<String, String> timezoneComments;
  final Map<String, (double, double)> timezoneCoordinates;
  final Map<String, String> legacyTimezones;
  final Map<String, Map<String, String>> windowsToTimezone;
  final Map<String, String> timezoneToWindows;

  /// Non-fatal problems worth a human look, e.g. a new country name whose
  /// word order the generator does not know how to straighten.
  final List<String> warnings;
}

/// Debian iso-codes writes several country names in inverted order
/// ("Palestine, State of"). Straightening them mechanically is not safe —
/// "Bonaire, Sint Eustatius and Saba" is a list, not an inversion — so the
/// affected codes are listed explicitly and anything new is reported.
const Map<String, String> countryNameOverrides = {
  'CD': 'Democratic Republic of the Congo',
  'FM': 'Federated States of Micronesia',
  'PS': 'State of Palestine',
  'VG': 'British Virgin Islands',
  'VI': 'U.S. Virgin Islands',
};

/// Country codes whose comma is part of a list of islands, not an inversion.
const Set<String> countryNamesWithCommaOk = {'BQ', 'SH'};

/// Parses the Debian iso-codes `iso_3166-1.json` payload.
({
  Map<String, String> alpha2ToAlpha3,
  Map<String, String> alpha2ToNumeric,
  Map<String, String> countryNames,
  List<String> warnings,
})
parseIso3166(String isoJson) {
  final entries =
      (jsonDecode(isoJson) as Map<String, dynamic>)['3166-1'] as List;

  final alpha2ToAlpha3 = <String, String>{};
  final alpha2ToNumeric = <String, String>{};
  final countryNames = <String, String>{};
  final warnings = <String>[];

  for (final entry in entries) {
    final map = entry as Map<String, dynamic>;
    final a2 = map['alpha_2'] as String;
    // common_name is the everyday short form; name can be the inverted long one.
    final name = (map['common_name'] ?? map['name']) as String;

    alpha2ToAlpha3[a2] = map['alpha_3'] as String;
    alpha2ToNumeric[a2] = map['numeric'] as String;
    countryNames[a2] = countryNameOverrides[a2] ?? name;

    if (countryNames[a2]!.contains(',') &&
        !countryNamesWithCommaOk.contains(a2)) {
      warnings.add('$a2 has an inverted name: "${countryNames[a2]}"');
    }
  }

  return (
    alpha2ToAlpha3: alpha2ToAlpha3,
    alpha2ToNumeric: alpha2ToNumeric,
    countryNames: countryNames,
    warnings: warnings,
  );
}

/// Parses IANA zone tables. Pass `zone1970.tab` before `zone.tab`: the former
/// is authoritative for multi-country zones, the latter supplies the
/// country-specific zones that the 1970 merge dropped.
({
  Map<String, String> timezoneToCountry,
  Map<String, List<String>> timezoneToCountries,
  Map<String, List<String>> countryToTimezones,
  Map<String, String> comments,
  Map<String, (double, double)> coordinates,
})
parseZoneTables(List<String> tables) {
  final tzToCountry = <String, String>{};
  final tzToCountries = <String, List<String>>{};
  final countryToTzs = <String, List<String>>{};
  final comments = <String, String>{};
  final coordinates = <String, (double, double)>{};

  for (final table in tables) {
    for (final line in const LineSplitter().convert(table)) {
      if (line.isEmpty || line.startsWith('#')) continue;
      final parts = line.split('\t');
      if (parts.length < 3) continue;

      final codes = parts[0].split(',');
      final tz = parts[2];

      if (!tzToCountry.containsKey(tz)) {
        tzToCountry[tz] = codes.first;
        tzToCountries[tz] = codes;
        final point = parseIso6709(parts[1]);
        if (point != null) coordinates[tz] = point;
        if (parts.length > 3 && parts[3].isNotEmpty) comments[tz] = parts[3];
      }

      for (final code in codes) {
        final zones = countryToTzs[code] ??= [];
        if (!zones.contains(tz)) zones.add(tz);
      }
    }
  }

  // Both tables sort rows by their *first* country code, so a country listed
  // only as a secondary code would get a foreign zone first.
  // Partition rather than sort: List.sort is unstable.
  for (final code in countryToTzs.keys.toList()) {
    final zones = countryToTzs[code]!;
    countryToTzs[code] = [
      for (final tz in zones)
        if (tzToCountry[tz] == code) tz,
      for (final tz in zones)
        if (tzToCountry[tz] != code) tz,
    ];
  }

  return (
    timezoneToCountry: tzToCountry,
    timezoneToCountries: tzToCountries,
    countryToTimezones: countryToTzs,
    comments: comments,
    coordinates: coordinates,
  );
}

/// Parses an ISO 6709 point as written in the zone tables:
/// `±DDMM±DDDMM` or `±DDMMSS±DDDMMSS`. Returns `null` if unrecognised.
(double, double)? parseIso6709(String value) {
  final match = RegExp(
    r'^([+-]\d{2})(\d{2})(\d{2})?([+-]\d{3})(\d{2})(\d{2})?$',
  ).firstMatch(value);
  if (match == null) return null;

  double toDegrees(String? d, String? m, String? s) {
    final magnitude =
        int.parse(d!).abs() +
        int.parse(m!) / 60 +
        (s == null ? 0 : int.parse(s) / 3600);
    // Take the sign from the text: a degrees field of "-00" parses to an
    // integer that no longer carries it.
    final signed = d.startsWith('-') ? -magnitude : magnitude;
    // The source is whole arc-seconds at best.
    return double.parse(signed.toStringAsFixed(5));
  }

  return (
    toDegrees(match[1], match[2], match[3]),
    toDegrees(match[4], match[5], match[6]),
  );
}

/// Parses the IANA `backward` file into alias → canonical identifier.
/// Only `Link` lines carry aliases; `Zone` lines in that file are real zones.
///
/// `backward` refuses to link to a link, so an alias of a zone-table zone
/// that is itself a link points at the merged zone, in another country, and
/// records the zone it stands for in a `#=` comment. That zone is used when
/// it is in [known].
Map<String, String> parseBackward(String backward, Set<String> known) {
  final legacy = <String, String>{};
  for (final line in const LineSplitter().convert(backward)) {
    if (!line.startsWith('Link')) continue;
    // Format: Link <target> <alias> [#= <zone-table target>]
    final parts = line.split(RegExp(r'\s+'));
    if (parts.length < 3) continue;
    final zoneTab = parts.length > 4 && parts[3] == '#=' ? parts[4] : null;
    legacy[parts[2]] = zoneTab != null && known.contains(zoneTab)
        ? zoneTab
        : parts[1];
  }
  return legacy;
}

/// Parses CLDR `windowsZones.xml`.
///
/// Each `mapZone` binds a Windows identifier and a territory to one or more
/// IANA zones. Territory `001` is the worldwide default.
///
/// CLDR names some zones by an identifier IANA has since renamed, so a zone
/// missing from [known] is looked up in [legacy]. Renaming a zone that is in
/// [known] would collapse the country-specific zones onto the shared zone
/// they link to, in another country.
({
  Map<String, Map<String, String>> windowsToTimezone,
  Map<String, String> timezoneToWindows,
})
parseWindowsZones(String xml, Map<String, String> legacy, Set<String> known) {
  final windowsToTz = <String, Map<String, String>>{};
  final tzToWindows = <String, String>{};

  final pattern = RegExp(
    r'<mapZone\s+other="([^"]*)"\s+territory="([^"]*)"\s+type="([^"]*)"',
  );
  for (final match in pattern.allMatches(xml)) {
    final windows = match[1]!;
    final territory = match[2]!;
    final zones = [
      for (final zone in match[3]!.split(' '))
        if (zone.isNotEmpty) known.contains(zone) ? zone : legacy[zone] ?? zone,
    ];
    if (zones.isEmpty) continue;

    (windowsToTz[windows] ??= {})[territory] = zones.first;
    for (final zone in zones) {
      tzToWindows.putIfAbsent(zone, () => windows);
    }
  }

  return (windowsToTimezone: windowsToTz, timezoneToWindows: tzToWindows);
}

/// Runs every parser and assembles the result.
SourceData parseSources({
  required String zone1970Tab,
  required String zoneTab,
  required String backward,
  required String isoJson,
  required String windowsZonesXml,
}) {
  final iso = parseIso3166(isoJson);
  final zones = parseZoneTables([zone1970Tab, zoneTab]);
  final known = zones.timezoneToCountry.keys.toSet();
  final legacy = parseBackward(backward, known);
  final windows = parseWindowsZones(windowsZonesXml, legacy, known);

  return SourceData(
    alpha2ToAlpha3: iso.alpha2ToAlpha3,
    alpha2ToNumeric: iso.alpha2ToNumeric,
    countryNames: iso.countryNames,
    timezoneToCountry: zones.timezoneToCountry,
    timezoneToCountries: zones.timezoneToCountries,
    countryToTimezones: zones.countryToTimezones,
    timezoneComments: zones.comments,
    timezoneCoordinates: zones.coordinates,
    legacyTimezones: legacy,
    windowsToTimezone: windows.windowsToTimezone,
    timezoneToWindows: windows.timezoneToWindows,
    warnings: iso.warnings,
  );
}

/// Returns the reasons [data] must not be written out, empty when it is sound.
///
/// An empty map passes every data-integrity test by iterating nothing, so
/// truncated input has to be caught here.
List<String> validate(SourceData data) => [
  if (data.timezoneToCountry.isEmpty)
    'the zone tables produced zero timezone mappings',
  if (data.legacyTimezones.isEmpty) 'backward produced zero legacy aliases',
  if (data.alpha2ToAlpha3.length < 240)
    'only ${data.alpha2ToAlpha3.length} ISO 3166-1 countries parsed, '
        'expected at least 240',
  if (data.windowsToTimezone.length < 100)
    'only ${data.windowsToTimezone.length} Windows timezone identifiers '
        'parsed, expected at least 100',
];
