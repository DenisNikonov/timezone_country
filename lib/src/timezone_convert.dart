import 'dart:math' as math;

import 'country_code_format.dart';
import 'data/alpha2_to_alpha3_data.dart' as data;
import 'data/alpha2_to_numeric_data.dart' as data;
import 'data/alpha3_to_alpha2_data.dart' as data;
import 'data/backward_timezones_data.dart' as data;
import 'data/country_names_data.dart' as data;
import 'data/country_to_timezones_data.dart' as data;
import 'data/etc_timezones_data.dart' as data;
import 'data/iana_version_data.dart' as data;
import 'data/legacy_timezones_data.dart' as data;
import 'data/metazone_daylight_names_data.dart' as data;
import 'data/metazone_generic_names_data.dart' as data;
import 'data/metazone_standard_names_data.dart' as data;
import 'data/numeric_to_alpha2_data.dart' as data;
import 'data/primary_timezones_data.dart' as data;
import 'data/timezone_cities_data.dart' as data;
import 'data/timezone_comments_data.dart' as data;
import 'data/timezone_coordinates_data.dart' as data;
import 'data/timezone_daylight_names_data.dart' as data;
import 'data/timezone_generic_names_data.dart' as data;
import 'data/timezone_metazone_data.dart' as data;
import 'data/timezone_standard_names_data.dart' as data;
import 'data/timezone_to_countries_data.dart' as data;
import 'data/timezone_to_country_data.dart' as data;
import 'data/timezone_to_windows_data.dart' as data;
import 'data/windows_to_timezone_data.dart' as data;

/// Bidirectional mapping between IANA timezone identifiers and
/// ISO 3166-1 country codes.
///
/// Identifier lookups are O(1) using compile-time const [Map]s.
/// [nearestTimezone] is the exception and scans every zone.
abstract final class TimezoneConvert {
  /// Regional Indicator Symbol range, used to build and read flag emoji.
  static const int _riA = 0x1F1E6;
  static const int _riZ = 0x1F1FF;
  static const int _riOffset = _riA - 0x41; // 'A' = 0x41

  /// The alpha-2 form of [countryCode], which may be alpha-2 or alpha-3
  /// in either letter case. Returns `null` for anything else.
  static String? _alpha2(String countryCode) {
    final normalized = countryCode.toUpperCase();
    if (normalized.length == CountryCodeFormat.alpha2.length) {
      return data.alpha2ToAlpha3.containsKey(normalized) ? normalized : null;
    }
    if (normalized.length == CountryCodeFormat.alpha3.length) {
      return data.alpha3ToAlpha2[normalized];
    }
    return null;
  }

  /// Renders [alpha2] in the requested [format], or `null` if it is not a
  /// known country code.
  static String? _format(String alpha2, CountryCodeFormat format) =>
      switch (format) {
        CountryCodeFormat.alpha2 =>
          data.alpha2ToAlpha3.containsKey(alpha2) ? alpha2 : null,
        CountryCodeFormat.alpha3 => data.alpha2ToAlpha3[alpha2],
      };

  /// The canonical form of [timezone] that carries a country association,
  /// falling back to legacy alias resolution for deprecated identifiers.
  static String _canonical(String timezone) =>
      data.timezoneToCountry.containsKey(timezone)
      ? timezone
      : resolveTimezone(timezone);

  // Timezone → Country

  /// Returns the primary country code for [timezone].
  ///
  /// The primary country is the one IANA lists first: the country of the
  /// zone's most populous city.
  ///
  /// Deprecated identifiers are resolved through [resolveTimezone] first,
  /// so `'US/Eastern'` and `'Asia/Calcutta'` also return a country.
  ///
  /// Returns `null` if [timezone] is not a known IANA timezone identifier.
  ///
  /// ```dart
  /// TimezoneConvert.timezoneToCountryCode('Asia/Tokyo'); // 'JP'
  /// TimezoneConvert.timezoneToCountryCode('Asia/Tokyo',
  ///     format: CountryCodeFormat.alpha3); // 'JPN'
  /// ```
  static String? timezoneToCountryCode(
    String timezone, {
    CountryCodeFormat format = CountryCodeFormat.alpha2,
  }) {
    final alpha2 = data.timezoneToCountry[_canonical(timezone)];
    if (alpha2 == null) return null;
    return switch (format) {
      CountryCodeFormat.alpha2 => alpha2,
      CountryCodeFormat.alpha3 => data.alpha2ToAlpha3[alpha2],
    };
  }

