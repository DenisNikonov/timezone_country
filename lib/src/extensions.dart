import 'country_code_format.dart';
import 'timezone_convert.dart';

/// Convenience extensions for timezone/country string conversions.
extension TimezoneCountryStringExtension on String {
  /// Primary alpha-2 country code for this timezone, or `null`.
  ///
  /// ```dart
  /// 'Asia/Tokyo'.toCountryCode // 'JP'
  /// ```
  String? get toCountryCode => TimezoneConvert.timezoneToCountryCode(this);

  /// Primary alpha-3 country code for this timezone, or `null`.
  String? get toCountryCodeAlpha3 => TimezoneConvert.timezoneToCountryCode(
    this,
    format: CountryCodeFormat.alpha3,
  );

  /// All alpha-2 country codes sharing this timezone, or `null`.
  List<String>? get toCountryCodes =>
      TimezoneConvert.timezoneToCountryCodes(this);

  /// All alpha-3 country codes sharing this timezone, or `null`.
  List<String>? get toCountryCodesAlpha3 =>
      TimezoneConvert.timezoneToCountryCodes(
        this,
        format: CountryCodeFormat.alpha3,
      );

  /// IANA timezone identifiers for this country code, or `null`.
  ///
  /// ```dart
  /// 'JP'.toTimezones  // ['Asia/Tokyo']
  /// 'USA'.toTimezones // ['America/New_York', ...]
  /// ```
  List<String>? get toTimezones => TimezoneConvert.countryToTimezones(this);

  /// Canonical IANA form of this timezone (resolves legacy names).
  ///
  /// ```dart
  /// 'US/Eastern'.toCanonicalTimezone // 'America/New_York'
  /// ```
  String get toCanonicalTimezone => TimezoneConvert.resolveTimezone(this);

  /// Converts alpha-2 to alpha-3, or `null` if unknown.
  ///
  /// ```dart
  /// 'US'.toAlpha3 // 'USA'
  /// ```
  String? get toAlpha3 => TimezoneConvert.alpha2ToAlpha3(this);

  /// Converts alpha-3 to alpha-2, or `null` if unknown.
  ///
  /// ```dart
  /// 'USA'.toAlpha2 // 'US'
  /// ```
  String? get toAlpha2 => TimezoneConvert.alpha3ToAlpha2(this);

  /// English country name for this country code, or `null`.
  ///
  /// Accepts both alpha-2 and alpha-3 codes.
  ///
  /// ```dart
  /// 'JP'.toCountryName  // 'Japan'
  /// 'USA'.toCountryName // 'United States'
  /// ```
  String? get toCountryName => TimezoneConvert.countryName(this);

  /// Flag emoji for this country code, or `null`.
  ///
  /// Accepts both alpha-2 and alpha-3 codes.
  ///
  /// ```dart
  /// 'JP'.toFlag  // '\u{1f1ef}\u{1f1f5}'
  /// 'USA'.toFlag // '\u{1f1fa}\u{1f1f8}'
  /// ```
  String? get toFlag => TimezoneConvert.countryFlag(this);
}
