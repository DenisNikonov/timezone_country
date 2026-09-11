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

  // Country-specific zones
  print(TimezoneConvert.timezoneToCountryCode('Europe/Oslo')); // NO
  print(TimezoneConvert.timezoneToCountryCode('Europe/Copenhagen')); // DK

  // Legacy resolution
  print(TimezoneConvert.resolveTimezone('US/Eastern')); // America/New_York
  print(TimezoneConvert.timezoneToCountryCode('US/Eastern')); // US
  print(TimezoneConvert.timezoneToCountryCode('Asia/Calcutta')); // IN

  // Alpha-2 ↔ Alpha-3 ↔ numeric
  print(TimezoneConvert.alpha2ToAlpha3('JP')); // JPN
  print(TimezoneConvert.alpha3ToAlpha2('JPN')); // JP
  print(TimezoneConvert.countryNumericCode('JP')); // 392
  print(TimezoneConvert.numericToCountryCode('392')); // JP

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
  print(TimezoneConvert.isValidCountryCode('BV')); // false — no IANA timezone
  print(TimezoneConvert.isKnownCountryCode('BV')); // true — valid ISO 3166-1

  // String Extensions
  print('Europe/London'.toCountryCode); // GB
  print('Europe/London'.toCountryCodeAlpha3); // GBR
  print('US'.toTimezones); // [America/New_York, ...]
  print('US/Eastern'.toCanonicalTimezone); // America/New_York
  print('GB'.toAlpha3); // GBR
  print('GBR'.toAlpha2); // GB
  print('GB'.toFlag?.fromFlag); // GB

  // Windows timezones
  print(TimezoneConvert.timezoneToWindows('Asia/Tokyo')); // Tokyo Standard Time
  print(
    TimezoneConvert.windowsToTimezone('Romance Standard Time'),
  ); // Europe/Paris
  print(
    TimezoneConvert.windowsToTimezone(
      'Romance Standard Time',
      countryCode: 'BE',
    ),
  ); // Europe/Brussels

  // Location
  print(
    TimezoneConvert.timezoneCoordinates('Asia/Tokyo'),
  ); // latitude, longitude
  print(
    TimezoneConvert.timezoneComment('America/New_York'),
  ); // IANA's description of the zone
  print(TimezoneConvert.nearestTimezone(35.68, 139.76)); // Asia/Tokyo

  // Validated types — parse once, no null checks after
  final country = CountryCode.tryParse('usa')!;
  print('${country.alpha2} ${country.alpha3} ${country.name} ${country.flag}');
  final zone = TimezoneId.tryParse('US/Eastern')!;
  print('${zone.id} ${zone.country.name} ${zone.windowsId}');

  // Enumeration
  print('Timezones: ${TimezoneConvert.allTimezones.length}');
  print('Countries (alpha-2): ${TimezoneConvert.allCountryCodes.length}');
  print('Countries (alpha-3): ${TimezoneConvert.allCountryCodesAlpha3.length}');
}
