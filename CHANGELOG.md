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