  /// Returns all country codes served by [timezone].
  ///
  /// Most timezones serve a single country, but some serve multiple
  /// (e.g., `Europe/Brussels` serves `['BE', 'LU', 'NL']`).
  ///
  /// Deprecated identifiers are resolved through [resolveTimezone] first.
  ///
  /// Returns `null` if [timezone] is not found.
  static List<String>? timezoneToCountryCodes(
    String timezone, {
    CountryCodeFormat format = CountryCodeFormat.alpha2,
  }) {
    final codes = data.timezoneToCountries[_canonical(timezone)];
    if (codes == null) return null;
    return switch (format) {
      CountryCodeFormat.alpha2 => codes,
      CountryCodeFormat.alpha3 => List.unmodifiable([
        for (final code in codes) ?data.alpha2ToAlpha3[code],
      ]),
    };
  }

  // Country → Timezones

  /// Returns all IANA timezone identifiers for [countryCode].
  ///
  /// Accepts both alpha-2 and alpha-3 codes (auto-detected by length).
  /// Input is case-insensitive.
  ///
  /// The zones the country owns come first, then the zones it merely shares
  /// with another country. Within each of those two groups the order is the
  /// one the IANA zone tables list the rows in, which is neither by
  /// population nor alphabetical, so the first entry is not the country's
  /// principal zone and must not be treated as a default.
  ///
  /// Returns `null` if [countryCode] is not found.
  ///
  /// ```dart
  /// TimezoneConvert.countryToTimezones('JP');  // ['Asia/Tokyo']
  /// TimezoneConvert.countryToTimezones('USA'); // ['America/New_York', ...]
  /// ```
  static List<String>? countryToTimezones(String countryCode) {
    final alpha2 = _alpha2(countryCode);
    if (alpha2 == null) return null;
    return data.countryToTimezones[alpha2];
  }

  /// Returns the one IANA timezone that stands for [countryCode].
  ///
  /// That is the zone CLDR designates, and otherwise the single zone the
  /// country owns — zones it merely shares with a neighbour do not count, so
  /// Denmark answers `Europe/Copenhagen` despite also listing
  /// `Europe/Berlin`. Returns `null` for a country that owns several zones and
  /// has no CLDR designation, rather than picking one: no ordering in the
  /// source data ranks them.
  ///
  /// Accepts both alpha-2 and alpha-3 codes (case-insensitive).
  static String? primaryTimezone(String countryCode) {
    final alpha2 = _alpha2(countryCode);
    if (alpha2 == null) return null;
    return data.primaryTimezones[alpha2];
  }

  // Legacy Resolution

  /// Resolves a legacy/deprecated timezone name to its canonical IANA form.
  ///
  /// Returns the canonical name if [timezone] is a known alias,
  /// or [timezone] unchanged if it is already canonical or unknown.
  ///
  /// ```dart
  /// TimezoneConvert.resolveTimezone('US/Eastern'); // 'America/New_York'
  /// TimezoneConvert.resolveTimezone('Asia/Tokyo'); // 'Asia/Tokyo'
  /// ```
  static String resolveTimezone(String timezone) =>
      data.legacyTimezones[timezone] ?? timezone;

  // Country Code Conversion

  /// Converts an ISO 3166-1 alpha-2 code to alpha-3.
  ///
  /// Returns `null` if [alpha2] is not a known code.
  static String? alpha2ToAlpha3(String alpha2) =>
      data.alpha2ToAlpha3[alpha2.toUpperCase()];

  /// Converts an ISO 3166-1 alpha-3 code to alpha-2.
  ///
  /// Returns `null` if [alpha3] is not a known code.
  static String? alpha3ToAlpha2(String alpha3) =>
      data.alpha3ToAlpha2[alpha3.toUpperCase()];

  // Country Name

  /// Returns the English name for [countryCode].
  ///
  /// Accepts both alpha-2 and alpha-3 codes (auto-detected by length).
  /// Input is case-insensitive.
  ///
  /// Returns `null` if [countryCode] is not found.
  ///
  /// ```dart
  /// TimezoneConvert.countryName('JP');  // 'Japan'
  /// TimezoneConvert.countryName('USA'); // 'United States'
  /// ```
  static String? countryName(String countryCode) {
    final alpha2 = _alpha2(countryCode);
    if (alpha2 == null) return null;
    return data.countryNames[alpha2];
  }

