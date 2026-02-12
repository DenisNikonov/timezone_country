import 'package:test/test.dart';
import 'package:timezone_country/timezone_country.dart';

void main() {
  group('Legacy timezone resolution', () {
    test('US legacy timezones resolve correctly', () {
      expect(TimezoneConvert.resolveTimezone('US/Eastern'), 'America/New_York');
      expect(TimezoneConvert.resolveTimezone('US/Central'), 'America/Chicago');
      expect(TimezoneConvert.resolveTimezone('US/Mountain'), 'America/Denver');
      expect(
        TimezoneConvert.resolveTimezone('US/Pacific'),
        'America/Los_Angeles',
      );
      expect(TimezoneConvert.resolveTimezone('US/Hawaii'), 'Pacific/Honolulu');
      expect(TimezoneConvert.resolveTimezone('US/Alaska'), 'America/Anchorage');
    });

    test('single-name legacy timezones resolve correctly', () {
      expect(TimezoneConvert.resolveTimezone('Japan'), 'Asia/Tokyo');
      expect(TimezoneConvert.resolveTimezone('Cuba'), 'America/Havana');
      expect(TimezoneConvert.resolveTimezone('Egypt'), 'Africa/Cairo');
      expect(TimezoneConvert.resolveTimezone('Turkey'), 'Europe/Istanbul');
      expect(TimezoneConvert.resolveTimezone('Poland'), 'Europe/Warsaw');
      expect(TimezoneConvert.resolveTimezone('Portugal'), 'Europe/Lisbon');
    });

    test('renamed city timezones resolve correctly', () {
      expect(TimezoneConvert.resolveTimezone('Asia/Calcutta'), 'Asia/Kolkata');
      expect(
        TimezoneConvert.resolveTimezone('Asia/Saigon'),
        'Asia/Ho_Chi_Minh',
      );
      expect(
        TimezoneConvert.resolveTimezone('Asia/Katmandu'),
        'Asia/Kathmandu',
      );
      expect(TimezoneConvert.resolveTimezone('Asia/Rangoon'), 'Asia/Yangon');
    });

    test('Canada legacy timezones resolve correctly', () {
      expect(
        TimezoneConvert.resolveTimezone('Canada/Eastern'),
        'America/Toronto',
      );
      expect(
        TimezoneConvert.resolveTimezone('Canada/Pacific'),
        'America/Vancouver',
      );
    });

    test('abbreviation timezones resolve correctly', () {
      expect(TimezoneConvert.resolveTimezone('GB'), 'Europe/London');
      expect(TimezoneConvert.resolveTimezone('ROK'), 'Asia/Seoul');
      expect(TimezoneConvert.resolveTimezone('ROC'), 'Asia/Taipei');
      expect(TimezoneConvert.resolveTimezone('PRC'), 'Asia/Shanghai');
    });

    test('UTC aliases resolve correctly', () {
      expect(TimezoneConvert.resolveTimezone('UTC'), 'Etc/UTC');
      expect(TimezoneConvert.resolveTimezone('UCT'), 'Etc/UTC');
      expect(TimezoneConvert.resolveTimezone('Universal'), 'Etc/UTC');
      expect(TimezoneConvert.resolveTimezone('Zulu'), 'Etc/UTC');
    });

    test('canonical name returns unchanged', () {
      expect(TimezoneConvert.resolveTimezone('Asia/Tokyo'), 'Asia/Tokyo');
      expect(
        TimezoneConvert.resolveTimezone('America/New_York'),
        'America/New_York',
      );
      expect(TimezoneConvert.resolveTimezone('Europe/London'), 'Europe/London');
    });

    test('unknown name returns unchanged', () {
      expect(
        TimezoneConvert.resolveTimezone('Totally/Unknown'),
        'Totally/Unknown',
      );
      expect(TimezoneConvert.resolveTimezone(''), '');
    });

    test('chained: resolve legacy then lookup country', () {
      final canonical = TimezoneConvert.resolveTimezone('US/Eastern');
      final country = TimezoneConvert.timezoneToCountryCode(canonical);
      expect(country, 'US');

      final canonical2 = TimezoneConvert.resolveTimezone('Japan');
      final country2 = TimezoneConvert.timezoneToCountryCode(canonical2);
      expect(country2, 'JP');

      final canonical3 = TimezoneConvert.resolveTimezone('Asia/Calcutta');
      final country3 = TimezoneConvert.timezoneToCountryCode(canonical3);
      expect(country3, 'IN');
    });

    test('legacyTimezoneAliases map is accessible', () {
      final aliases = TimezoneConvert.legacyTimezoneAliases;
      expect(aliases, isNotEmpty);
      expect(aliases['US/Eastern'], 'America/New_York');
      expect(aliases['Japan'], 'Asia/Tokyo');
    });
  });
}
