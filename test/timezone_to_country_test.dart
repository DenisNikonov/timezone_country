import 'package:test/test.dart';
import 'package:timezone_country/timezone_country.dart';

void main() {
  group('Timezone → Country mappings', () {
    // Africa
    test('Africa timezones map correctly', () {
      expect(TimezoneConvert.timezoneToCountryCode('Africa/Cairo'), 'EG');
      expect(TimezoneConvert.timezoneToCountryCode('Africa/Lagos'), 'NG');
      expect(
        TimezoneConvert.timezoneToCountryCode('Africa/Johannesburg'),
        'ZA',
      );
      expect(TimezoneConvert.timezoneToCountryCode('Africa/Nairobi'), 'KE');
    });

    // Americas
    test('Americas timezones map correctly', () {
      expect(TimezoneConvert.timezoneToCountryCode('America/New_York'), 'US');
      expect(TimezoneConvert.timezoneToCountryCode('America/Chicago'), 'US');
      expect(
        TimezoneConvert.timezoneToCountryCode('America/Los_Angeles'),
        'US',
      );
      expect(TimezoneConvert.timezoneToCountryCode('America/Toronto'), 'CA');
      expect(TimezoneConvert.timezoneToCountryCode('America/Sao_Paulo'), 'BR');
      expect(
        TimezoneConvert.timezoneToCountryCode('America/Mexico_City'),
        'MX',
      );
    });

    // Asia
    test('Asia timezones map correctly', () {
      expect(TimezoneConvert.timezoneToCountryCode('Asia/Tokyo'), 'JP');
      expect(TimezoneConvert.timezoneToCountryCode('Asia/Shanghai'), 'CN');
      expect(TimezoneConvert.timezoneToCountryCode('Asia/Kolkata'), 'IN');
      expect(TimezoneConvert.timezoneToCountryCode('Asia/Seoul'), 'KR');
      expect(TimezoneConvert.timezoneToCountryCode('Asia/Singapore'), 'SG');
      expect(TimezoneConvert.timezoneToCountryCode('Asia/Dubai'), 'AE');
    });

    // Europe
    test('Europe timezones map correctly', () {
      expect(TimezoneConvert.timezoneToCountryCode('Europe/London'), 'GB');
      expect(TimezoneConvert.timezoneToCountryCode('Europe/Paris'), 'FR');
      expect(TimezoneConvert.timezoneToCountryCode('Europe/Berlin'), 'DE');
      expect(TimezoneConvert.timezoneToCountryCode('Europe/Moscow'), 'RU');
      expect(TimezoneConvert.timezoneToCountryCode('Europe/Rome'), 'IT');
      expect(TimezoneConvert.timezoneToCountryCode('Europe/Madrid'), 'ES');
    });

    // Oceania
    test('Oceania timezones map correctly', () {
      expect(TimezoneConvert.timezoneToCountryCode('Australia/Sydney'), 'AU');
      expect(TimezoneConvert.timezoneToCountryCode('Pacific/Auckland'), 'NZ');
      expect(TimezoneConvert.timezoneToCountryCode('Pacific/Honolulu'), 'US');
    });

    // Antarctica
    test('Antarctica timezones map correctly', () {
      expect(TimezoneConvert.timezoneToCountryCode('Antarctica/Casey'), 'AQ');
      expect(TimezoneConvert.timezoneToCountryCode('Antarctica/Palmer'), 'AQ');
    });

    // Multi-country timezones
    test('multi-country timezone returns primary country', () {
      // Europe/Brussels serves BE, LU, NL
      expect(TimezoneConvert.timezoneToCountryCode('Europe/Brussels'), 'BE');
      // Asia/Dubai serves AE, OM, RE, SC, TF
      expect(TimezoneConvert.timezoneToCountryCode('Asia/Dubai'), 'AE');
    });

    test('multi-country timezone returns all countries', () {
      final codes = TimezoneConvert.timezoneToCountryCodes('Europe/Brussels');
      expect(codes, isNotNull);
      expect(codes, contains('BE'));
      expect(codes, contains('LU'));
      expect(codes, contains('NL'));
    });

    // Etc timezones are NOT in zone1970.tab (no country association)
    test('Etc timezones are not mapped to countries', () {
      expect(TimezoneConvert.timezoneToCountryCode('Etc/UTC'), isNull);
      expect(TimezoneConvert.timezoneToCountryCode('Etc/GMT'), isNull);
    });

    // Edge: timezone containing special characters
    test('timezones with underscores and hyphens work', () {
      expect(
        TimezoneConvert.timezoneToCountryCode('America/Argentina/Buenos_Aires'),
        'AR',
      );
      expect(
        TimezoneConvert.timezoneToCountryCode('Australia/Broken_Hill'),
        'AU',
      );
    });
  });
}