  // Flag Emoji

  /// Returns the flag emoji for [countryCode].
  ///
  /// Uses Unicode Regional Indicator Symbols to build the flag.
  /// Accepts both alpha-2 and alpha-3 codes (auto-detected by length).
  /// Input is case-insensitive.
  ///
  /// Returns `null` if [countryCode] is not a known country code.
  ///
  /// ```dart
  /// TimezoneConvert.countryFlag('JP');  // '\u{1f1ef}\u{1f1f5}'
  /// TimezoneConvert.countryFlag('USA'); // '\u{1f1fa}\u{1f1f8}'
  /// ```
  static String? countryFlag(String countryCode) {
    final alpha2 = _alpha2(countryCode);
    if (alpha2 == null) return null;
    return String.fromCharCodes([
      alpha2.codeUnitAt(0) + _riOffset,
      alpha2.codeUnitAt(1) + _riOffset,
    ]);
  }

  /// Returns the ISO 3166-1 country code for a flag emoji.
  ///
  /// The inverse of [countryFlag]. Returns `null` if [flag] is not a pair of
  /// Regional Indicator Symbols naming a known country.
  ///
  /// ```dart
  /// TimezoneConvert.countryCodeFromFlag('🇯🇵'); // 'JP'
  /// ```
  static String? countryCodeFromFlag(
    String flag, {
    CountryCodeFormat format = CountryCodeFormat.alpha2,
  }) {
    final runes = flag.runes.toList();
    if (runes.length != 2) return null;
    for (final rune in runes) {
      if (rune < _riA || rune > _riZ) return null;
    }
    final alpha2 = String.fromCharCodes([
      for (final rune in runes) rune - _riOffset,
    ]);
    return _format(alpha2, format);
  }

  // Numeric Codes

  /// Returns the ISO 3166-1 numeric code for [countryCode] as a
  /// zero-padded three-digit string (e.g. `'JP'` → `'392'`).
  ///
  /// Accepts both alpha-2 and alpha-3 codes (case-insensitive).
  /// Returns `null` if [countryCode] is not found.
  static String? countryNumericCode(String countryCode) {
    final alpha2 = _alpha2(countryCode);
    if (alpha2 == null) return null;
    return data.alpha2ToNumeric[alpha2];
  }

  /// Returns the country code for an ISO 3166-1 numeric code.
  ///
  /// [numeric] may be given with or without leading zeros (`'004'` or `'4'`).
  /// Returns `null` if it is not a known numeric code.
  ///
  /// ```dart
  /// TimezoneConvert.numericToCountryCode('392'); // 'JP'
  /// ```
  static String? numericToCountryCode(
    String numeric, {
    CountryCodeFormat format = CountryCodeFormat.alpha2,
  }) {
    final padded = numeric.padLeft(3, '0');
    final alpha2 = data.numericToAlpha2[padded];
    if (alpha2 == null) return null;
    return _format(alpha2, format);
  }

  // Windows Timezones

  /// Returns the IANA timezone identifier for a Windows timezone identifier.
  ///
  /// A Windows zone spans several countries, each with its own IANA zone, so
  /// pass [countryCode] when it is known. Without it, or when CLDR does not
  /// cover that country, the worldwide default is returned.
  ///
  /// Returns `null` if [windowsId] is not a known Windows timezone
  /// identifier, or if [countryCode] is given and is not a country code.
  ///
  /// ```dart
  /// TimezoneConvert.windowsToTimezone('Romance Standard Time'); // 'Europe/Paris'
  /// TimezoneConvert.windowsToTimezone('Romance Standard Time',
  ///     countryCode: 'BE'); // 'Europe/Brussels'
  /// ```
  ///
  /// See [windowsToTimezones] for the other zones CLDR groups under the same
  /// identifier and territory.
  static String? windowsToTimezone(String windowsId, {String? countryCode}) =>
      windowsToTimezones(windowsId, countryCode: countryCode)?.first;

