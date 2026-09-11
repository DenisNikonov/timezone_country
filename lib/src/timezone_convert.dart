import 'dart:math' as math;

import 'country_code_format.dart';
import 'data/alpha2_to_alpha3_data.dart' as data;
import 'data/alpha2_to_numeric_data.dart' as data;
import 'data/alpha3_to_alpha2_data.dart' as data;
import 'data/country_names_data.dart' as data;
import 'data/country_to_timezones_data.dart' as data;
import 'data/iana_version_data.dart' as data;
import 'data/legacy_timezones_data.dart' as data;
import 'data/numeric_to_alpha2_data.dart' as data;
import 'data/timezone_comments_data.dart' as data;
import 'data/timezone_coordinates_data.dart' as data;
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
  static String? windowsToTimezone(String windowsId, {String? countryCode}) {
    final byTerritory = data.windowsToTimezone[windowsId];
    if (byTerritory == null) return null;
    if (countryCode != null) {
      final alpha2 = _alpha2(countryCode);
      if (alpha2 == null) return null;
      final zone = byTerritory[alpha2];
      if (zone != null) return zone;
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

  // Validation

  /// Returns `true` if [timezone] is a known IANA timezone identifier
  /// with a country association, including deprecated aliases such as
  /// `US/Eastern`.
  ///
  /// `Etc/*` zones (`Etc/UTC`, `Etc/GMT`) return `false` because they
  /// have no associated country in the IANA zone tables.
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

  /// All known IANA timezone identifiers, sorted alphabetically.
  static final List<String> allTimezones = List.unmodifiable(
    data.timezoneToCountry.keys.toList()..sort(),
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

  /// Raw country-to-timezones mapping (alpha-2 keys).
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

  /// Raw Windows-identifier-to-territory-to-timezone mapping.
  static Map<String, Map<String, String>> get windowsToTimezoneMap =>
      data.windowsToTimezone;

  /// Raw timezone-to-Windows-identifier mapping.
  static Map<String, String> get timezoneToWindowsMap => data.timezoneToWindows;

  /// IANA Time Zone Database version used to generate the data,
  /// or `null` if unknown.
  static String? get ianaVersion => data.ianaVersion;
}
