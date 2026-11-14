import 'dart:math' as math;

import 'package:intl/intl.dart';

/// As many decimals as [step] has, so whole steps read without ".0".
int decimalsOf(double step) {
  var decimals = 0;
  while (decimals < 10) {
    final scaled = step * math.pow(10, decimals);
    if ((scaled - scaled.round()).abs() < 1e-9) break;
    decimals++;
  }
  return decimals;
}

/// `min + index * step` without the floating-point noise.
double stepValue(double min, double step, int index) =>
    double.parse((min + index * step).toStringAsFixed(10));

/// [value] with [decimals] decimals in the current locale's digits, its
/// thousands grouped ("1,000") unless [grouped] is false, as for a year.
String formatNumber(double value, int decimals, {bool grouped = true}) {
  final format = NumberFormat.decimalPatternDigits(decimalDigits: decimals);
  if (!grouped) format.turnOffGrouping();
  return format.format(value);
}
