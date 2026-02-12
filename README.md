# Timezone Country

Bidirectional mapping between IANA timezone identifiers and ISO 3166-1 country codes (alpha-2 and alpha-3).

Pure Dart. Zero dependencies. O(1) lookups with compile-time `const` maps.

[![pub package](https://img.shields.io/pub/v/timezone_country.svg)](https://pub.dev/packages/timezone_country)
[![CI](https://github.com/DenisNikonov/timezone_country/actions/workflows/ci.yml/badge.svg)](https://github.com/DenisNikonov/timezone_country/actions/workflows/ci.yml)
[![coverage](https://img.shields.io/badge/coverage-100%25-brightgreen.svg)](https://github.com/DenisNikonov/timezone_country)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## Features

- **Timezone → Country**: Get the country code for any IANA timezone
- **Country → Timezones**: Get all timezones for a country
- **Alpha-2 & Alpha-3**: Full ISO 3166-1 support (`US` ↔ `USA`)
- **Legacy Resolution**: Resolve deprecated timezone names (`US/Eastern` → `America/New_York`)
- **Multi-country Timezones**: `Europe/Brussels` → `['BE', 'LU', 'NL']`
- **Country Names**: `'JP'` → `'Japan'` (from [Debian iso-codes](https://salsa.debian.org/iso-codes-team/iso-codes))
- **Flag Emoji**: `'JP'` → `'🇯🇵'` (pure Unicode arithmetic, zero data)
- **String Extensions**: Fluent API on `String` for quick conversions
- **Validation**: Check if a timezone or country code is valid
- **Enumeration**: List all known timezones or country codes

## Installation

```yaml
dependencies:
  timezone_country: ^1.0.0
```

```bash
dart pub add timezone_country
# or for Flutter projects:
flutter pub add timezone_country
```

## Quick Start

```dart
import 'package:timezone_country/timezone_country.dart';

// Timezone → Country
TimezoneConvert.timezoneToCountryCode('Asia/Tokyo');       // 'JP'
TimezoneConvert.timezoneToCountryCode('Asia/Tokyo',
    format: CountryCodeFormat.alpha3);                      // 'JPN'

// Country → Timezones
TimezoneConvert.countryToTimezones('US');                   // ['America/New_York', ...]
TimezoneConvert.countryToTimezones('USA');                  // same — auto-detects format

// Legacy resolution
TimezoneConvert.resolveTimezone('US/Eastern');              // 'America/New_York'

// Alpha-2 ↔ Alpha-3
TimezoneConvert.alpha2ToAlpha3('JP');                       // 'JPN'
TimezoneConvert.alpha3ToAlpha2('JPN');                      // 'JP'

// Country name & flag
TimezoneConvert.countryName('JP');                           // 'Japan'
TimezoneConvert.countryFlag('JP');                           // '🇯🇵'

// String extensions
'Asia/Tokyo'.toCountryCode;                                 // 'JP'
'US'.toTimezones;                                           // ['America/New_York', ...]
'US/Eastern'.toCanonicalTimezone;                           // 'America/New_York'
'JP'.toCountryName;                                         // 'Japan'
'JP'.toFlag;                                                // '🇯🇵'
```

## Usage with Flutter

This is a pure Dart package — it works in any Dart project including Flutter.

Dart's `DateTime.now().timeZoneName` returns abbreviations like `'EST'` or `'CET'`,
not IANA identifiers like `'America/New_York'`. To get the IANA timezone ID from the
device, use [`flutter_timezone`](https://pub.dev/packages/flutter_timezone):

```yaml
dependencies:
  timezone_country: ^1.0.0
  flutter_timezone: ^5.0.1
```

```dart
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone_country/timezone_country.dart';

// Get the device timezone and convert to country code
final timezone = await FlutterTimezone.getLocalTimezone(); // e.g. 'Asia/Tokyo'
final country = TimezoneConvert.timezoneToCountryCode(timezone); // 'JP'

// Or get the alpha-3 code directly
final country3 = TimezoneConvert.timezoneToCountryCode(
  timezone,
  format: CountryCodeFormat.alpha3,
); // 'JPN'

// Get all timezones available on the device
final available = await FlutterTimezone.getAvailableTimezones();
for (final tz in available) {
  print('$tz → ${TimezoneConvert.timezoneToCountryCode(tz)}');
}
```

## API Reference

### TimezoneConvert

| Method | Description |
|--------|-------------|
| `timezoneToCountryCode(tz, {format})` | Primary country for a timezone |
| `timezoneToCountryCodes(tz, {format})` | All countries for a timezone |
| `countryToTimezones(code)` | All timezones for a country (accepts alpha-2 or alpha-3) |
| `resolveTimezone(tz)` | Resolve legacy name to canonical |
| `alpha2ToAlpha3(code)` | Convert `'US'` → `'USA'` |
| `alpha3ToAlpha2(code)` | Convert `'USA'` → `'US'` |
| `countryName(code)` | English name for a country (accepts alpha-2 or alpha-3) |
| `countryFlag(code)` | Flag emoji for a country (accepts alpha-2 or alpha-3) |
| `isValidTimezone(tz)` | Check if timezone exists |
| `isValidCountryCode(code)` | Check if country code exists (alpha-2 or alpha-3) |
| `allTimezones` | Sorted list of all timezone IDs |
| `allCountryCodes` | Sorted list of all alpha-2 codes |
| `allCountryCodesAlpha3` | Sorted list of all alpha-3 codes |
| `ianaVersion` | IANA Time Zone Database version used |

### String Extensions

| Extension | Description |
|-----------|-------------|
| `'Asia/Tokyo'.toCountryCode` | Timezone → alpha-2 |
| `'Asia/Tokyo'.toCountryCodeAlpha3` | Timezone → alpha-3 |
| `'Asia/Tokyo'.toCountryCodes` | Timezone → all alpha-2 codes |
| `'Asia/Tokyo'.toCountryCodesAlpha3` | Timezone → all alpha-3 codes |
| `'JP'.toTimezones` | Country → timezones |
| `'US/Eastern'.toCanonicalTimezone` | Legacy → canonical |
| `'US'.toAlpha3` | Alpha-2 → alpha-3 |
| `'USA'.toAlpha2` | Alpha-3 → alpha-2 |
| `'JP'.toCountryName` | Country code → English name |
| `'JP'.toFlag` | Country code → flag emoji |

### Raw Data Access

For advanced use cases, raw `const` maps are available:

```dart
TimezoneConvert.timezoneToCountryMap;    // Map<String, String>
TimezoneConvert.timezoneToCountriesMap;  // Map<String, List<String>>
TimezoneConvert.countryToTimezonesMap;   // Map<String, List<String>>
TimezoneConvert.legacyTimezoneAliases;   // Map<String, String>
TimezoneConvert.alpha2ToAlpha3Map;       // Map<String, String>
TimezoneConvert.alpha3ToAlpha2Map;       // Map<String, String>
TimezoneConvert.countryNamesMap;         // Map<String, String>
```

## Data Sources

- **IANA Time Zone Database** (`zone1970.tab`, `backward`) — timezone ↔ country mappings and legacy aliases. Check `TimezoneConvert.ianaVersion` for the exact version.
- **ISO 3166-1** via [Debian iso-codes](https://salsa.debian.org/iso-codes-team/iso-codes) — alpha-2 ↔ alpha-3 country code mappings and English country names

All data is embedded as compile-time `const` maps. No network requests, no file I/O, no runtime parsing.

## Notes

- `Etc/*` zones (`Etc/UTC`, `Etc/GMT`) have no country association in the
  IANA database. `isValidTimezone('Etc/UTC')` returns `false` and
  `timezoneToCountryCode('Etc/UTC')` returns `null`. Use `resolveTimezone`
  first if input might be `'UTC'` or a similar alias.

## Comparison

| Feature | timezone_country | timezone_to_country | country_to_timezone |
|---------|:---:|:---:|:---:|
| TZ → Country | Yes | Yes | — |
| Country → TZ | Yes | — | Yes |
| Alpha-3 support | Yes | — | — |
| Country names | Yes | — | — |
| Flag emoji | Yes | — | — |
| Legacy TZ resolution | Yes | — | — |
| Multi-country TZ | Yes | — | — |
| String extensions | Yes | — | — |
| Validation helpers | Yes | — | — |
| Pure Dart | Yes | — | — |
| Zero dependencies | Yes | — | — |
| Const maps (O(1)) | Yes | Yes | — |

## License

MIT
