import 'package:test/test.dart';
import 'package:timezone_country/timezone_country.dart';

void main() {
  group('String extensions', () {
    test('toCountryCode returns alpha-2 code', () {
      expect('Asia/Tokyo'.toCountryCode, 'JP');
      expect('America/New_York'.toCountryCode, 'US');
      expect('Europe/London'.toCountryCode, 'GB');
    });

    test('toCountryCode returns null for invalid timezone', () {
      expect('Invalid/Zone'.toCountryCode, isNull);
    });

    test('toCountryCodeAlpha3 returns alpha-3 code', () {
      expect('Asia/Tokyo'.toCountryCodeAlpha3, 'JPN');
      expect('America/New_York'.toCountryCodeAlpha3, 'USA');
    });

    test('toCountryCodes returns all country codes', () {
      expect('Europe/Brussels'.toCountryCodes, contains('BE'));
      expect('Europe/Brussels'.toCountryCodes, contains('NL'));
    });

    test('toCountryCodesAlpha3 returns alpha-3 codes', () {
      expect('Europe/Brussels'.toCountryCodesAlpha3, contains('BEL'));
      expect('Europe/Brussels'.toCountryCodesAlpha3, contains('NLD'));
    });

    test('toTimezones returns timezones for alpha-2 code', () {
      expect('JP'.toTimezones, contains('Asia/Tokyo'));
      expect('US'.toTimezones, contains('America/New_York'));
    });

    test('toTimezones returns timezones for alpha-3 code', () {
      expect('JPN'.toTimezones, contains('Asia/Tokyo'));
      expect('USA'.toTimezones, contains('America/New_York'));
    });

    test('toTimezones returns null for invalid code', () {
      expect('XX'.toTimezones, isNull);
    });

    test('toCanonicalTimezone resolves legacy name', () {
      expect('US/Eastern'.toCanonicalTimezone, 'America/New_York');
      expect('Japan'.toCanonicalTimezone, 'Asia/Tokyo');
      expect('Asia/Calcutta'.toCanonicalTimezone, 'Asia/Kolkata');
    });

    test('toCanonicalTimezone returns canonical name unchanged', () {
      expect('Asia/Tokyo'.toCanonicalTimezone, 'Asia/Tokyo');
    });

    test('toAlpha3 converts alpha-2 to alpha-3', () {
      expect('US'.toAlpha3, 'USA');
      expect('JP'.toAlpha3, 'JPN');
      expect('GB'.toAlpha3, 'GBR');
    });

    test('toAlpha3 returns null for invalid code', () {
      expect('XX'.toAlpha3, isNull);
    });

    test('toAlpha2 converts alpha-3 to alpha-2', () {
      expect('USA'.toAlpha2, 'US');
      expect('JPN'.toAlpha2, 'JP');
      expect('GBR'.toAlpha2, 'GB');
    });

    test('toAlpha2 returns null for invalid code', () {
      expect('XXX'.toAlpha2, isNull);
    });
  });
}
