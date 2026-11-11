import 'package:forge_core/forge_core.dart';
import 'package:timezone/timezone.dart';

/// How many occurrences `Notifications.scheduleEvery` keeps scheduled. A
/// series with base id `b` owns ids `b` to `b + seriesLength - 1`.
const seriesLength = 12;

/// Pending notifications iOS keeps per app; it silently drops the rest.
const iosPendingLimit = 64;

/// A local wall-clock time of day.
final class ClockTime extends Equatable {
  const ClockTime(this.hour, this.minute);

  /// 0–23.
  final int hour;

  /// 0–59.
  final int minute;

  @override
  List<Object?> get props => [hour, minute];
}

/// One notification to schedule.
typedef Occurrence = ({int id, TZDateTime at});

/// What a series schedules: one native weekly repeat, or one-offs.
typedef SeriesPlan = ({bool weekly, List<Occurrence> occurrences});

/// Throws a [ValidationFailure] unless every id of the series at [baseId]
/// fits the platforms' 32-bit ids.
void checkSeriesBase(int baseId) {
  if (baseId < -0x80000000 || baseId + seriesLength - 1 > 0x7FFFFFFF) {
    throw ValidationFailure('Series ids from $baseId exceed 32 bits');
  }
}

/// Throws a [ValidationFailure] unless [when] is after [now].
void checkFuture(DateTime when, DateTime now) {
  if (!when.isAfter(now)) {
    throw ValidationFailure('Cannot schedule a notification at $when');
  }
}

/// Throws a [ValidationFailure] if adding [adding] notifications would take
/// the pending ones past [limit]. Pending ids in [claimed] are replaced or
/// cancelled by the same call, so they do not count.
void checkBudget(
  Iterable<int> pendingIds,
  Set<int> claimed,
  int adding,
  int limit,
) {
  final total = pendingIds.where((id) => !claimed.contains(id)).length + adding;
  if (total > limit) {
    throw ValidationFailure(
      '$total pending notifications exceed the limit of $limit',
    );
  }
}

/// [time] rounded up to a whole second: the platforms drop sub-seconds.
TZDateTime ceilToSecond(TZDateTime time) {
  final excess = time.microsecondsSinceEpoch % Duration.microsecondsPerSecond;
  return excess == 0
      ? time
      : time.add(
          Duration(microseconds: Duration.microsecondsPerSecond - excess),
        );
}

/// The ids a series at [baseId] owns.
Iterable<int> seriesIds(int baseId) =>
    Iterable.generate(seriesLength, (i) => baseId + i);

/// The first [weekday] (ISO, 1 = Monday) at [time] strictly after [now], in
/// [now]'s location. A week whose [time] falls in a DST gap is skipped, so a
/// native weekly repeat started from the result keeps [time].
TZDateTime nextWeekly(TZDateTime now, int weekday, ClockTime time) {
  if (weekday < DateTime.monday || weekday > DateTime.sunday) {
    throw ValidationFailure('Weekday $weekday is not in 1–7');
  }
  if (time.hour < 0 || time.hour > 23 || time.minute < 0 || time.minute > 59) {
    throw ValidationFailure('Time ${time.hour}:${time.minute} is invalid');
  }
  var days = (weekday - now.weekday) % 7;
  while (true) {
    final candidate = TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day + days,
      time.hour,
      time.minute,
    );
    if (candidate.isAfter(now) &&
        candidate.hour == time.hour &&
        candidate.minute == time.minute) {
      return candidate;
    }
    days += 7;
  }
}

/// The plan for a series at [baseId] that starts at [first] and repeats
/// every [weeks] weeks at [first]'s wall-clock time, from [now] on.
///
/// Weekly series whose next occurrence is [first] or later than it repeat
/// natively under [baseId]. Otherwise the next [seriesLength] occurrences are
/// one-offs; occurrence `k` (counted from [first]) gets id
/// `baseId + k % seriesLength`, so planning again keeps each occurrence's id.
SeriesPlan planSeries(int baseId, TZDateTime first, int weeks, TZDateTime now) {
  if (weeks < 1) throw ValidationFailure('Interval of $weeks weeks');
  if (weeks == 1) {
    final next = nextWeekly(
      now,
      first.weekday,
      ClockTime(first.hour, first.minute),
    );
    if (!first.isAfter(next)) {
      return (weekly: true, occurrences: [(id: baseId, at: next)]);
    }
  }
  final period = 7 * weeks;
  // Wall-clock days lag elapsed days by at most a DST shift, so this never
  // skips an occurrence after [now].
  var index = first.isAfter(now) ? 0 : now.difference(first).inDays ~/ period;
  final occurrences = <Occurrence>[];
  while (occurrences.length < seriesLength) {
    final at = TZDateTime(
      first.location,
      first.year,
      first.month,
      first.day + period * index,
      first.hour,
      first.minute,
    );
    if (at.isAfter(now)) {
      occurrences.add((id: baseId + index % seriesLength, at: at));
    }
    index++;
  }
  return (weekly: false, occurrences: occurrences);
}
