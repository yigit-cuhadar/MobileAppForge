import 'package:forge_core/forge_core.dart';

import '../domain/health_steps.dart';

/// Local midnight starting the day of [time].
DateTime startOfDay(DateTime time) {
  final local = time.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// The local days from [first] to [last] inclusive as `[start, end)`
/// midnights. Built by calendar day, never by adding 24 hours, so days of a
/// daylight saving change are 23 or 25 hours long.
List<({DateTime start, DateTime end})> localDays(
  DateTime first,
  DateTime last,
) {
  final from = startOfDay(first);
  final to = startOfDay(last);
  return [
    for (var day = from; !day.isAfter(to); day = _next(day))
      (start: day, end: _next(day)),
  ];
}

DateTime _next(DateTime day) => DateTime(day.year, day.month, day.day + 1);

/// [localDays] of a read: [last] not before [first], at most [maxStepDays]
/// days; a [ValidationFailure] otherwise.
List<({DateTime start, DateTime end})> readDays(DateTime first, DateTime last) {
  if (startOfDay(last).isBefore(startOfDay(first))) {
    throw ValidationFailure('$last is before $first');
  }
  final days = localDays(first, last);
  if (days.length > maxStepDays) {
    throw ValidationFailure(
      '${days.length} days requested, at most $maxStepDays',
    );
  }
  return days;
}
