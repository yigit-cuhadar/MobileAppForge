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

    test('skips a week whose time falls in a DST gap', () {
      // 02:30 does not exist in Berlin on 29 March 2026.
      final now = TZDateTime(berlin, 2026, 3, 27, 12);

      final next = nextWeekly(now, DateTime.sunday, const ClockTime(2, 30));

      expect(next, TZDateTime(berlin, 2026, 4, 5, 2, 30));
      expect((next.hour, next.minute), (2, 30));
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

  group('planSeries', () {
    List<TZDateTime> times(SeriesPlan plan) => [
      for (final o in plan.occurrences) o.at,
    ];
    List<int> ids(SeriesPlan plan) => [for (final o in plan.occurrences) o.id];

    test('pre-schedules a future multi-week series at its wall-clock time', () {
      final first = TZDateTime(berlin, 2026, 3, 16, 7);

      final plan = planSeries(100, first, 2, TZDateTime(berlin, 2026, 3, 1));

      expect(plan.weekly, isFalse);
      expect(ids(plan), [for (var i = 100; i < 100 + seriesLength; i++) i]);
      expect(times(plan).first, first);
      expect(times(plan)[1], TZDateTime(berlin, 2026, 3, 30, 7));
      expect(times(plan).map((t) => t.hour).toSet(), {7});
      expect(times(plan).map((t) => t.timeZoneOffset.inHours).toSet(), {1, 2});
    });

    test('continues a started series and keeps each occurrence id', () {
      final first = TZDateTime(istanbul, 2026, 1, 5, 18);

      // Occurrences 0..2 have passed; occurrence 3 is next.
      final plan = planSeries(
        100,
        first,
        2,
        TZDateTime(istanbul, 2026, 2, 9, 19),
      );

      expect(plan.occurrences.first, (
        id: 103,
        at: TZDateTime(istanbul, 2026, 2, 16, 18),
      ));
      // Occurrence 12 reuses the id of occurrence 0.
      expect(ids(plan).sublist(8), [111, 100, 101, 102]);
      expect(ids(plan).toSet(), hasLength(seriesLength));
    });

    test('skips an occurrence at exactly now', () {
      final first = TZDateTime(istanbul, 2026, 1, 5, 18);

      final plan = planSeries(
        100,
        first,
        4,
        TZDateTime(istanbul, 2026, 2, 2, 18),
      );

      expect(times(plan).first, TZDateTime(istanbul, 2026, 3, 2, 18));
    });

    test('keeps the occurrence just after a DST change', () {
      // From summer time; the 1 November one is an hour later in UTC.
      final first = TZDateTime(berlin, 2026, 10, 18, 9);

      final plan = planSeries(
        100,
        first,
        2,
        TZDateTime(berlin, 2026, 11, 1, 8, 30),
      );

      expect(times(plan).first, TZDateTime(berlin, 2026, 11, 1, 9));
    });

    test('crosses the year boundary', () {
      final first = TZDateTime(newYork, 2026, 12, 21, 6);

      final plan = planSeries(100, first, 4, TZDateTime(newYork, 2026, 12, 1));

      expect(times(plan)[1], TZDateTime(newYork, 2027, 1, 18, 6));
    });

    test('repeats weekly natively once the first date is within a week', () {
      final now = TZDateTime(berlin, 2026, 11, 11, 10);

      final started = planSeries(
        100,
        TZDateTime(berlin, 2026, 10, 1, 8),
        1,
        now,
      );
      final soon = planSeries(100, TZDateTime(berlin, 2026, 11, 14, 8), 1, now);

      expect(started.weekly, isTrue);
      expect(started.occurrences, [
        (id: 100, at: TZDateTime(berlin, 2026, 11, 12, 8)),
      ]);
      expect(soon.weekly, isTrue);
      expect(times(soon), [TZDateTime(berlin, 2026, 11, 14, 8)]);
    });

    test('pre-schedules a weekly series whose first date is weeks away', () {
      final now = TZDateTime(berlin, 2026, 11, 11, 10);
      final first = TZDateTime(berlin, 2026, 12, 2, 8);

      final plan = planSeries(100, first, 1, now);

      expect(plan.weekly, isFalse);
      expect(times(plan).first, first);
      expect(times(plan), hasLength(seriesLength));
    });

    test('a native weekly repeat keeps a time hit by a DST gap', () {
      // Sundays at 02:30 from 22 March; 29 March has no 02:30.
      final plan = planSeries(
        100,
        TZDateTime(berlin, 2026, 3, 22, 2, 30),
        1,
        TZDateTime(berlin, 2026, 3, 27, 12),
      );

      expect(plan.weekly, isTrue);
      final next = times(plan).single;
      expect((next.month, next.day, next.hour, next.minute), (4, 5, 2, 30));
    });

    test('rejects an interval under one week', () {
      final first = TZDateTime(istanbul, 2026, 1, 5);

      expect(() => planSeries(100, first, 0, first), throwsValidation);
    });
  });

  test('a series base must leave room for its ids in 32 bits', () {
    expect(
      () => checkSeriesBase(0x7FFFFFFF - seriesLength + 1),
      returnsNormally,
    );
    expect(
      () => checkSeriesBase(0x7FFFFFFF - seriesLength + 2),
      throwsValidation,
    );
    expect(() => checkSeriesBase(-0x80000001), throwsValidation);
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

  test('checkBudget ignores ids the call replaces', () {
    final pending = List.generate(63, (i) => i);

    expect(() => checkBudget(pending, {}, 1, 64), returnsNormally);
    expect(() => checkBudget(pending, {}, 2, 64), throwsValidation);
    expect(() => checkBudget(pending, {0}, 2, 64), returnsNormally);
  });

  group('payload signatures', () {
    final at = DateTime.utc(2026, 11, 13, 7);
    String sign(String? payload, {DateTime? when, String body = 'B'}) =>
        signPayload(payload, at: when ?? at, title: 'T', body: body);

    test('are stable and change with time, text and payload', () {
      expect(sign('p'), sign('p'));
      expect(sign('p'), isNot(sign('q')));
      expect(sign('p'), isNot(sign('p', body: 'C')));
      expect(
        sign('p'),
        isNot(sign('p', when: at.add(const Duration(seconds: 1)))),
      );
    });

    test('come off again, and only a signature does', () {
      expect(unsignPayload(sign('reminder:workout')), 'reminder:workout');
      expect(unsignPayload(sign(null)), '');
      expect(unsignPayload('plain'), 'plain');
      expect(unsignPayload('a\u001Fnot-hex!'), 'a\u001Fnot-hex!');
    });
  });

  test('ceilToSecond rounds sub-seconds up', () {
    final whole = TZDateTime(istanbul, 2026, 11, 11, 10, 0, 5);

    expect(ceilToSecond(whole), whole);
    expect(
      ceilToSecond(whole.add(const Duration(microseconds: 1))),
      whole.add(const Duration(seconds: 1)),
    );
  });
}
