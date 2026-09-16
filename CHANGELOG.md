## 1.2.0

Display names and fixed-offset zones. No method changes signature, and the new
data tree-shakes out of an app that does not call it. Five deprecated aliases
now answer with a different country; see Fixed.

### Added

- **English zone display names** from CLDR: `timezoneCity`,
  `timezoneGenericName`, `timezoneStandardName`, `timezoneDaylightName` and
  `metazone`, plus the matching accessors on `TimezoneId`. A timezone picker
  can show "Mountain Standard Time" instead of `America/Denver`.
  Every accessor is nullable and nothing is synthesised to fill a gap: 8
  timezones have no current metazone, 143 have no generic name, and 141 have
  no daylight name. Short abbreviations are deliberately not exposed — CLDR
  supplies them for only a handful of metazones in English and they are
  ambiguous across regions.
- **`primaryTimezone(countryCode)`** and `CountryCode.primaryTimezone`, from
  CLDR's designation or from the single zone the country owns. `null` for the
  20 countries that own several zones and that CLDR does not rank; it does not
  guess.
- **`Etc/*` fixed-offset zones** from the IANA `etcetera` file. Devices report
  these, and until now they were indistinguishable from a typo.
  `isKnownTimezone` tells an
  unrecognised string apart from a real zone with no country;
  `timezoneFixedOffset` returns the offset with its true sign rather than the
  inverted one inside the identifier. `resolveTimezone('GMT')` now resolves.
  These zones stay out of `allTimezones` and still have no country, so
  `isValidTimezone` and `timezoneToCountryCode` are unchanged.
- **`windowsToTimezones`** and `windowsToTimezonesMap`, exposing every IANA
  zone CLDR groups under one Windows identifier. `windowsToTimezone` returns
  the same single zone as before.
- **`windowsZonesVersion` and `windowsZonesIanaVersion`**, recording which
  CLDR mapping is embedded and which IANA release it was aligned to. The
  latter trails `ianaVersion` by years, which is why deprecated identifiers in
  the mapping have to be resolved.

### Changed

- The CLDR download is pinned to a release tag instead of the development
  branch, so an unreleased upstream edit can no longer reach a published
  release. Every version up to 1.1.1 took CLDR from the development branch.
  The embedded Windows mapping is unaffected by the pin.
- `countryToTimezones` documents its actual ordering: zones the country owns
  first, then zones it shares, each group in IANA zone-table row order. The
  first entry is not the country's principal zone — use `primaryTimezone`.

### Fixed

- **Five deprecated aliases named the wrong country.** `backward` may only
  link to a canonical zone, so an alias of a zone the 1970 merge collapsed
  lands on the merged zone abroad. CLDR's `bcp47/timezone.xml` says which zone
  each spelling really stands for, and it is now consulted first:

  | Identifier | Was | Now |
  | --- | --- | --- |
  | `Atlantic/Jan_Mayen` | `Europe/Berlin`, DE | `Arctic/Longyearbyen`, SJ |
  | `Pacific/Yap` | `Pacific/Port_Moresby`, PG | `Pacific/Chuuk`, FM |
  | `Africa/Timbuktu` | `Africa/Abidjan`, CI | `Africa/Bamako`, ML |
  | `Antarctica/South_Pole` | `Pacific/Auckland`, NZ | `Antarctica/McMurdo`, AQ |
  | `America/Coral_Harbour` | `America/Panama`, PA | `America/Atikokan`, CA |

  Only identifiers IANA already treats as aliases are re-pointed, and only at
  zones the zone tables list. The same table gives `America/Atikokan` the
  display names it was missing.
- **`CST6CDT`, `EST5EDT`, `MST7MDT` and `PST8PDT` no longer appear and
  disappear with the tzdb release.** tzdb has moved them between `Link` and
  `Zone` form and back; 2026d settles on `Zone`. Both forms are now read, so
  `isKnownTimezone` stays `true` either way. They have no country and
  `resolveTimezone` returns them unchanged, because the zones are ahistorical
  and are not the same as `America/Chicago` and its siblings.
## 1.1.1

- Updated embedded timezone and country data (2026-09-12). IANA Time Zone Database 2026d, CLDR c33a1f0.
- 418 timezones, 247 countries.

## 1.1.0

Country accuracy release. Three separate places collapsed a country-specific
zone onto the shared zone IANA merged it into, so lookups returned a
neighbouring country. All three are fixed and pinned by tests.

### Added

- **Windows timezone identifiers** from CLDR: `timezoneToWindows`,
  `windowsToTimezone`, plus the `timezoneToWindowsMap` and
  `windowsToTimezoneMap` raw maps. Every known zone but `Antarctica/Troll`,
  which CLDR omits, has a Windows identifier.
