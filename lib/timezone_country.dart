/// Bidirectional mapping between IANA timezone identifiers and
/// ISO 3166-1 country codes (alpha-2 and alpha-3).
///
/// Provides O(1) lookups in both directions using compile-time const maps.
/// Pure Dart with zero runtime dependencies.
///
/// ```dart
/// import 'package:timezone_country/timezone_country.dart';
///
/// // Timezone to country
/// TimezoneConvert.timezoneToCountryCode('Asia/Tokyo'); // 'JP'
///
/// // Country to timezones
/// TimezoneConvert.countryToTimezones('US'); // ['America/New_York', ...]
///
/// // Extension methods
/// 'Asia/Tokyo'.toCountryCode; // 'JP'
/// 'US'.toTimezones; // ['America/New_York', ...]
/// ```
library;

export 'src/country_code_format.dart';
export 'src/extensions.dart';
export 'src/timezone_convert.dart';
