import 'package:vector_math/vector_math_64.dart';

import 'json.dart';
import 'shape.dart';
import 'skeleton.dart';

const _placing = {'kit', 'at', 'turn'};

/// The kits a recipe uses, placed in rig space (recipe.py's `gear_of`).
class Gear {
  Gear._(this.skeleton, this.first);

  /// Reads the recipe's `gear` with [kits]; [first] is the clip's first key.
  factory Gear(
    Skeleton skeleton,
    Solved first,
    Object? uses,
    Map<String, Object?> kits,
  ) {
    final gear = Gear._(skeleton, first);
    for (final useJson in array(uses ?? const [], 'gear')) {
      final use = object(useJson, 'gear use');
      final name = text(use['kit'], 'kit');
      final kit = kits[name] == null
          ? bad('unknown kit $name')
          : object(kits[name], 'kit $name');
      final values = {
        ...object(kit['values'] ?? const <String, Object?>{}, 'values'),
        for (final MapEntry(:key, :value) in use.entries)
          if (!_placing.contains(key)) key: value,
      };
      final placing = _Placing(
        Matrix3.rotationZ(radians(number(use['turn'] ?? 0, 'turn'))),
        vec3(use['at'] ?? const [0, 0, 0], 'at'),
        object(
          _filled(kit['movers'] ?? const <String, Object?>{}, values),
          'movers',
        ),
      );
      for (final pieceJson in array(_filled(kit['pieces'], values), 'pieces')) {
        gear.pieces.add(_piece(object(pieceJson, 'piece'), placing));
      }
    }
    return gear;
  }

  final Skeleton skeleton;
  final Solved first;

  /// The frame being placed.
  late Solved now = first;
  final pieces = <Piece>[];
}

/// One piece: a unit cube, a unit cylinder (radius 1, height 1 along z) or a
/// unit ball (radius 1), placed by a linear part and an offset in metres.
sealed class Piece {
  Piece(this.colour);

  final String colour;

  PieceShape get shape => switch (this) {
    _Cylinder() => PieceShape.cylinder,
    _Ball() => PieceShape.ball,
    _Box() => PieceShape.box,
  };

  void place(Gear gear, Matrix3 linear, Vector3 offset);
}

class _Cylinder extends Piece {
  _Cylinder(super.colour, this._a, this._b, this._r);

  final _Point _a, _b;
  final double _r;
  final _pa = Vector3.zero();
  final _pb = Vector3.zero();
  final _axis = Vector3.zero();
  final _side = Vector3.zero();
  final _up = Vector3.zero();

  @override
  void place(Gear gear, Matrix3 linear, Vector3 offset) {
    _a.eval(gear, gear.now, _pa);
    _b.eval(gear, gear.now, _pb);
    offset
      ..setFrom(_pa)
      ..add(_pb)
      ..scale(0.5);
    _pb.sub(_pa);
    _axis
      ..setFrom(_pb)
      ..normalize();
    _axis.z.abs() < 0.9 ? _up.setValues(0, 0, 1) : _up.setValues(1, 0, 0);
    _axis.crossInto(_up, _side);
    _side.normalize();
    _axis.crossInto(_side, _up);
    _side.scale(_r);
    _up.scale(_r);
    linear.setColumns(_side, _up, _pb);
  }
}

class _Ball extends Piece {
  _Ball(super.colour, this._at, this._r);

  final _Point _at;
  final double _r;

  @override
  void place(Gear gear, Matrix3 linear, Vector3 offset) {
    _at.eval(gear, gear.now, offset);
    linear.setValues(_r, 0, 0, 0, _r, 0, 0, 0, _r);
  }
}

class _Box extends Piece {
  _Box(super.colour, this._linear, this._at);

  final Matrix3 _linear;
  final _Point _at;

  @override
  void place(Gear gear, Matrix3 linear, Vector3 offset) {
    linear.setFrom(_linear);
    _at.eval(gear, gear.now, offset);
  }
}

class _Placing {
  _Placing(this.turn, this.at, this.moversJson);

  final Matrix3 turn;
  final Vector3 at;
  final Map<String, Object?> moversJson;
  final movers = <String, _Mover>{};
}

class _Mover {
  _Mover(this.follows, this.turnedAxis, this.along);

  final _Point follows;
  final Vector3 turnedAxis, along;
}

Object? _filled(Object? value, Map<String, Object?> values) => switch (value) {
  Map<String, Object?>() => {
    for (final MapEntry(:key, :value) in value.entries)
      key: _filled(value, values),
  },
  List<Object?>() => [for (final v in value) _filled(v, values)],
  String() when value.startsWith(r'$') =>
    values.containsKey(value.substring(1))
        ? values[value.substring(1)]
        : bad('unknown value $value'),
  _ => value,
};

Piece _piece(Map<String, Object?> json, _Placing placing) {
  final colour = text(json['colour'] ?? 'gear', 'colour');
  if (json.containsKey('cyl')) {
    final ends = array(json['cyl'], 'cyl');
    if (ends.length != 2) bad('cyl needs two points');
    return _Cylinder(
      colour,
      _point(ends[0], placing),
      _point(ends[1], placing),
      number(json['r'], 'r'),
    );
  }
  if (json.containsKey('ball')) {
    return _Ball(colour, _point(json['ball'], placing), number(json['r'], 'r'));
  }
  final size = vec3(json['size'], 'size');
  return _Box(
    colour,
    placing.turn.clone()
      ..multiply(Matrix3(size.x, 0, 0, 0, size.y, 0, 0, 0, size.z)),
    _point(json['box'], placing),
  );
}

