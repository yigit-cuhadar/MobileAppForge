import 'package:vector_math/vector_math_64.dart';

Never bad(String message) => throw FormatException(message);

Map<String, Object?> object(Object? value, String what) =>
    value is Map<String, Object?> ? value : bad('$what is not an object');

List<Object?> array(Object? value, String what) =>
    value is List<Object?> ? value : bad('$what is not a list');

double number(Object? value, String what) =>
    value is num ? value.toDouble() : bad('$what is not a number');

String text(Object? value, String what) =>
    value is String ? value : bad('$what is not a string');

List<double> numbers(Object? value, int count, String what) {
  final list = array(value, what);
  if (list.length != count) bad('$what needs $count numbers');
  return [for (final v in list) number(v, what)];
}

Vector3 vec3(Object? value, String what) {
  final n = numbers(value, 3, what);
  return Vector3(n[0], n[1], n[2]);
}

/// [base] with [change] folded in; nested objects merge, anything else is replaced.
Map<String, Object?> merged(
  Map<String, Object?> base,
  Map<String, Object?> change,
) {
  final out = Map<String, Object?>.of(base);
  for (final MapEntry(:key, :value) in change.entries) {
    final old = out[key];
    out[key] = value is Map<String, Object?> && old is Map<String, Object?>
        ? merged(old, value)
        : value;
  }
  return out;
}
