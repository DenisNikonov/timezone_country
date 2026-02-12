import 'package:test/test.dart';
import 'package:timezone_country/timezone_country.dart';

void main() {
  group('Country → Timezones mappings', () {
    test('single-timezone country returns one timezone', () {
      final tzs = TimezoneConvert.countryToTimezones('JP');
      expect(tzs, isNotNull);
      expect(tzs, equals(['Asia/Tokyo']));
    });

    test('US has many timezones', () {
      final tzs = TimezoneConvert.countryToTimezones('US');
      expect(tzs, isNotNull);
      expect(tzs!.length, greaterThanOrEqualTo(6));
      expect(tzs, contains('America/New_York'));
      expect(tzs, contains('America/Chicago'));
      expect(tzs, contains('America/Denver'));
      expect(tzs, contains('America/Los_Angeles'));
      expect(tzs, contains('Pacific/Honolulu'));
    });

    test('Russia has many timezones', () {
      final tzs = TimezoneConvert.countryToTimezones('RU');
      expect(tzs, isNotNull);
      expect(tzs!.length, greaterThanOrEqualTo(10));
      expect(tzs, contains('Europe/Moscow'));
    });

    test('Australia has many timezones', () {
      final tzs = TimezoneConvert.countryToTimezones('AU');
      expect(tzs, isNotNull);
      expect(tzs!.length, greaterThanOrEqualTo(5));
      expect(tzs, contains('Australia/Sydney'));
      expect(tzs, contains('Australia/Perth'));
    });

    test('small countries with one timezone', () {
      expect(TimezoneConvert.countryToTimezones('SG'), ['Asia/Singapore']);
      expect(TimezoneConvert.countryToTimezones('KR'), ['Asia/Seoul']);
    });

    test('case-insensitive lookup', () {
      expect(
        TimezoneConvert.countryToTimezones('us'),
        TimezoneConvert.countryToTimezones('US'),
      );
      expect(
        TimezoneConvert.countryToTimezones('Jp'),
        TimezoneConvert.countryToTimezones('JP'),
      );
    });

    test('accepts alpha-3 codes', () {
      expect(
        TimezoneConvert.countryToTimezones('USA'),
        TimezoneConvert.countryToTimezones('US'),
      );
      expect(
        TimezoneConvert.countryToTimezones('JPN'),
        TimezoneConvert.countryToTimezones('JP'),
      );
      expect(
        TimezoneConvert.countryToTimezones('GBR'),
        TimezoneConvert.countryToTimezones('GB'),
      );
    });

    test('unknown country code returns null', () {
      expect(TimezoneConvert.countryToTimezones('XX'), isNull);
      expect(TimezoneConvert.countryToTimezones('ZZZ'), isNull);
    });

    test('Argentina has multiple timezones', () {
      final tzs = TimezoneConvert.countryToTimezones('AR');
      expect(tzs, isNotNull);
      expect(tzs!.length, greaterThanOrEqualTo(5));
      expect(tzs, contains('America/Argentina/Buenos_Aires'));
    });

    test('Brazil has multiple timezones', () {
      final tzs = TimezoneConvert.countryToTimezones('BR');
      expect(tzs, isNotNull);
      expect(tzs!.length, greaterThanOrEqualTo(4));
      expect(tzs, contains('America/Sao_Paulo'));
    });

    test('Antarctica has multiple timezones', () {
      final tzs = TimezoneConvert.countryToTimezones('AQ');
      expect(tzs, isNotNull);
      expect(tzs!.length, greaterThanOrEqualTo(5));
    });
  });
}
