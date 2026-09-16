// Not a `dart test` suite: CI compiles this with `dart compile exe`.
// Assert only facts that survive a data regeneration.
import 'package:timezone_country/timezone_country.dart';

void main() {
  final checks = <String, bool>{
    'timezoneToCountryCode':
        TimezoneConvert.timezoneToCountryCode('Asia/Tokyo') == 'JP',
    'alpha3': TimezoneConvert.alpha2ToAlpha3('JP') == 'JPN',
    'countryFlag': TimezoneConvert.countryFlag('JP') == '\u{1F1EF}\u{1F1F5}',
    'countryName': TimezoneConvert.countryName('JP')?.isNotEmpty ?? false,
    'countryToTimezones':
        TimezoneConvert.countryToTimezones('JP')?.isNotEmpty ?? false,
    'timezoneCoordinates':
        TimezoneConvert.timezoneCoordinates('Asia/Tokyo') != null,
    'timezoneToWindows':
        TimezoneConvert.timezoneToWindows('Asia/Tokyo')?.isNotEmpty ?? false,
    'allTimezones': TimezoneConvert.allTimezones.isNotEmpty,
    'extension': 'Asia/Tokyo'.toCountryCode == 'JP',
  };

  final failed = checks.entries.where((e) => !e.value).map((e) => e.key);
  if (failed.isNotEmpty) {
    throw StateError('AOT smoke check failed: ${failed.join(', ')}');
  }
  print('aot smoke ok: ${checks.length} checks');
}
