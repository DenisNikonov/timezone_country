# Timezone Country

Bidirectional mapping between IANA timezone identifiers and ISO 3166-1 country codes (alpha-2 and alpha-3).

Pure Dart. Zero dependencies. O(1) identifier lookups with compile-time `const` maps.

[![pub package](https://img.shields.io/pub/v/timezone_country.svg)](https://pub.dev/packages/timezone_country)
[![CI](https://github.com/DenisNikonov/timezone_country/actions/workflows/ci.yml/badge.svg)](https://github.com/DenisNikonov/timezone_country/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/DenisNikonov/timezone_country/graph/badge.svg)](https://codecov.io/gh/DenisNikonov/timezone_country)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

No platform channel, no plugin, no network call — a plain Dart library, so it
behaves the same in a server, a CLI, a Flutter app and a release web build.

## Features

- **Timezone → Country**: Get the country code for any IANA timezone
- **Country → Timezones**: Get all timezones for a country
- **Alpha-2 & Alpha-3**: Full ISO 3166-1 support (`US` ↔ `USA`)
- **Country-specific Zones**: `Europe/Oslo` → `'NO'`, `Europe/Copenhagen` → `'DK'`
- **Legacy Resolution**: Deprecated names are resolved on lookup (`US/Eastern` → `'US'`, `Asia/Calcutta` → `'IN'`)
- **Multi-country Timezones**: `Europe/Brussels` → `['BE', 'LU', 'NL']`
- **Country Names**: `'JP'` → `'Japan'` (from [Debian iso-codes](https://salsa.debian.org/iso-codes-team/iso-codes))
- **Flag Emoji**: `'JP'` → `'🇯🇵'` (pure Unicode arithmetic, zero data)
- **Windows Timezones**: `'Tokyo Standard Time'` ↔ `'Asia/Tokyo'` (from [CLDR](https://github.com/unicode-org/cldr))
- **Zone Display Names**: `'America/Denver'` → `'Mountain Standard Time'` (from [CLDR](https://github.com/unicode-org/cldr))
- **Coordinates**: `'Asia/Tokyo'` → latitude and longitude, plus a nearest-city search
- **String Extensions**: Fluent API on `String` for quick conversions
- **Validated Types**: `CountryCode` and `TimezoneId` extension types — parse once, no null checks after
- **Validation**: Check if a timezone or country code is valid
- **Enumeration**: List all known timezones or country codes

## Installation

```yaml
dependencies:
  timezone_country: ^1.2.0
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

// Windows timezones
TimezoneConvert.timezoneToWindows('Asia/Tokyo');            // 'Tokyo Standard Time'
TimezoneConvert.windowsToTimezone('Romance Standard Time'); // 'Europe/Paris'
TimezoneConvert.windowsToTimezone('Romance Standard Time',
    countryCode: 'BE');                                     // 'Europe/Brussels'

// Zone display names
TimezoneConvert.timezoneGenericName('America/Denver');      // 'Mountain Time'
TimezoneConvert.timezoneStandardName('America/Denver');     // 'Mountain Standard Time'
TimezoneConvert.timezoneDaylightName('America/Denver');     // 'Mountain Daylight Time'
TimezoneConvert.timezoneCity('Asia/Ho_Chi_Minh');           // 'Ho Chi Minh City'
TimezoneConvert.primaryTimezone('DE');                      // 'Europe/Berlin'

// Fixed-offset zones
TimezoneConvert.isKnownTimezone('Etc/UTC');                 // true
TimezoneConvert.timezoneFixedOffset('Etc/GMT-1');           // Duration(hours: 1)

// Location
TimezoneConvert.timezoneCoordinates('Asia/Tokyo');          // ≈ (35.65, 139.74)
TimezoneConvert.timezoneComment('America/New_York');        // IANA's description
TimezoneConvert.nearestTimezone(35.68, 139.76);             // 'Asia/Tokyo'

// String extensions
'Asia/Tokyo'.toCountryCode;                                 // 'JP'
'US'.toTimezones;                                           // ['America/New_York', ...]
'US/Eastern'.toCanonicalTimezone;                           // 'America/New_York'
'JP'.toCountryName;                                         // 'Japan'
'JP'.toFlag;                                                // '🇯🇵'
```

## Validated types

Validate a code once and the accessors stop returning `null`. Both are
extension types over `String` — no wrapper object exists at runtime.

```dart
final country = CountryCode.tryParse('usa');  // null if not ISO 3166-1
country?.alpha2;     // 'US'
country?.alpha3;     // 'USA'
country?.name;       // 'United States'
country?.flag;       // '🇺🇸'
country?.timezones;  // [America/New_York, ...]

final zone = TimezoneId.tryParse('US/Eastern');  // null if not a known zone
zone?.id;              // 'America/New_York' — canonical
zone?.country.name;    // 'United States'
zone?.coordinates;     // ≈ (40.71, -74.01)
zone?.comment;         // IANA's description
zone?.windowsId;       // 'Eastern Standard Time'
```

## Usage with Flutter

This is a pure Dart package — it works in any Dart project including Flutter.

Dart's `DateTime.now().timeZoneName` returns abbreviations like `'EST'` or `'CET'`,
not IANA identifiers like `'America/New_York'`. To get the IANA timezone ID from the
device, use [`flutter_timezone`](https://pub.dev/packages/flutter_timezone):

```yaml
dependencies:
  timezone_country: ^1.2.0
  flutter_timezone: ^5.1.0
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

### On the web, without a plugin

Browsers expose the IANA identifier through `Intl`, so no platform channel is
involved and nothing has to be awaited:

```dart
import 'dart:js_interop';

@JS('Intl.DateTimeFormat')
extension type _DateTimeFormat._(JSObject _) implements JSObject {
  external factory _DateTimeFormat();
  external _ResolvedOptions resolvedOptions();
}

extension type _ResolvedOptions._(JSObject _) implements JSObject {
  external String get timeZone;
}

String? localCountryCode() =>
    TimezoneConvert.timezoneToCountryCode(_DateTimeFormat().resolvedOptions().timeZone);
```

Older browsers report a deprecated identifier here — `Asia/Calcutta` rather
than `Asia/Kolkata`, `Europe/Kiev` rather than `Europe/Kyiv`. Both forms
resolve, so no normalisation step is needed.

## Bundle size

Tree shaking works per data file: an app pays only for the maps it reaches.
Measured with `dart run tool/measure_size.dart`, as the difference against an
identical program that does not import the package.

| What the app calls | dart2js | dart2wasm | AOT |
|---|---|---|---|
| `timezoneToCountryCode` | 7.7 KB | 11.1 KB | 18.1 KB |
| `countryName`, `countryFlag` | 6.3 KB | 10.9 KB | 17.6 KB |
| `timezoneToWindows` | 10.3 KB | 15.2 KB | 21.0 KB |
| `timezoneCoordinates` | 13.3 KB | 19.1 KB | 28.1 KB |
| the entire public API | 55.9 KB | 55.1 KB | 93.5 KB |

Gzipped, which is what a browser downloads. Re-run the tool to check these
against the current data rather than trusting the table.

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
| `countryNumericCode(code)` | Convert `'US'` → `'840'` |
| `numericToCountryCode(num, {format})` | Convert `'840'` → `'US'` |
| `countryName(code)` | English name for a country (accepts alpha-2 or alpha-3) |
| `countryFlag(code)` | Flag emoji for a country (accepts alpha-2 or alpha-3) |
| `countryCodeFromFlag(flag, {format})` | Flag emoji → country code |
| `timezoneToWindows(tz)` | IANA → Windows timezone identifier |
| `windowsToTimezone(id, {countryCode})` | Windows timezone identifier → IANA |
| `timezoneCity(tz)` | The zone's exemplar city in English |
| `timezoneGenericName(tz)` | Location-independent name, e.g. `'Mountain Time'` |
| `timezoneStandardName(tz)` | Standard-time name, e.g. `'Mountain Standard Time'` |
| `timezoneDaylightName(tz)` | Daylight-time name, `null` where the zone has none |
| `metazone(tz)` | CLDR metazone the zone currently belongs to |
| `primaryTimezone(code)` | The country's principal zone, `null` when unranked |
| `isKnownTimezone(tz)` | Known identifier, `Etc/*` and aliases included |
| `timezoneFixedOffset(tz)` | Fixed offset of an `Etc/*` zone, `null` otherwise |
| `windowsToTimezones(id, {countryCode})` | Every IANA zone CLDR groups under a Windows ID |
| `windowsZonesVersion` | CLDR's version stamp for the Windows mapping |
| `windowsZonesIanaVersion` | IANA release that mapping was aligned to |
| `timezoneCoordinates(tz)` | Latitude and longitude of the zone's city |
| `timezoneComment(tz)` | IANA's English description of the zone |
| `nearestTimezone(lat, lon, {countryCode})` | Zone with the closest city |
| `isValidTimezone(tz)` | Check if timezone exists (legacy names included) |
| `isValidCountryCode(code)` | Check if a country code has at least one timezone |
| `isKnownCountryCode(code)` | Check if a country code is in ISO 3166-1 |
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
| `'🇯🇵'.fromFlag` | Flag emoji → country code |
| `'JP'.toNumericCode` | Country code → ISO 3166-1 numeric |
| `'392'.fromNumericCode` | ISO 3166-1 numeric → country code |

The `String` getters cover the country-code mappings only. Windows identifiers
and coordinates are reachable through `TimezoneConvert` or the validated types.

### CountryCode and TimezoneId

| Member | Description |
|--------|-------------|
| `CountryCode.tryParse(code)` | Alpha-2 or alpha-3, any case → `CountryCode?` |
| `.alpha2` `.alpha3` `.numeric` | The three ISO 3166-1 forms |
| `.name` `.flag` | English name, flag emoji |
| `.timezones` | `List<TimezoneId>`, empty if the country has none |
| `TimezoneId.tryParse(tz)` | Known identifier → `TimezoneId?`, canonicalised |
| `.id` | The canonical IANA identifier |
| `.country` `.countries` | Primary country, all countries |
| `.coordinates` `.comment` | Location, IANA's description |
| `.windowsId` | Windows timezone identifier, `null` if CLDR omits the zone |

Both are extension types over `String`: they cost nothing at runtime and print
as the underlying code, but they are distinct static types. Pass `.alpha2` or
`.id` where a `String` is expected.

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
TimezoneConvert.alpha2ToNumericMap;      // Map<String, String>
TimezoneConvert.numericToAlpha2Map;      // Map<String, String>
TimezoneConvert.timezoneCommentsMap;     // Map<String, String>
TimezoneConvert.timezoneCoordinatesMap;  // Map<String, (double, double)>
TimezoneConvert.timezoneToWindowsMap;    // Map<String, String>
TimezoneConvert.windowsToTimezoneMap;    // Map<String, Map<String, String>>
```

These maps and the lists returned by the API are unmodifiable. Mutating them
throws `UnsupportedError`; copy first.

## Data Sources

- **IANA Time Zone Database** (`zone1970.tab`, `zone.tab`, `backward`) — timezone ↔ country mappings and legacy aliases. Check `TimezoneConvert.ianaVersion` for the exact version.
  Both zone tables are used: `zone1970.tab` supplies the multi-country lists, `zone.tab` supplies the country-specific zones that `zone1970.tab` merges away (`Europe/Oslo`, `Europe/Copenhagen`, and others).
  Column 2 of the zone tables supplies the coordinates, column 4 the English descriptions.
- **ISO 3166-1** via [Debian iso-codes](https://salsa.debian.org/iso-codes-team/iso-codes) — alpha-2 ↔ alpha-3 ↔ numeric country code mappings and English country names
- **CLDR** [`windowsZones.xml`](https://github.com/unicode-org/cldr/blob/main/common/supplemental/windowsZones.xml) — Windows ↔ IANA timezone identifiers. Released on its own schedule, independent of the IANA version, and pinned to a release tag rather than the development branch. The mapping states the IANA release it was itself aligned to; read it from `windowsZonesIanaVersion`, and expect it to trail `ianaVersion` by years.
- **CLDR** `metaZones.xml` and `common/main/en.xml` — English zone display names, exemplar cities, and the primary zone of a country.
- **CLDR** `common/bcp47/timezone.xml` — which IANA zone each CLDR spelling stands for. `backward` may only link to a canonical zone, so it sends `Atlantic/Jan_Mayen` to `Europe/Berlin` and `Pacific/Yap` to `Pacific/Port_Moresby`; this table names the zone in the right country.
- **IANA `etcetera`** — the `Etc/*` fixed-offset zones. These carry no country, so they are reachable through `isKnownTimezone` and `timezoneFixedOffset` but stay out of `allTimezones`.

All data is embedded as compile-time `const` maps. No network requests, no file I/O, no runtime parsing.

## Notes

- `Etc/*` zones (`Etc/UTC`, `Etc/GMT`) have no country association in the
  IANA database. `isValidTimezone('Etc/UTC')` returns `false` and
  `timezoneToCountryCode('Etc/UTC')` returns `null`. Use `isKnownTimezone` to
  tell an unrecognised string apart from a real zone that simply has no
  country — devices do report these. `timezoneFixedOffset` gives the offset
  with its true sign, not the inverted one inside the identifier.
- The display names are English only, and every one of them is nullable. A
  zone with no current metazone has no generic, standard or daylight name; a
  zone that never leaves standard time has no daylight name. Nothing is
  synthesised to fill a gap, so a `null` means CLDR has no answer. Short
  abbreviations are deliberately not exposed: CLDR supplies them for only a
  handful of metazones in English, and they are ambiguous across regions.
- `isValidCountryCode` means "has at least one IANA timezone", which is narrower
  than ISO 3166-1 membership. Use `isKnownCountryCode` for the latter.
- `nearestTimezone` compares against the coordinates IANA gives each zone —
  the city the identifier is named after, not a polygon. It answers "which of
  these zones is closest", not "which zone contains this point", and the two
  disagree often — including inside a single country, so `countryCode` narrows
  the error without removing it. Treat the result as a guess.
- Some zones serve several countries because IANA merged them. Use
  `timezoneToCountryCodes` for the full list, and prefer the country-specific
  identifier (`Europe/Oslo` over `Europe/Berlin`) when you know the country.
- `allTimezones` lists one identifier per zone, with deprecated aliases and the
  `Etc/*` zones excluded. It matches the primary identifiers ECMA-402 defines,
  including keeping two zones apart where they serve different countries
  despite agreeing on the clock (`Europe/Oslo` and `Europe/Berlin`). Browsers
  expose the same set through `Intl.supportedValuesOf('timeZone')`, but engines
  are slow to follow IANA renames and still emit the superseded spelling, so
  the two lists disagree on the names even where they agree on the zones.

## Non-goals

This package maps identifiers. It does not do:

- Time arithmetic, UTC offsets or DST — use [`timezone`](https://pub.dev/packages/timezone).
  An embedded offset table would ship stale: offsets move with DST and on
  political notice. The `Etc/*` zones are the exception, being fixed by
  definition.
- Localized country names — English only. Use [`common_locale_data`](https://pub.dev/packages/common_locale_data) or [`country_codes`](https://pub.dev/packages/country_codes).
- Dial codes — use [`country_codes`](https://pub.dev/packages/country_codes).
- Timezone boundary lookup from a coordinate — that needs shapefiles. `nearestTimezone` is a nearest-city approximation, not a substitute.
- Wider country data (currencies, capitals, subdivisions) — use [`sealed_countries`](https://pub.dev/packages/sealed_countries).
- Reading the device timezone — needs a platform channel. Use [`flutter_timezone`](https://pub.dev/packages/flutter_timezone) and pass the result in, as shown above.

## License

MIT
