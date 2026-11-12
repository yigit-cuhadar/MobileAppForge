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