  /// Returns every IANA timezone identifier CLDR groups under a Windows
  /// timezone identifier, with the one [windowsToTimezone] returns first.
  ///
  /// A Windows zone covers a whole country at once, so a country split across
  /// several IANA zones contributes all of them here. Selection between them
  /// needs information a Windows identifier does not carry.
  ///
  /// Resolves [countryCode] and returns `null` on the same terms as
  /// [windowsToTimezone].
  static List<String>? windowsToTimezones(
    String windowsId, {
    String? countryCode,
  }) {
    final byTerritory = data.windowsToTimezones[windowsId];
    if (byTerritory == null) return null;
    if (countryCode != null) {
      final alpha2 = _alpha2(countryCode);
      if (alpha2 == null) return null;
      final zones = byTerritory[alpha2];
      if (zones != null) return zones;
    }
    return byTerritory[_worldwideTerritory];
  }

  /// Returns the Windows timezone identifier for [timezone].
  ///
  /// Deprecated identifiers are resolved first. Returns `null` if CLDR has no
  /// Windows equivalent.
  ///
  /// ```dart
  /// TimezoneConvert.timezoneToWindows('Asia/Tokyo'); // 'Tokyo Standard Time'
  /// ```
  static String? timezoneToWindows(String timezone) =>
      // A country-specific zone can be absent from CLDR while its link
      // target is listed.
      data.timezoneToWindows[_canonical(timezone)] ??
      data.timezoneToWindows[resolveTimezone(timezone)];

  // Location

  /// Returns the English description IANA gives [timezone] in the zone
  /// tables, naming the part of the country it covers.
  ///
  /// Most single-zone countries have no description. Returns `null` then, and
  /// for unknown identifiers.
  static String? timezoneComment(String timezone) =>
      data.timezoneComments[_canonical(timezone)];

  /// Returns the latitude and longitude in degrees of the principal location
  /// of [timezone] — the city the identifier is named after, not a centroid
  /// of the region the zone covers.
  ///
  /// Returns `null` if [timezone] is not a known identifier.
  ///
  /// ```dart
  /// final (latitude, longitude) = TimezoneConvert.timezoneCoordinates('Asia/Tokyo')!;
  /// ```
  static (double latitude, double longitude)? timezoneCoordinates(
    String timezone,
  ) => data.timezoneCoordinates[_canonical(timezone)];

  /// Returns the timezone whose principal location is closest to
  /// ([latitude], [longitude]).
  ///
  /// This is a nearest-city search, not a timezone boundary lookup, and the
  /// two disagree often enough that the result is a guess: a point well
  /// inside one zone is regularly closer to the city naming another, even
  /// within a single country. Use it where a wrong-but-close answer is
  /// acceptable, and reach for a shapefile-based lookup where it is not.
  ///
  /// [countryCode] restricts the search to one country. Returns `null` if it
  /// is given and has no timezone to search; scans every known timezone
  /// otherwise, in O(n).
  static String? nearestTimezone(
    double latitude,
    double longitude, {
    String? countryCode,
  }) {
    final Iterable<String> candidates;
    if (countryCode == null) {
      candidates = data.timezoneCoordinates.keys;
    } else {
      final zones = countryToTimezones(countryCode);
      if (zones == null) return null;
      candidates = zones;
    }

    String? nearest;
    var shortest = double.infinity;
    for (final timezone in candidates) {
      final point = data.timezoneCoordinates[timezone];
      if (point == null) continue;
      final distance = _angularDistance(
        latitude,
        longitude,
        point.$1,
        point.$2,
      );
      if (distance < shortest) {
        shortest = distance;
        nearest = timezone;
      }
    }
    return nearest;
  }

  /// CLDR territory code for "the whole world", the fallback mapping every
  /// Windows timezone identifier carries.
  static const String _worldwideTerritory = '001';

