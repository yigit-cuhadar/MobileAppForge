import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

// Scratch values: every helper writes into outputs it is given, so sampling
// allocates nothing. No helper calls another one that shares its scratch.
final _rotation = Matrix3.zero();
final _turn = Matrix3.zero();
final _half = Matrix3.zero();
final _a = Vector3.zero();
final _b = Vector3.zero();
final _n = Vector3.zero();
final _axis = Vector3.zero();

/// Rz(yaw) Rx(pitch) Ry(roll), in degrees.
void setEuler(Matrix3 out, double pitch, double yaw, double roll) {
  out.setRotationZ(radians(yaw));
  _rotation.setRotationX(radians(pitch));
  out.multiply(_rotation);
  _rotation.setRotationY(radians(roll));
  out.multiply(_rotation);
}

void setRotationAxis(Matrix3 out, Vector3 axis, double angle) {
  final length = axis.length;
  final x = axis.x / length, y = axis.y / length, z = axis.z / length;
  final c = math.cos(angle), s = math.sin(angle), k = 1 - c;
  out.setValues(
    c + x * x * k,
    y * x * k + z * s,
    z * x * k - y * s,
    x * y * k - z * s,
    c + y * y * k,
    z * y * k + x * s,
    x * z * k + y * s,
    y * z * k - x * s,
    c + z * z * k,
  );
}

/// The rotation half way from [a] to [b].
void setHalfway(Matrix3 out, Matrix3 a, Matrix3 b) {
  _turn
    ..setFrom(a)
    ..transposeMultiply(b);
  final angle = math.acos(((_turn.trace() - 1) / 2).clamp(-1.0, 1.0));
  if (angle < 1e-6) {
    out.setFrom(a);
    return;
  }
  _axis.setValues(
    _turn.entry(2, 1) - _turn.entry(1, 2),
    _turn.entry(0, 2) - _turn.entry(2, 0),
    _turn.entry(1, 0) - _turn.entry(0, 1),
  );
  if (_axis.length < 1e-6) {
    // Half a turn: the axis is the largest column of turn + 1.
    var largest = -1.0;
    for (var c = 0; c < 3; c++) {
      final x = _turn.entry(0, c) + (c == 0 ? 1 : 0);
      final y = _turn.entry(1, c) + (c == 1 ? 1 : 0);
      final z = _turn.entry(2, c) + (c == 2 ? 1 : 0);
      final norm = math.sqrt(x * x + y * y + z * z);
      if (norm > largest) {
        largest = norm;
        _axis.setValues(x, y, z);
      }
    }
  }
  setRotationAxis(_half, _axis, angle / 2);
  out
    ..setFrom(a)
    ..multiply(_half);
}

/// Orthonormal frame along [axis] whose third column is nearest [normal].
void setFrame(Matrix3 out, Vector3 axis, Vector3 normal) {
  _a
    ..setFrom(axis)
    ..normalize();
  _n
    ..setFrom(normal)
    ..addScaled(_a, -normal.dot(_a))
    ..normalize();
  _n.crossInto(_a, _b);
  out.setColumns(_a, _b, _n);
}

/// Angle by which [rotation] turns [reference] around [axis].
double twistAbout(Matrix3 rotation, Vector3 axis, Vector3 reference) {
  _a
    ..setFrom(axis)
    ..normalize();
  _b
    ..setFrom(reference)
    ..addScaled(_a, -reference.dot(_a));
  rotation.transformed(reference, _n);
  _n.addScaled(_a, -_n.dot(_a));
  _b.crossInto(_n, _axis);
  return math.atan2(_axis.dot(_a), _b.dot(_n));
}

/// Two-bone IK: writes the middle joint, the reached end and the bend normal.
void solveLimb(
  Vector3 root,
  Vector3 target,
  double upper,
  double lower,
  Vector3 pole, {
  required Vector3 mid,
  required Vector3 end,
  required Vector3 normal,
}) {
  _a
    ..setFrom(target)
    ..sub(root);
  final distance = _a.length;
  final reach = distance.clamp(
    (upper - lower).abs() + 1e-4,
    (upper + lower) * 0.999,
  );
  _a.scale(1 / distance);
  _b
    ..setFrom(pole)
    ..addScaled(_a, -pole.dot(_a))
    ..normalize();
  final cos =
      (upper * upper + reach * reach - lower * lower) / (2 * upper * reach);
  mid
    ..setFrom(root)
    ..addScaled(_a, upper * cos)
    ..addScaled(_b, upper * math.sqrt(1 - cos * cos));
  end
    ..setFrom(root)
    ..addScaled(_a, reach);
  _a.crossInto(_b, normal);
}

double ease(double t) => t * t * (3 - 2 * t);