- **Zone locations and descriptions** from the IANA zone tables:
  `timezoneCoordinates`, `timezoneComment`, `nearestTimezone`, and the
  `timezoneCoordinatesMap` and `timezoneCommentsMap` raw maps.
  `nearestTimezone` is a nearest-city search, not a boundary lookup — see the
  README notes before relying on it.
- **`CountryCode` and `TimezoneId` extension types.** `tryParse` validates
  once and the accessors are non-nullable afterwards. No wrapper object exists
  at runtime. The `String` API is unchanged.
- **ISO 3166-1 numeric codes**: `countryNumericCode`, `numericToCountryCode`,
  `alpha2ToNumericMap`, `numericToAlpha2Map`, `toNumericCode`,
  `fromNumericCode`.
- **`countryCodeFromFlag`** and the `fromFlag` extension, the inverse of
  `countryFlag`.
- **`isKnownCountryCode`** for ISO 3166-1 membership. `isValidCountryCode`
  keeps its narrower meaning, "has at least one timezone".
- 106 country-specific timezone identifiers from `zone.tab` (`Europe/Oslo`,
  `Europe/Copenhagen`, `Europe/Bratislava` and others). They returned `null`
  before. 418 timezones, 247 countries.

### Fixed

- **Country-specific zones returned the wrong country.** Resolving them
  through `backward` first gave `Europe/Copenhagen` → `'DE'` instead of
  `'DK'`. Identifiers that carry a country of their own are no longer
  resolved.
- **Aliases flattened by IANA returned a foreign country.** `backward`
  collapses link chains and records the real target in a `#=` comment, which
  the generator ignored: `timezoneToCountryCode('Iceland')` was `'CI'`,
  `'Africa/Asmera'` was `'KE'`, `'America/Virgin'` was `'PR'`,
  `'Pacific/Ponape'` was `'SB'`, `'Pacific/Truk'` was `'PG'`. The Windows
  mapping for `ER` and `FM` followed the same error.
- **`countryToTimezones` ordering.** A country listed only as a secondary code
  in the zone tables got a foreign zone first (`'UA'` → `Europe/Simferopol`).
  Each country's own zones now come first.
- **Country names inverted by ISO** are straightened
  ("Congo, The Democratic Republic of the" → "Democratic Republic of the
  Congo"). List-form names such as "Bonaire, Sint Eustatius and Saba" are left
  alone, and a new inverted name is reported as a CI warning.

### Changed

- **Deprecated identifiers now resolve on lookup.** `timezoneToCountryCode('US/Eastern')`
  returns `'US'` and `isValidTimezone('Asia/Calcutta')` returns `true`. `Etc/*`
  zones still have no country.
- **`resolveTimezone` answers differently for five aliases** — `Iceland`,
  `Africa/Asmera`, `America/Virgin`, `Pacific/Ponape`, `Pacific/Truk` — which
  now resolve to the zone their `#=` comment names. The previous answers named
  a zone in another country.
- **`CST6CDT`, `EST5EDT`, `MST7MDT` and `PST8PDT` are no longer legacy
  aliases.** IANA defines them as zones, not links, and they have no country.
- Raised the SDK floor to `^3.8.0`; `^3.7.0` was unresolvable against
  `lints ^6.0.0`.
- Corrected the country counts in the 1.0.1 and 1.0.2 entries below. The
  generator counted wrapped lines, not map keys.

### Tooling

- `tool/generate_data.dart` takes `zone.tab` and CLDR `windowsZones.xml` as
  extra inputs, and aborts on implausibly small input instead of emitting
  empty data.
- Parsing moved to `tool/parse_source_data.dart`, which is pure and covered by
  `test/generator_test.dart`.
- The release tag is pushed after CI passes, not on the push to `main`.

## 1.0.2

- Updated IANA Time Zone Database to 2026c (2026-09-10).
- 312 timezones, 247 countries.

## 1.0.1

- Updated IANA Time Zone Database to 2026b (2026-06-18).
- 312 timezones, 247 countries.

## 1.0.0

- Bidirectional mapping between IANA timezone IDs and ISO 3166-1 country codes.
- Support for both alpha-2 (`US`) and alpha-3 (`USA`) country code formats.
- Legacy timezone resolution (`US/Eastern` → `America/New_York`).
- Multi-country timezone support (`Europe/Brussels` → `['BE', 'LU', 'NL']`).
- Country names from [Debian iso-codes](https://salsa.debian.org/iso-codes-team/iso-codes) (`'JP'` → `'Japan'`).
- Flag emoji from country code (`'JP'` → flag emoji, pure Unicode arithmetic).
- String extensions for fluent conversions.
- Validation and enumeration helpers.
- O(1) lookups via compile-time `const` maps, zero runtime dependencies.