  /// Great-circle separation of two points in radians. Only the ordering
  /// matters here, so the Earth's radius is left out.
  static double _angularDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const toRadians = math.pi / 180;
    final dLat = (lat2 - lat1) * toRadians;
    final dLon = (lon2 - lon1) * toRadians;
    final chord =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * toRadians) *
            math.cos(lat2 * toRadians) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return 2 * math.asin(math.min(1, math.sqrt(chord)));
  }

  // Display Names

  /// Returns the English city CLDR shows for [timezone].
  ///
  /// Usually the last segment of the identifier with underscores replaced by
  /// spaces; CLDR overrides that where the segment is not the name people
  /// use. Returns `null` for the fixed-offset zones, which name no place, and
  /// for unknown identifiers.
  ///
  /// ```dart
  /// TimezoneConvert.timezoneCity('America/New_York'); // 'New York'
  /// ```
  static String? timezoneCity(String timezone) {
    final canonical = _canonical(timezone);
    final override = data.timezoneCities[canonical];
    if (override != null) return override;
    if (!data.timezoneToCountry.containsKey(canonical)) return null;
    return canonical
        .substring(canonical.lastIndexOf('/') + 1)
        .replaceAll('_', ' ');
  }

  /// Returns the CLDR metazone [timezone] currently belongs to.
  ///
  /// A metazone groups the zones that share a display name. This is the
  /// grouping [timezoneGenericName] and its siblings read; it is not an
  /// identifier IANA knows, and CLDR reassigns zones between metazones.
  ///
  /// Returns `null` for a zone CLDR has taken out of every metazone, and for
  /// unknown identifiers.
  static String? metazone(String timezone) =>
      data.timezoneToMetazone[_canonical(timezone)];

  /// Returns the English name [timezone] goes by whatever the date, such as
  /// `'Mountain Time'`.
  ///
  /// Returns `null` where CLDR gives the zone no generic name, which is the
  /// case for zones that never leave standard time.
  static String? timezoneGenericName(String timezone) => _displayName(
    timezone,
    data.timezoneGenericNames,
    data.metazoneGenericNames,
  );

  /// Returns the English name for [timezone]'s standard time, such as
  /// `'Mountain Standard Time'`.
  ///
  /// Returns `null` where CLDR gives the zone no standard-time name.
  static String? timezoneStandardName(String timezone) => _displayName(
    timezone,
    data.timezoneStandardNames,
    data.metazoneStandardNames,
  );

  /// Returns the English name for [timezone]'s daylight saving time, such as
  /// `'Mountain Daylight Time'`.
  ///
  /// Returns `null` where CLDR gives the zone no daylight-time name, which
  /// includes every zone that observes no daylight saving. This says nothing
  /// about whether the zone is on daylight time now: the package does no time
  /// arithmetic.
  static String? timezoneDaylightName(String timezone) => _displayName(
    timezone,
    data.timezoneDaylightNames,
    data.metazoneDaylightNames,
  );

  static String? _displayName(
    String timezone,
    Map<String, String> zoneNames,
    Map<String, String> metazoneNames,
  ) {
    final canonical = _canonical(timezone);
    final own = zoneNames[canonical];
    if (own != null) return own;
    final group = data.timezoneToMetazone[canonical];
    return group == null ? null : metazoneNames[group];
  }

  // Fixed Offsets

  /// Returns the offset from UTC that [timezone] is fixed at.
  ///
  /// Only the `Etc/*` zones have one. Every other zone changes offset with
  /// the date, and this package does no time arithmetic, so it returns `null`
  /// for them and for unknown identifiers.
  ///
  /// The sign is the real one: an identifier's own sign is POSIX-style and
  /// points the other way.
  ///
  /// ```dart
  /// TimezoneConvert.timezoneFixedOffset('Etc/GMT-1'); // 1 hour ahead of UTC
  /// ```
  static Duration? timezoneFixedOffset(String timezone) {
    final seconds = data.etcTimezoneOffsets[_canonical(timezone)];
    return seconds == null ? null : Duration(seconds: seconds);
  }

  // Validation

  /// Returns `true` if [timezone] is an identifier this package knows,
  /// whether or not it has a country.
  ///
  /// Wider than [isValidTimezone]: the `Etc/*` zones real devices report, the
  /// deprecated aliases of them, and the System V names POSIX still accepts
  /// (`EST5EDT` and its three siblings) all return `true` here.
  static bool isKnownTimezone(String timezone) {
    final canonical = _canonical(timezone);
    return data.timezoneToCountry.containsKey(canonical) ||
        data.etcTimezoneOffsets.containsKey(canonical) ||
        data.backwardTimezones.contains(canonical);
  }

  /// Returns `true` if [timezone] is a known IANA timezone identifier
  /// with a country association, including deprecated aliases such as
  /// `US/Eastern`.
  ///
  /// The `Etc/*` zones return `false` because they have no associated
  /// country in the IANA zone tables. Use [isKnownTimezone] to tell those
  /// apart from identifiers the package does not recognise at all.
  static bool isValidTimezone(String timezone) =>
      data.timezoneToCountry.containsKey(_canonical(timezone));

  /// Returns `true` if [countryCode] has at least one associated timezone.
  ///
  /// Accepts both alpha-2 and alpha-3 formats (case-insensitive).
  ///
  /// Narrower than [isKnownCountryCode]: ISO 3166-1 codes that have no IANA
  /// timezone return `false` here.
  static bool isValidCountryCode(String countryCode) =>
      data.countryToTimezones.containsKey(_alpha2(countryCode));

  /// Returns `true` if [countryCode] is a known ISO 3166-1 code, whether or
  /// not it has an associated timezone.
  ///
  /// Accepts both alpha-2 and alpha-3 formats (case-insensitive).
  static bool isKnownCountryCode(String countryCode) =>
      _alpha2(countryCode) != null;

  // Enumeration

  /// Every IANA timezone identifier with a country, sorted alphabetically.
  /// The `Etc/*` zones are not among them; see [fixedOffsetTimezones].
  static final List<String> allTimezones = List.unmodifiable(
    data.timezoneToCountry.keys.toList()..sort(),
  );

  /// Every fixed-offset IANA timezone identifier, sorted alphabetically.
  static final List<String> fixedOffsetTimezones = List.unmodifiable(
    data.etcTimezoneOffsets.keys.toList()..sort(),
  );

  /// All known ISO 3166-1 alpha-2 country codes, sorted alphabetically.
  static final List<String> allCountryCodes = List.unmodifiable(
    data.countryToTimezones.keys.toList()..sort(),
  );

  /// All known ISO 3166-1 alpha-3 country codes, sorted alphabetically.
  static final List<String> allCountryCodesAlpha3 = List.unmodifiable(
    data.alpha2ToAlpha3.values.toList()..sort(),
  );

  // Raw Data Access

  /// Raw timezone-to-primary-country mapping (alpha-2).
  static Map<String, String> get timezoneToCountryMap => data.timezoneToCountry;

  /// Raw timezone-to-all-countries mapping (alpha-2).
  static Map<String, List<String>> get timezoneToCountriesMap =>
      data.timezoneToCountries;

  /// Raw country-to-timezones mapping (alpha-2 keys), ordered as
  /// [countryToTimezones] describes.
  static Map<String, List<String>> get countryToTimezonesMap =>
      data.countryToTimezones;

  /// Raw legacy-timezone-to-canonical mapping.
  static Map<String, String> get legacyTimezoneAliases => data.legacyTimezones;

  /// Raw alpha-2-to-alpha-3 mapping.
  static Map<String, String> get alpha2ToAlpha3Map => data.alpha2ToAlpha3;

  /// Raw alpha-3-to-alpha-2 mapping.
  static Map<String, String> get alpha3ToAlpha2Map => data.alpha3ToAlpha2;

  /// Raw alpha-2-to-country-name mapping.
  static Map<String, String> get countryNamesMap => data.countryNames;

  /// Raw alpha-2-to-numeric mapping.
  static Map<String, String> get alpha2ToNumericMap => data.alpha2ToNumeric;

  /// Raw numeric-to-alpha-2 mapping.
  static Map<String, String> get numericToAlpha2Map => data.numericToAlpha2;

  /// Raw timezone-to-description mapping.
  static Map<String, String> get timezoneCommentsMap => data.timezoneComments;

  /// Raw timezone-to-coordinates mapping, in degrees.
  static Map<String, (double latitude, double longitude)>
  get timezoneCoordinatesMap => data.timezoneCoordinates;

  /// Raw Windows-identifier-to-territory-to-timezone mapping, holding the
  /// preferred timezone of each territory.
  ///
  /// Built on first use from [windowsToTimezonesMap], which carries the
  /// zones this one drops.
  static Map<String, Map<String, String>> get windowsToTimezoneMap =>
      _windowsToTimezonePreferred;

  static final Map<String, Map<String, String>> _windowsToTimezonePreferred =
      Map.unmodifiable({
        for (final MapEntry(key: windowsId, value: byTerritory)
            in data.windowsToTimezones.entries)
          windowsId: Map<String, String>.unmodifiable({
            for (final MapEntry(key: territory, value: zones)
                in byTerritory.entries)
              territory: zones.first,
          }),
      });

  /// Raw Windows-identifier-to-territory-to-timezones mapping, preferred
  /// timezone of each territory first.
  static Map<String, Map<String, List<String>>> get windowsToTimezonesMap =>
      data.windowsToTimezones;

  /// Raw timezone-to-Windows-identifier mapping.
  static Map<String, String> get timezoneToWindowsMap => data.timezoneToWindows;

  /// Raw country-to-primary-timezone mapping (alpha-2 keys), holding only the
  /// countries [primaryTimezone] answers for.
  static Map<String, String> get primaryTimezonesMap => data.primaryTimezones;

  /// Raw timezone-to-metazone mapping, holding only the zones that are in a
  /// metazone.
  static Map<String, String> get timezoneToMetazoneMap =>
      data.timezoneToMetazone;

  /// Raw metazone-to-generic-name mapping.
  static Map<String, String> get metazoneGenericNamesMap =>
      data.metazoneGenericNames;

  /// Raw metazone-to-standard-name mapping.
  static Map<String, String> get metazoneStandardNamesMap =>
      data.metazoneStandardNames;

  /// Raw metazone-to-daylight-name mapping.
  static Map<String, String> get metazoneDaylightNamesMap =>
      data.metazoneDaylightNames;

  /// Raw timezone-to-fixed-offset mapping.
  static Map<String, Duration> get timezoneFixedOffsetsMap => _fixedOffsets;

  static final Map<String, Duration> _fixedOffsets = Map.unmodifiable({
    for (final MapEntry(:key, :value) in data.etcTimezoneOffsets.entries)
      key: Duration(seconds: value),
  });

  /// Raw timezone-to-exemplar-city mapping, covering every timezone in
  /// [allTimezones].
  ///
  /// Built on first use: most cities are derived from the identifier rather
  /// than stored.
  static Map<String, String> get timezoneCitiesMap => _cities;

  static final Map<String, String> _cities = Map.unmodifiable({
    for (final timezone in data.timezoneToCountry.keys)
      timezone: timezoneCity(timezone)!,
  });

  /// Raw timezone-to-generic-name mapping, with each zone's metazone name
  /// already resolved and zones CLDR names nothing left out.
  static Map<String, String> get timezoneGenericNamesMap => _genericNames;

  static final Map<String, String> _genericNames = _resolvedNames(
    data.timezoneGenericNames,
    data.metazoneGenericNames,
  );

  /// Raw timezone-to-standard-name mapping, resolved as
  /// [timezoneGenericNamesMap] describes.
  static Map<String, String> get timezoneStandardNamesMap => _standardNames;

  static final Map<String, String> _standardNames = _resolvedNames(
    data.timezoneStandardNames,
    data.metazoneStandardNames,
  );

  /// Raw timezone-to-daylight-name mapping, resolved as
  /// [timezoneGenericNamesMap] describes.
  static Map<String, String> get timezoneDaylightNamesMap => _daylightNames;

  static final Map<String, String> _daylightNames = _resolvedNames(
    data.timezoneDaylightNames,
    data.metazoneDaylightNames,
  );

  static Map<String, String> _resolvedNames(
    Map<String, String> zoneNames,
    Map<String, String> metazoneNames,
  ) => Map.unmodifiable({
    for (final timezone in {
      ...data.timezoneToCountry.keys,
      ...data.etcTimezoneOffsets.keys,
    })
      timezone: ?_displayName(timezone, zoneNames, metazoneNames),
  });

  /// IANA Time Zone Database version used to generate the data,
  /// or `null` if unknown.
  static String? get ianaVersion => data.ianaVersion;

  /// CLDR's own version stamp for the Windows timezone mapping, or `null` if
  /// unknown.
  ///
  /// Unrelated to [ianaVersion]: CLDR releases on its own schedule.
  static String? get windowsZonesVersion => data.windowsZonesVersion;

  /// IANA Time Zone Database release the CLDR Windows timezone mapping was
  /// last aligned to, or `null` if unknown.
  ///
  /// Trails [ianaVersion], so CLDR still names some zones by an identifier
  /// IANA has renamed. The generator resolves those, and [windowsToTimezone]
  /// answers with the current identifier either way.
  static String? get windowsZonesIanaVersion => data.windowsZonesIanaVersion;
}
