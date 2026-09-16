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
    required this.backwardTimezones,
    required this.windowsToTimezones,
    required this.timezoneToWindows,
    required this.windowsZonesVersion,
    required this.windowsZonesIanaVersion,
    required this.etceteraAliases,
    required this.etcTimezoneOffsets,
    required this.timezoneToMetazone,
    required this.primaryTimezones,
    required this.timezoneCities,
    required this.timezoneGenericNames,
    required this.timezoneStandardNames,
    required this.timezoneDaylightNames,
    required this.metazoneGenericNames,
    required this.metazoneStandardNames,
    required this.metazoneDaylightNames,
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
  final Set<String> backwardTimezones;
  final Map<String, Map<String, List<String>>> windowsToTimezones;
  final Map<String, String> timezoneToWindows;
  final String? windowsZonesVersion;
  final String? windowsZonesIanaVersion;
  final Map<String, String> etceteraAliases;
  final Map<String, int> etcTimezoneOffsets;
  final Map<String, String> timezoneToMetazone;
  final Map<String, String> primaryTimezones;
  final Map<String, String> timezoneCities;
  final Map<String, String> timezoneGenericNames;
  final Map<String, String> timezoneStandardNames;
  final Map<String, String> timezoneDaylightNames;
  final Map<String, String> metazoneGenericNames;
  final Map<String, String> metazoneStandardNames;
  final Map<String, String> metazoneDaylightNames;

  /// Non-fatal problems worth a human look, e.g. a new country name whose
  /// word order the generator does not know how to straighten.
  final List<String> warnings;

  /// Every alias the package resolves, `backward` winning over `etcetera`.
  ///
  /// The two files are kept apart above so that [validate] can still tell a
  /// truncated `backward` from a whole one.
  Map<String, String> get allAliases => {
    ...etceteraAliases,
    ...legacyTimezones,
  };
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

/// Parses the zones IANA `backward` declares outright: the System V names
/// POSIX still accepts. They carry no country, so they are outside the zone
/// tables.
///
/// tzdb has moved them between `Link` and `Zone` form and back. A `Link` puts
/// them in [parseBackward]'s result instead, which is why both forms have to
/// be read: an identifier must not stop being known because upstream changed
/// how it spells it.
Set<String> parseBackwardZones(String backward) => {
  for (final line in const LineSplitter().convert(backward))
    if (line.startsWith('Zone')) ?line.split(RegExp(r'\s+')).elementAtOrNull(1),
};

/// Parses IANA `etcetera`: the fixed-offset zones, as seconds east of UTC,
/// and the aliases its `Link` lines carry.
///
/// The sign in an `Etc/GMT` identifier is POSIX-style and points the opposite
/// way from the offset field read here, which is the real one.
({Map<String, int> offsets, Map<String, String> links}) parseEtcetera(
  String etcetera,
) {
  final offsets = <String, int>{};
  final links = <String, String>{};

  for (final line in const LineSplitter().convert(etcetera)) {
    final parts = line.split(RegExp(r'\s+'));
    if (parts.length < 3) continue;
    if (parts[0] == 'Zone') {
      final seconds = parseTzOffset(parts[2]);
      if (seconds != null) offsets[parts[1]] = seconds;
    } else if (parts[0] == 'Link') {
      links[parts[2]] = parts[1];
    }
  }

  return (offsets: offsets, links: links);
}

/// Parses a tzdb offset field (`h`, `h:mm` or `h:mm:ss`) as seconds east of
/// UTC. Returns `null` if unrecognised.
int? parseTzOffset(String value) {
  final match = RegExp(
    r'^([+-]?)(\d{1,2})(?::(\d{2})(?::(\d{2}))?)?$',
  ).firstMatch(value);
  if (match == null) return null;
  final magnitude =
      int.parse(match[2]!) * 3600 +
      int.parse(match[3] ?? '0') * 60 +
      int.parse(match[4] ?? '0');
  return match[1] == '-' ? -magnitude : magnitude;
}