_Point _point(Object? json, _Placing placing) {
  if (json is List<Object?>) {
    return _Fixed(
      placing.turn.transformed(vec3(json, 'point'))..add(placing.at),
    );
  }
  final spec = object(json, 'point');
  if (spec.containsKey('grips')) return _Grips(vec3(spec['grips'], 'grips'));
  if (spec.containsKey('hand')) {
    final side = switch (text(spec['hand'], 'hand')) {
      'L' => 0,
      'R' => 1,
      final other => bad('unknown hand $other'),
    };
    return _Hand(side, vec3(spec['at'], 'at'));
  }
  if (spec.containsKey('foot')) {
    final side = switch (text(spec['foot'], 'foot')) {
      'L' => 0,
      'R' => 1,
      final other => bad('unknown foot $other'),
    };
    return _Foot(side, vec3(spec['at'], 'at'));
  }
  if (spec.containsKey('between')) {
    final ends = array(spec['between'], 'between');
    if (ends.length != 2) bad('between needs two points');
    return _Between(
      _point(ends[0], placing),
      _point(ends[1], placing),
      number(spec['t'], 't'),
    );
  }
  final name = text(spec['with'], 'with');
  final mover = placing.movers[name] ??= switch (placing.moversJson[name]) {
    null => bad('unknown mover $name'),
    final json => _mover(object(json, 'mover $name'), placing),
  };
  return _Moved(vec3(spec['at'], 'at'), mover, placing);
}

_Mover _mover(Map<String, Object?> json, _Placing placing) => _Mover(
  _point(json['follows'], placing),
  placing.turn.transformed(vec3(json['axis'], 'axis')),
  vec3(json['along'], 'along'),
);

sealed class _Point {
  void eval(Gear gear, Solved solved, Vector3 out);
}

class _Fixed extends _Point {
  _Fixed(this._at);

  final Vector3 _at;

  @override
  void eval(Gear gear, Solved solved, Vector3 out) => out.setFrom(_at);
}

/// Between the two hands: along the bar, forward of it, above it.
class _Grips extends _Point {
  _Grips(this._grips);

  final Vector3 _grips;
  final _right = Vector3.zero();
  final _along = Vector3.zero();
  final _forward = Vector3.zero();
  final _up = Vector3.zero();

  @override
  void eval(Gear gear, Solved solved, Vector3 out) {
    gear.skeleton.grip(solved, 0, out);
    gear.skeleton.grip(solved, 1, _right);
    _along
      ..setFrom(out)
      ..sub(_right)
      ..normalize();
    _up
      ..setValues(0, 0, 1)
      ..addScaled(_along, -_along.z)
      ..normalize();
    _up.crossInto(_along, _forward);
    out
      ..add(_right)
      ..scale(0.5)
      ..addScaled(_along, _grips.x)
      ..addScaled(_forward, _grips.y)
      ..addScaled(_up, _grips.z);
  }
}

/// From where one hand holds: along the fingers, out of the palm, across it.
class _Hand extends _Point {
  _Hand(this._side, this._at);

  final int _side;
  final Vector3 _at;

  @override
  void eval(Gear gear, Solved solved, Vector3 out) =>
      gear.skeleton.grip(solved, _side, out, from: _at);
}

/// From one ankle, in the foot's own frame.
class _Foot extends _Point {
  _Foot(this._side, this._at);

  final int _side;
  final Vector3 _at;

  @override
  void eval(Gear gear, Solved solved, Vector3 out) =>
      gear.skeleton.footPoint(solved, _side, _at, out);
}

class _Between extends _Point {
  _Between(this._a, this._b, this._t);

  final _Point _a, _b;
  final double _t;
  final _end = Vector3.zero();

  @override
  void eval(Gear gear, Solved solved, Vector3 out) {
    _a.eval(gear, solved, out);
    _b.eval(gear, solved, _end);
    _end.sub(out);
    out.addScaled(_end, _t);
  }
}

/// How far the mover's point has moved along its axis since the first key,
/// as a shift along `along`. The followed point is always taken at the frame
/// being placed and at the first key, as recipe.py does.
class _Moved extends _Point {
  _Moved(this._at, this._mover, _Placing placing)
    : _turn = placing.turn,
      _kitAt = placing.at;

  final Vector3 _at;
  final _Mover _mover;
  final Matrix3 _turn;
  final Vector3 _kitAt;
  final _now = Vector3.zero();
  final _first = Vector3.zero();

  @override
  void eval(Gear gear, Solved solved, Vector3 out) {
    _mover.follows.eval(gear, gear.now, _now);
    _mover.follows.eval(gear, gear.first, _first);
    _now.sub(_first);
    out
      ..setFrom(_at)
      ..addScaled(_mover.along, _now.dot(_mover.turnedAxis));
    _turn.transform(out);
    out.add(_kitAt);
  }
}
