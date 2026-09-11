import 'timezone_convert.dart';

/// A country code that is known to be valid, held in alpha-2 form.
///
/// Validate once with [tryParse], then pass the result around instead of a
/// bare [String]: the getters below cannot return `null` for a code that
/// exists in ISO 3166-1.
///
/// ```dart
/// final country = CountryCode.tryParse('usa');
/// country?.alpha2; // 'US'
/// country?.name;   // 'United States'
/// ```
///
/// This is a [String] at runtime, so it costs nothing and prints as the
/// code itself, but it is a distinct static type: pass [alpha2] where a
/// [String] is expected.
extension type const CountryCode._(String alpha2) {
  /// Returns a [CountryCode] for [code], which may be alpha-2 or alpha-3 in
  /// either letter case, or `null` if it is not in ISO 3166-1.
  static CountryCode? tryParse(String code) {
    final normalized = code.toUpperCase();
    final alpha2 = TimezoneConvert.alpha3ToAlpha2(normalized) ?? normalized;
    return TimezoneConvert.isKnownCountryCode(alpha2)
        ? CountryCode._(alpha2)
        : null;
  }

  /// The ISO 3166-1 alpha-3 code.
  String get alpha3 => TimezoneConvert.alpha2ToAlpha3(alpha2)!;

  /// The ISO 3166-1 numeric code, zero-padded to three digits.
  String get numeric => TimezoneConvert.countryNumericCode(alpha2)!;

  /// The English country name.
  String get name => TimezoneConvert.countryName(alpha2)!;

  /// The flag emoji.
  String get flag => TimezoneConvert.countryFlag(alpha2)!;

  /// Every IANA timezone in this country, empty for the few ISO 3166-1
  /// countries that have none.
  List<TimezoneId> get timezones => List.unmodifiable([
    for (final id in TimezoneConvert.countryToTimezones(alpha2) ?? const [])
      TimezoneId._(id),
  ]);
}

/// An IANA timezone identifier that is known to be valid and canonical.
///
/// [tryParse] resolves deprecated aliases, so `'US/Eastern'` and
/// `'America/New_York'` both yield the canonical identifier.
///
/// ```dart
/// final zone = TimezoneId.tryParse('US/Eastern');
/// zone?.id;              // 'America/New_York'
/// zone?.country.alpha2;  // 'US'
/// ```
///
/// This is a [String] at runtime, so it costs nothing and prints as the
/// identifier itself, but it is a distinct static type: pass [id] where a
/// [String] is expected.
extension type const TimezoneId._(String id) {
  /// Returns a [TimezoneId] for [timezone], or `null` if it is not a known
  /// identifier with a country association.
  static TimezoneId? tryParse(String timezone) {
    // Resolving unconditionally would collapse the country-specific zones
    // onto the shared zone they link to, in another country.
    final canonical = TimezoneConvert.timezoneToCountryMap.containsKey(timezone)
        ? timezone
        : TimezoneConvert.resolveTimezone(timezone);
    return TimezoneConvert.timezoneToCountryMap.containsKey(canonical)
        ? TimezoneId._(canonical)
        : null;
  }

  /// The primary country.
  CountryCode get country =>
      CountryCode._(TimezoneConvert.timezoneToCountryCode(id)!);

  /// Every country this zone serves, the primary one first.
  List<CountryCode> get countries => List.unmodifiable([
    for (final code in TimezoneConvert.timezoneToCountryCodes(id)!)
      CountryCode._(code),
  ]);

  /// The English description IANA gives this zone, or `null` if it has none.
  String? get comment => TimezoneConvert.timezoneComment(id);

  /// The latitude and longitude in degrees of this zone's principal location.
  (double latitude, double longitude) get coordinates =>
      TimezoneConvert.timezoneCoordinates(id)!;

  /// The Windows timezone identifier, or `null` if CLDR has no equivalent.
  String? get windowsId => TimezoneConvert.timezoneToWindows(id);
}