/// Parses CLDR `bcp47/timezone.xml` into CLDR identifier → IANA identifier.
///
/// This is CLDR's own statement of what its spellings mean, and it is the only
/// source that gets `America/Coral_Harbour` to `America/Atikokan`: IANA's
/// `backward` links both to the merged `America/Panama` instead, which would
/// strand the Canadian zone with no display name.
///
/// The `iana` attribute is present only when it is not the first alias.
Map<String, String> parseBcp47Aliases(String xml) {
  final aliases = <String, String>{};
  for (final match in RegExp(
    r'<type\s+[^>]*alias="([^"]*)"([^>]*)/>',
  ).allMatches(xml)) {
    final spellings = match[1]!.split(' ').where((s) => s.isNotEmpty).toList();
    if (spellings.isEmpty) continue;
    final iana =
        RegExp(r'iana="([^"]*)"').firstMatch(match[2]!)?[1] ?? spellings.first;
    for (final spelling in spellings) {
      if (spelling != iana) aliases[spelling] = iana;
    }
  }
  return aliases;
}

/// Re-points the aliases whose IANA target sits in the wrong country.
///
/// `backward` may only link to a canonical zone, so an alias of a zone the
/// 1970 merge collapsed lands on the merged zone abroad: `Atlantic/Jan_Mayen`
/// on `Europe/Berlin`, `Pacific/Yap` on `Pacific/Port_Moresby`. The `#=`
/// comments fix some of these and CLDR's [bcp47] table fixes the rest.
///
/// Only keys [legacy] already holds are touched, and only where the CLDR
/// target is a zone-table zone: whether an identifier is an alias at all is
/// IANA's call, and CLDR still lists the System V names as aliases after tzdb
/// made them zones of their own.
Map<String, String> preferCldrTargets(
  Map<String, String> legacy,
  Map<String, String> bcp47,
  Set<String> known,
) => {
  for (final MapEntry(:key, :value) in legacy.entries)
    key: switch (bcp47[key]) {
      final target? when known.contains(target) => target,
      _ => value,
    },
};

/// The identifier this package files a CLDR-named zone under.
///
/// Renaming a zone that is in [known] would collapse the country-specific
/// zones onto the shared zone they link to, in another country.
String canonicalZone(
  String zone,
  Map<String, String> legacy,
  Set<String> known,
) => known.contains(zone) ? zone : legacy[zone] ?? zone;

/// Parses CLDR `metaZones.xml`.
///
/// A zone belongs to at most one metazone at a time; the intervals with a
/// `to` attribute have already ended and are dropped. CLDR keeps a zone whose
/// last interval has ended, and that zone has no metazone now.
///
/// Zones absent from [known] after [canonicalZone] are dropped: CLDR carries
/// placeholder identifiers that IANA refuses to define.
({Map<String, String> timezoneToMetazone, Map<String, String> primaryTimezones})
parseMetaZones(String xml, Map<String, String> legacy, Set<String> known) {
  final toMetazone = <String, String>{};
  final uses = RegExp(r'<usesMetazone\s+([^/>]*)/>');

  for (final block in RegExp(
    r'<timezone type="([^"]*)">(.*?)</timezone>',
    dotAll: true,
  ).allMatches(xml)) {
    final zone = canonicalZone(block[1]!, legacy, known);
    if (!known.contains(zone)) continue;
    for (final use in uses.allMatches(block[2]!)) {
      if (use[1]!.contains('to=')) continue;
      final mzone = RegExp(r'mzone="([^"]*)"').firstMatch(use[1]!);
      if (mzone != null) toMetazone.putIfAbsent(zone, () => mzone[1]!);
    }
  }

  final primary = <String, String>{};
  for (final match in RegExp(
    r'<primaryZone iso3166="([^"]*)">([^<]*)</primaryZone>',
  ).allMatches(xml)) {
    final zone = canonicalZone(match[2]!, legacy, known);
    if (known.contains(zone)) primary[match[1]!] = zone;
  }

  return (timezoneToMetazone: toMetazone, primaryTimezones: primary);
}

