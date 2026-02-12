import 'country_code_format.dart';
import 'data/alpha2_to_alpha3_data.dart' as data;
import 'data/alpha3_to_alpha2_data.dart' as data;
import 'data/country_names_data.dart' as data;
import 'data/country_to_timezones_data.dart' as data;
import 'data/iana_version_data.dart' as data;
import 'data/legacy_timezones_data.dart' as data;
import 'data/timezone_to_countries_data.dart' as data;
import 'data/timezone_to_country_data.dart' as data;

/// Bidirectional mapping between IANA timezone identifiers and
/// ISO 3166-1 country codes.
///
/// All lookups are O(1) using compile-time const [Map]s.
abstract final class TimezoneConvert {
  // Timezone → Country

  /// Returns the primary country code for [timezone].
  ///
  /// The primary country is the most populous country using this timezone,
  /// as defined by the IANA timezone database.
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
    final alpha2 = data.timezoneToCountry[timezone];
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
  /// Returns `null` if [timezone] is not found.
  static List<String>? timezoneToCountryCodes(
    String timezone, {
    CountryCodeFormat format = CountryCodeFormat.alpha2,
  }) {
    final codes = data.timezoneToCountries[timezone];
    if (codes == null) return null;
    return switch (format) {
      CountryCodeFormat.alpha2 => codes,
      CountryCodeFormat.alpha3 => [
        for (final code in codes)
          if (data.alpha2ToAlpha3[code] case final alpha3?) alpha3,
      ],
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
    final normalized = countryCode.toUpperCase();
    final alpha2 = switch (normalized.length) {
      2 => normalized,
      3 => data.alpha3ToAlpha2[normalized],
      _ => null,
    };
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
    final normalized = countryCode.toUpperCase();
    final alpha2 = switch (normalized.length) {
      2 => normalized,
      3 => data.alpha3ToAlpha2[normalized],
      _ => null,
    };
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
    final normalized = countryCode.toUpperCase();
    final alpha2 = switch (normalized.length) {
      2 => normalized,
      3 => data.alpha3ToAlpha2[normalized],
      _ => null,
    };
    if (alpha2 == null || !data.alpha2ToAlpha3.containsKey(alpha2)) return null;
    // Each letter maps to a Regional Indicator Symbol: A=0x1F1E6, B=0x1F1E7, ...
    const offset = 0x1F1E6 - 0x41; // 'A' = 0x41
    return String.fromCharCodes([
      alpha2.codeUnitAt(0) + offset,
      alpha2.codeUnitAt(1) + offset,
    ]);
  }

  // Validation

  /// Returns `true` if [timezone] is a known IANA timezone identifier
  /// with a country association.
  ///
  /// `Etc/*` zones (`Etc/UTC`, `Etc/GMT`) return `false` because they
  /// have no associated country in `zone1970.tab`.
  static bool isValidTimezone(String timezone) =>
      data.timezoneToCountry.containsKey(timezone);

  /// Returns `true` if [countryCode] has at least one associated timezone.
  ///
  /// Accepts both alpha-2 and alpha-3 formats (case-insensitive).
  static bool isValidCountryCode(String countryCode) {
    final normalized = countryCode.toUpperCase();
    return switch (normalized.length) {
      2 => data.countryToTimezones.containsKey(normalized),
      3 =>
        data.alpha3ToAlpha2[normalized] != null &&
            data.countryToTimezones.containsKey(
              data.alpha3ToAlpha2[normalized],
            ),
      _ => false,
    };
  }

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

  /// IANA Time Zone Database version used to generate the data,
  /// or `null` if unknown.
  static String? get ianaVersion => data.ianaVersion;
}
