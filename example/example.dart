import 'package:timezone_country/timezone_country.dart';

void main() {
  // Timezone → Country
  print(TimezoneConvert.timezoneToCountryCode('Asia/Tokyo')); // JP
  print(
    TimezoneConvert.timezoneToCountryCode(
      'Asia/Tokyo',
      format: CountryCodeFormat.alpha3,
    ),
  ); // JPN

  // Multi-country timezone
  print(
    TimezoneConvert.timezoneToCountryCodes('Europe/Brussels'),
  ); // [BE, LU, NL]

  // Country → Timezones
  print(TimezoneConvert.countryToTimezones('JP')); // [Asia/Tokyo]
  print(TimezoneConvert.countryToTimezones('USA')); // [America/New_York, ...]

  // Legacy Resolution
  final canonical = TimezoneConvert.resolveTimezone('US/Eastern');
  print(canonical); // America/New_York
  print(TimezoneConvert.timezoneToCountryCode(canonical)); // US

  // Alpha-2 ↔ Alpha-3
  print(TimezoneConvert.alpha2ToAlpha3('JP')); // JPN
  print(TimezoneConvert.alpha3ToAlpha2('JPN')); // JP

  // Country Name & Flag
  print(TimezoneConvert.countryName('JP')); // Japan
  print(TimezoneConvert.countryName('USA')); // United States
  print(TimezoneConvert.countryFlag('JP')); // flag emoji
  print(TimezoneConvert.countryFlag('GB')); // flag emoji
  print('DE'.toCountryName); // Germany
  print('DE'.toFlag); // flag emoji

  // Validation
  print(TimezoneConvert.isValidTimezone('Asia/Tokyo')); // true
  print(TimezoneConvert.isValidTimezone('Invalid/Zone')); // false
  print(TimezoneConvert.isValidCountryCode('US')); // true
  print(TimezoneConvert.isValidCountryCode('USA')); // true

  // String Extensions
  print('Europe/London'.toCountryCode); // GB
  print('Europe/London'.toCountryCodeAlpha3); // GBR
  print('US'.toTimezones); // [America/New_York, ...]
  print('US/Eastern'.toCanonicalTimezone); // America/New_York
  print('GB'.toAlpha3); // GBR
  print('GBR'.toAlpha2); // GB

  // Enumeration
  print('Timezones: ${TimezoneConvert.allTimezones.length}');
  print('Countries (alpha-2): ${TimezoneConvert.allCountryCodes.length}');
  print('Countries (alpha-3): ${TimezoneConvert.allCountryCodesAlpha3.length}');
}