/// Parses the `timeZoneNames` block of a CLDR locale file.
///
/// Only the `long` names are read. CLDR gives English `short` names to a
/// handful of metazones, and an abbreviation that is unqualified by region
/// stands for more than one zone.
///
/// Drops unknown zones on the same terms as [parseMetaZones].
({
  Map<String, String> timezoneCities,
  Map<String, String> timezoneGenericNames,
  Map<String, String> timezoneStandardNames,
  Map<String, String> timezoneDaylightNames,
  Map<String, String> metazoneGenericNames,
  Map<String, String> metazoneStandardNames,
  Map<String, String> metazoneDaylightNames,
  List<String> warnings,
})
parseTimeZoneNames(String xml, Map<String, String> legacy, Set<String> known) {
  final warnings = <String>[];
  final seen = <String>{};
  final cities = <String, String>{};
  final zoneNames = {for (final kind in _nameKinds) kind: <String, String>{}};
  final metazoneNames = {
    for (final kind in _nameKinds) kind: <String, String>{},
  };

  final section = RegExp(
    r'<timeZoneNames>(.*?)</timeZoneNames>',
    dotAll: true,
  ).firstMatch(xml);

  if (section != null) {
    for (final block in RegExp(
      r'<zone type="([^"]*)">(.*?)</zone>',
      dotAll: true,
    ).allMatches(section[1]!)) {
      final zone = canonicalZone(block[1]!, legacy, known);
      if (!known.contains(zone)) continue;
      if (!seen.add(zone)) {
        warnings.add(
          'CLDR names $zone twice, once as ${block[1]}; the later block wins',
        );
      }
      final city = RegExp(
        r'<exemplarCity>(.*?)</exemplarCity>',
        dotAll: true,
      ).firstMatch(block[2]!);
      if (city != null) cities[zone] = _unescapeXml(city[1]!);
      for (final kind in _nameKinds) {
        final name = _longName(block[2]!, kind);
        if (name != null) zoneNames[kind]![zone] = name;
      }
    }

    for (final block in RegExp(
      r'<metazone type="([^"]*)">(.*?)</metazone>',
      dotAll: true,
    ).allMatches(section[1]!)) {
      for (final kind in _nameKinds) {
        final name = _longName(block[2]!, kind);
        if (name != null) metazoneNames[kind]![block[1]!] = name;
      }
    }
  }

  return (
    timezoneCities: cities,
    timezoneGenericNames: zoneNames['generic']!,
    timezoneStandardNames: zoneNames['standard']!,
    timezoneDaylightNames: zoneNames['daylight']!,
    metazoneGenericNames: metazoneNames['generic']!,
    metazoneStandardNames: metazoneNames['standard']!,
    metazoneDaylightNames: metazoneNames['daylight']!,
    warnings: warnings,
  );
}

const List<String> _nameKinds = ['generic', 'standard', 'daylight'];

String? _longName(String block, String kind) {
  final long = RegExp(r'<long>(.*?)</long>', dotAll: true).firstMatch(block);
  if (long == null) return null;
  final value = RegExp(
    '<$kind>(.*?)</$kind>',
    dotAll: true,
  ).firstMatch(long[1]!);
  return value == null ? null : _unescapeXml(value[1]!);
}

String _unescapeXml(String value) => value
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&amp;', '&');

/// Parses CLDR `windowsZones.xml`.
///
/// Each `mapZone` binds a Windows identifier and a territory to one or more
/// IANA zones. Territory `001` is the worldwide default.
///
/// CLDR names some zones by an identifier IANA has since renamed, so zones are
/// resolved through [canonicalZone].
({
  Map<String, Map<String, List<String>>> windowsToTimezones,
  Map<String, String> timezoneToWindows,
  String? otherVersion,
  String? typeVersion,
})
parseWindowsZones(String xml, Map<String, String> legacy, Set<String> known) {
  final windowsToTzs = <String, Map<String, List<String>>>{};
  final tzToWindows = <String, String>{};

  final pattern = RegExp(
    r'<mapZone\s+other="([^"]*)"\s+territory="([^"]*)"\s+type="([^"]*)"',
  );
  for (final match in pattern.allMatches(xml)) {
    final windows = match[1]!;
    final territory = match[2]!;
    final zones = [
      for (final zone in match[3]!.split(' '))
        if (zone.isNotEmpty) canonicalZone(zone, legacy, known),
    ];
    if (zones.isEmpty) continue;

    (windowsToTzs[windows] ??= {})[territory] = zones;
    for (final zone in zones) {
      tzToWindows.putIfAbsent(zone, () => windows);
    }
  }

  final versions = RegExp(
    r'<mapTimezones\s+otherVersion="([^"]*)"\s+typeVersion="([^"]*)"',
  ).firstMatch(xml);

  return (
    windowsToTimezones: windowsToTzs,
    timezoneToWindows: tzToWindows,
    otherVersion: versions?[1],
    typeVersion: versions?[2],
  );
}

