import 'package:forge_core/forge_core.dart';
import 'package:timezone/timezone.dart';

/// How many occurrences `Notifications.scheduleEvery` keeps scheduled. A
/// series with base id `b` owns ids `b` to `b + seriesLength - 1`.
const seriesLength = 12;

const _maxId = 0x7FFFFFFF;
const _minId = -0x80000000;

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

/// Throws a [ValidationFailure] unless [id] fits the platforms' 32-bit ids.
void checkId(int id) {
  if (id < _minId || id > _maxId) {
    throw ValidationFailure('Notification id $id is not a 32-bit integer');
  }
}

/// Throws a [ValidationFailure] unless every id of the series at [baseId]
/// fits the platforms' 32-bit ids.
void checkSeriesBase(int baseId) {
  checkId(baseId);
  checkId(baseId + seriesLength - 1);
}

/// Throws a [ValidationFailure] unless [when] is after [now].
void checkFuture(DateTime when, DateTime now) {
  if (!when.isAfter(now)) {
    throw ValidationFailure('Cannot schedule a notification at $when');
  }
}

/// The id of occurrence [index] of the series at [baseId].
int seriesId(int baseId, int index) => baseId + index;

/// The ids a series at [baseId] owns.
Iterable<int> seriesIds(int baseId) =>
    Iterable.generate(seriesLength, (i) => seriesId(baseId, i));

/// The first [weekday] (ISO, 1 = Monday) at [time] strictly after [now], in
/// [now]'s location.
TZDateTime nextWeekly(TZDateTime now, int weekday, ClockTime time) {
  if (weekday < DateTime.monday || weekday > DateTime.sunday) {
    throw ValidationFailure('Weekday $weekday is not in 1–7');
  }
  _checkTime(time);
  final days = (weekday - now.weekday) % 7;
  TZDateTime at(int offset) => TZDateTime(
    now.location,
    now.year,
    now.month,
    now.day + offset,
    time.hour,
    time.minute,
  );
  final candidate = at(days);
  return candidate.isAfter(now) ? candidate : at(days + 7);
}

/// The next [seriesLength] occurrences after [now] of a series that starts at
/// [first] and repeats every [weeks] weeks at [first]'s wall-clock time.
List<TZDateTime> seriesOccurrences(
  TZDateTime first,
  int weeks,
  TZDateTime now,
) {
  if (weeks < 1) throw ValidationFailure('Interval of $weeks weeks');
  final period = 7 * weeks;
  // Wall-clock days lag elapsed days by at most a DST shift, so this never
  // skips an occurrence after [now].
  var index = first.isAfter(now) ? 0 : now.difference(first).inDays ~/ period;
  final occurrences = <TZDateTime>[];
  while (occurrences.length < seriesLength) {
    final occurrence = TZDateTime(
      first.location,
      first.year,
      first.month,
      first.day + period * index++,
      first.hour,
      first.minute,
    );
    if (occurrence.isAfter(now)) occurrences.add(occurrence);
  }
  return occurrences;
}

void _checkTime(ClockTime time) {
  if (time.hour < 0 || time.hour > 23 || time.minute < 0 || time.minute > 59) {
    throw ValidationFailure('Time ${time.hour}:${time.minute} is invalid');
  }
}
