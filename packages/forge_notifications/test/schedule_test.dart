import 'package:flutter_test/flutter_test.dart';
import 'package:forge_core/forge_core.dart';
import 'package:forge_notifications/src/schedule.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart';

void main() {
  late Location istanbul;
  late Location berlin;
  late Location newYork;

  setUpAll(() {
    tzdata.initializeTimeZones();
    istanbul = getLocation('Europe/Istanbul');
    berlin = getLocation('Europe/Berlin');
    newYork = getLocation('America/New_York');
  });

  final throwsValidation = throwsA(isA<ValidationFailure>());

  group('nextWeekly', () {
    test('finds a later weekday in the same week', () {
      // Wednesday.
      final now = TZDateTime(istanbul, 2026, 11, 11, 10);

      expect(
        nextWeekly(now, DateTime.friday, const ClockTime(7, 30)),
        TZDateTime(istanbul, 2026, 11, 13, 7, 30),
      );
    });

    test('wraps to next week for an earlier weekday', () {
      final now = TZDateTime(istanbul, 2026, 11, 11, 10);

      expect(
        nextWeekly(now, DateTime.monday, const ClockTime(9, 0)),
        TZDateTime(istanbul, 2026, 11, 16, 9),
      );
    });

    test('uses today when the time is still ahead, next week otherwise', () {
      final now = TZDateTime(istanbul, 2026, 11, 11, 10);

      expect(
        nextWeekly(now, DateTime.wednesday, const ClockTime(10, 1)),
        TZDateTime(istanbul, 2026, 11, 11, 10, 1),
      );
      expect(
        nextWeekly(now, DateTime.wednesday, const ClockTime(10, 0)),
        TZDateTime(istanbul, 2026, 11, 18, 10),
      );
    });

    test('wraps from Sunday night to Monday', () {
      final now = TZDateTime(istanbul, 2026, 11, 15, 23, 30);

      expect(
        nextWeekly(now, DateTime.monday, const ClockTime(0, 15)),
        TZDateTime(istanbul, 2026, 11, 16, 0, 15),
      );
    });

    test('crosses the year boundary', () {
      // Thursday 31 December.
      final now = TZDateTime(newYork, 2026, 12, 31, 20);

      expect(
        nextWeekly(now, DateTime.friday, const ClockTime(8, 0)),
        TZDateTime(newYork, 2027, 1, 1, 8),
      );
    });

    test('keeps the wall-clock time across DST changes', () {
      // Berlin springs forward on 29 March, falls back on 25 October 2026.
      final spring = nextWeekly(
        TZDateTime(berlin, 2026, 3, 27, 12),
        DateTime.sunday,
        const ClockTime(9, 0),
      );
      expect((spring.day, spring.hour), (29, 9));
      expect(spring.timeZoneOffset, const Duration(hours: 2));

      final autumn = nextWeekly(
        TZDateTime(berlin, 2026, 10, 23, 12),
        DateTime.sunday,
        const ClockTime(9, 0),
      );
      expect((autumn.day, autumn.hour), (25, 9));
      expect(autumn.timeZoneOffset, const Duration(hours: 1));

      // New York springs forward on 8 March 2026.
      final newYorkSpring = nextWeekly(
        TZDateTime(newYork, 2026, 3, 6, 12),
        DateTime.sunday,
        const ClockTime(7, 30),
      );
      expect((newYorkSpring.day, newYorkSpring.hour), (8, 7));
      expect(newYorkSpring.timeZoneOffset, const Duration(hours: -4));
    });

    test('lands on the right day for a time skipped by DST', () {
      // 02:30 does not exist in Berlin on 29 March 2026.
      final now = TZDateTime(berlin, 2026, 3, 27, 12);

      final next = nextWeekly(now, DateTime.sunday, const ClockTime(2, 30));

      expect(next.day, 29);
      expect(next.isAfter(now), isTrue);
    });

    test('rejects an invalid weekday or time', () {
      final now = TZDateTime(istanbul, 2026, 11, 11);

      expect(() => nextWeekly(now, 0, const ClockTime(9, 0)), throwsValidation);
      expect(() => nextWeekly(now, 8, const ClockTime(9, 0)), throwsValidation);
      expect(
        () => nextWeekly(now, 1, const ClockTime(24, 0)),
        throwsValidation,
      );
      expect(
        () => nextWeekly(now, 1, const ClockTime(9, 60)),
        throwsValidation,
      );
    });
  });

  group('seriesOccurrences', () {
    test('starts at a future first date and keeps the wall-clock time', () {
      final first = TZDateTime(berlin, 2026, 3, 16, 7);

      final occurrences = seriesOccurrences(
        first,
        2,
        TZDateTime(berlin, 2026, 3, 1),
      );

      expect(occurrences, hasLength(seriesLength));
      expect(occurrences.first, first);
      expect(occurrences[1], TZDateTime(berlin, 2026, 3, 30, 7));
      expect(occurrences.map((o) => o.hour).toSet(), {7});
      expect(occurrences.map((o) => o.timeZoneOffset.inHours).toSet(), {1, 2});
      for (var i = 1; i < occurrences.length; i++) {
        final previous = occurrences[i - 1];
        final days = DateTime.utc(
          occurrences[i].year,
          occurrences[i].month,
          occurrences[i].day,
        ).difference(DateTime.utc(previous.year, previous.month, previous.day));
        expect(days.inDays, 14);
      }
    });

    test('continues a series whose first date has passed', () {
      final first = TZDateTime(istanbul, 2026, 1, 5, 18);
      final now = TZDateTime(istanbul, 2026, 2, 9, 19);

      final occurrences = seriesOccurrences(first, 2, now);

      expect(occurrences.first, TZDateTime(istanbul, 2026, 2, 16, 18));
    });

    test('skips an occurrence at exactly now', () {
      final first = TZDateTime(istanbul, 2026, 1, 5, 18);

      final occurrences = seriesOccurrences(
        first,
        4,
        TZDateTime(istanbul, 2026, 2, 2, 18),
      );

      expect(occurrences.first, TZDateTime(istanbul, 2026, 3, 2, 18));
    });

    test('keeps the occurrence just after a DST change', () {
      // Weekly from summer time; the 25 October one is an hour later in UTC.
      final first = TZDateTime(berlin, 2026, 10, 18, 9);
      final now = TZDateTime(berlin, 2026, 10, 25, 8, 30);

      expect(
        seriesOccurrences(first, 1, now).first,
        TZDateTime(berlin, 2026, 10, 25, 9),
      );
    });

    test('crosses the year boundary', () {
      final first = TZDateTime(newYork, 2026, 12, 21, 6);

      final occurrences = seriesOccurrences(
        first,
        4,
        TZDateTime(newYork, 2026, 12, 1),
      );

      expect(occurrences[1], TZDateTime(newYork, 2027, 1, 18, 6));
    });

    test('rejects an interval under one week', () {
      final first = TZDateTime(istanbul, 2026, 1, 5);

      expect(() => seriesOccurrences(first, 0, first), throwsValidation);
    });
  });

  group('ids', () {
    test('a series owns seriesLength consecutive ids from its base', () {
      expect(seriesIds(100), List.generate(seriesLength, (i) => 100 + i));
    });

    test('ids must fit 32 bits', () {
      expect(() => checkId(0x7FFFFFFF), returnsNormally);
      expect(() => checkId(-0x80000000), returnsNormally);
      expect(() => checkId(0x80000000), throwsValidation);
      expect(
        () => checkSeriesBase(0x7FFFFFFF - seriesLength + 1),
        returnsNormally,
      );
      expect(
        () => checkSeriesBase(0x7FFFFFFF - seriesLength + 2),
        throwsValidation,
      );
    });
  });

  test('checkFuture rejects now and the past', () {
    final now = DateTime.utc(2026, 11, 11, 10);

    expect(
      () => checkFuture(now.add(const Duration(seconds: 1)), now),
      returnsNormally,
    );
    expect(() => checkFuture(now, now), throwsValidation);
    expect(
      () => checkFuture(now.subtract(const Duration(minutes: 1)), now),
      throwsValidation,
    );
  });
}