/// The single zone that can stand for [code] without a CLDR ranking, or
/// `null` when the choice is not forced.
///
/// [zones] holding one entry settles it even when another country owns that
/// zone: Luxembourg has nothing but `Europe/Brussels`. Otherwise only a zone
/// the country owns will do, which is what separates Denmark's
/// `Europe/Copenhagen` from the `Europe/Berlin` it merely shares.
String? unambiguousZone(
  String code,
  List<String> zones,
  Map<String, String> timezoneToCountry,
) {
  if (zones.length == 1) return zones.single;
  final owned = [
    for (final zone in zones)
      if (timezoneToCountry[zone] == code) zone,
  ];
  return owned.length == 1 ? owned.single : null;
}

/// Runs every parser and assembles the result.
SourceData parseSources({
  required String zone1970Tab,
  required String zoneTab,
  required String backward,
  required String etcetera,
  required String isoJson,
  required String windowsZonesXml,
  required String metaZonesXml,
  required String enXml,
  required String bcp47Xml,
}) {
  final iso = parseIso3166(isoJson);
  final zones = parseZoneTables([zone1970Tab, zoneTab]);
  final known = zones.timezoneToCountry.keys.toSet();
  final bcp47 = parseBcp47Aliases(bcp47Xml);
  final legacy = preferCldrTargets(
    parseBackward(backward, known),
    bcp47,
    known,
  );
  final etc = parseEtcetera(etcetera);
  // CLDR's own spellings resolve through CLDR's own alias table first; the
  // IANA one is the fallback for identifiers bcp47 does not list.
  final aliases = {...etc.links, ...legacy, ...bcp47};
  final windows = parseWindowsZones(windowsZonesXml, aliases, known);

  // The fixed-offset zones carry no country, so they are outside the zone
  // tables and have to be admitted to the set CLDR identifiers resolve into.
  final namable = {...known, ...etc.offsets.keys};
  final metaZones = parseMetaZones(metaZonesXml, aliases, namable);
  final names = parseTimeZoneNames(enXml, aliases, namable);

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
    backwardTimezones: parseBackwardZones(backward),
    windowsToTimezones: windows.windowsToTimezones,
    timezoneToWindows: windows.timezoneToWindows,
    windowsZonesVersion: windows.otherVersion,
    windowsZonesIanaVersion: windows.typeVersion,
    etceteraAliases: etc.links,
    etcTimezoneOffsets: etc.offsets,
    timezoneToMetazone: metaZones.timezoneToMetazone,
    primaryTimezones: {
      for (final code in zones.countryToTimezones.keys)
        code:
            ?(metaZones.primaryTimezones[code] ??
            unambiguousZone(
              code,
              zones.countryToTimezones[code]!,
              zones.timezoneToCountry,
            )),
    },
    timezoneCities: names.timezoneCities,
    timezoneGenericNames: names.timezoneGenericNames,
    timezoneStandardNames: names.timezoneStandardNames,
    timezoneDaylightNames: names.timezoneDaylightNames,
    metazoneGenericNames: names.metazoneGenericNames,
    metazoneStandardNames: names.metazoneStandardNames,
    metazoneDaylightNames: names.metazoneDaylightNames,
    warnings: [...iso.warnings, ...names.warnings],
  );
}

/// Checks the two zone tables have not been passed the wrong way round,
/// before either is parsed. Every other source fails [validate] loudly when
/// misplaced, but these two share a format: swapping them parses cleanly and
/// answers with the wrong country for the zones the 1970 merge collapsed.
/// Only `zone1970.tab` lists several countries against one zone.
List<String> validateZoneTables({
  required String zone1970Tab,
  required String zoneTab,
}) {
  bool listsMultipleCountries(String table) => const LineSplitter()
      .convert(table)
      .where((line) => line.isNotEmpty && !line.startsWith('#'))
      .any((line) => line.split('\t').first.contains(','));

  return [
    if (!listsMultipleCountries(zone1970Tab))
      'the first zone table lists no multi-country zone, so it is not '
          'zone1970.tab',
    if (listsMultipleCountries(zoneTab))
      'the second zone table lists a multi-country zone, so it is not zone.tab',
  ];
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
  if (data.windowsToTimezones.length < 100)
    'only ${data.windowsToTimezones.length} Windows timezone identifiers '
        'parsed, expected at least 100',
  if (data.etcTimezoneOffsets.isEmpty)
    'etcetera produced zero fixed-offset zones',
  if (data.timezoneToMetazone.isEmpty) 'metaZones produced zero metazones',
  if (data.metazoneStandardNames.isEmpty)
    'the locale file produced zero metazone names',
  if (data.primaryTimezones.isEmpty) 'zero primary timezones resolved',
];
