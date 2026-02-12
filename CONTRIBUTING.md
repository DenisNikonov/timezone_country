# Contributing

Contributions are welcome! Here's how to get started.

## Setup

```bash
git clone https://github.com/DenisNikonov/timezone_country.git
cd timezone_country
dart pub get
```

## Development

### Running tests

```bash
dart test
```

### Checking code quality

```bash
dart analyze --fatal-infos
dart format --output=none --set-exit-if-changed .
```

### Regenerating data files

Data files in `lib/src/data/` are generated from the IANA Time Zone Database
and [Debian iso-codes](https://salsa.debian.org/iso-codes-team/iso-codes).
To regenerate manually:

```bash
# Download latest IANA data
curl -sL https://raw.githubusercontent.com/eggert/tz/main/zone1970.tab -o /tmp/zone1970.tab
curl -sL https://raw.githubusercontent.com/eggert/tz/main/backward -o /tmp/backward

# Download ISO 3166-1 data (country codes and names)
curl -sL https://salsa.debian.org/iso-codes-team/iso-codes/-/raw/main/data/iso_3166-1.json -o /tmp/iso_3166-1.json

# Generate (optionally specify IANA version)
dart run tool/generate_data.dart /tmp/zone1970.tab /tmp/backward /tmp/iso_3166-1.json --version 2024b
```

> **Note:** Data updates are handled automatically by a daily GitHub Action.
> Manual regeneration is only needed for local development or testing.

## Pull requests

1. Fork the repo and create a feature branch.
2. Make your changes.
3. Ensure `dart analyze`, `dart format`, and `dart test` all pass.
4. Keep commits focused — one logical change per commit.
5. Update `CHANGELOG.md` if adding user-facing changes.
6. Open a PR against `main`.

## Commit messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add timezone search by offset
fix: handle empty string in countryToTimezones
chore: update IANA data to 2024b
docs: clarify Etc/UTC behavior in README
test: add edge case for Antarctica timezones
```

## Code style

- Follow `package:lints/recommended.yaml` (enforced by CI).
- Use Dart 3.7+ features where appropriate (switch expressions, patterns, etc.).
- Keep the library free of runtime dependencies.

## Do not edit manually

Files in `lib/src/data/` are generated. Edit `tool/generate_data.dart` instead.
