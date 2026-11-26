import 'dart:math' as math;
import 'dart:typed_data';

import 'package:vector_math/vector_math_64.dart';

import 'gear.dart';
import 'json.dart';
import 'math.dart';
import 'shape.dart';
import 'skeleton.dart';

/// The body's joints: from the rig JSON (bone names, heads, tails, palms in
/// metres, and `metres` per unit of the body file).
class MotionRig {
  MotionRig._(this._skeleton);

  factory MotionRig.fromJson(Map<String, Object?> json) =>
      MotionRig._(Skeleton.fromJson(json));

  final Skeleton _skeleton;

  List<String> get bones => _skeleton.bones;
}

/// The gear, floor and shadow as one mesh in the body file's space, every
/// vertex bound to one joint of its [Motion].
class MotionMesh {
  MotionMesh._(MeshBuilder mesh, this.partNames)
    : positions = Float32List.fromList(mesh.positions),
      normals = Float32List.fromList(mesh.normals),
      vertexParts = Uint16List.fromList(mesh.parts),
      joints = Uint8List.fromList(mesh.joints),
      indices = Uint16List.fromList(mesh.indices);

  /// The colours used, such as steel, plate, floor and shadow.
  final List<String> partNames;

  /// Three per vertex.
  final Float32List positions, normals;

  /// Per vertex, an index into [partNames].
  final Uint16List vertexParts;

  /// Per vertex, the joint that moves it.
  final Uint8List joints;

  /// Triangles, counter-clockwise from outside.
  final Uint16List indices;
}

/// One clip of an animation recipe on a rig: the correct form, or one of the
/// recipe's mistakes. Everything it gives is in the body file's space: y up,
/// the body faces +z, the file's own unit.
class Motion {
  Motion._(
    this._skeleton,
    this._times,
    this._poses,
    this._gear,
    this._ring,
    this.view,
  ) : _durationMicros = (_times.last * 1e6).round(),
      _now = Solved(_skeleton.bones.length);

  /// The correct form when [mistake] is null, else mistake number [mistake]
  /// of the recipe's `mistakes`. Throws [ArgumentError] for a mistake that is
  /// not shown and [FormatException] for what the recipe format does not allow.
  factory Motion({
    required MotionRig rig,
    required Map<String, Object?> kits,
    required Map<String, Object?> recipe,
    int? mistake,
  }) {
    final skeleton = rig._skeleton;
    final mistakes = array(recipe['mistakes'] ?? const [], 'mistakes');
    final Map<String, Object?>? fault;
    if (mistake == null) {
      fault = null;
    } else {
      RangeError.checkValidIndex(mistake, mistakes, 'mistake');
      fault = object(mistakes[mistake], 'mistake');
      if (fault['shown'] == false) {
        throw ArgumentError.value(mistake, 'mistake', 'is not shown');
      }
    }

    final poses = _posesOf(recipe, fault);
    final normalized = <String, Pose>{};
    final times = <double>[];
    final keyPoses = <Pose>[];
    for (final keyJson in array(fault?['keys'] ?? recipe['keys'], 'keys')) {
      final key = array(keyJson, 'key');
      if (key.length != 2) bad('a key is [seconds, pose name]');
      final name = text(key[1], 'pose name');
      times.add(number(key[0], 'key time'));
      keyPoses.add(normalized[name] ??= skeleton.pose(poses(name)));
    }
    final first = Solved(skeleton.bones.length);
    for (final pose in normalized.values) {
      skeleton.measure(pose, first);
    }
    if (times.length < 2) bad('a clip needs two keys');
    for (var k = 1; k < times.length; k++) {
      if (times[k] <= times[k - 1]) bad('key times must rise');
      if (!keyPoses[k - 1].leadsTo(keyPoses[k])) {
        bad('key $k steps a foot given in a bone or drops a knee');
      }
    }

    skeleton.solve(keyPoses.first, first);
    final view = numbers(recipe['view'], 2, 'view');
    final motion = Motion._(
      skeleton,
      Float64List.fromList(times),
      keyPoses,
      Gear(skeleton, first, recipe['gear'], kits),
      [
        for (final bone in array(fault?['ring'] ?? const [], 'ring'))
          skeleton.index[text(bone, 'ring')] ?? bad('unknown ring bone $bone'),
      ],
      (view[0], view[1]),
    );
    motion._build();
    return motion;
  }

  final Skeleton _skeleton;
  final Float64List _times;
  final List<Pose> _poses;
  final Gear _gear;
  final List<int> _ring;
  final int _durationMicros;

  /// The recipe's `view`: the camera's yaw and pitch in degrees.
  final (double, double) view;

  late final MotionMesh _mesh;

  /// The gear, floor and shadow.
  MotionMesh get gear => _mesh;

  /// minX, minY, minZ, maxX, maxY, maxZ of the joints and the gear over the
  /// whole clip.
  final bounds = Float64List(6);

  Duration get duration => Duration(microseconds: _durationMicros);

  /// Body bones first (rig order), then one joint per gear piece, then the
  /// floor's and the shadow's.
  int get jointCount => _skeleton.bones.length + _gear.pieces.length + 2;

  int get markerCount => _ring.length;

  // Each gear piece's placement at the first key, inverted: its mesh is
  // stored there and its joint carries it on.
  final _firstInverse = <Matrix3>[];
  final _firstOffset = <Vector3>[];

  // Scratch for sampling.
  final _pose = Pose();
  final Solved _now;
  int? _solvedAt;
  final _linear = Matrix3.zero();
  final _offset = Vector3.zero();
  final _v = Vector3.zero();

  void _build() {
    final mesh = MeshBuilder(_skeleton.metres);
    final colours = <String>[];
    final bones = _skeleton.bones.length;
    for (var k = 0; k < _gear.pieces.length; k++) {
      final piece = _gear.pieces[k];
      final linear = Matrix3.zero(), offset = Vector3.zero();
      piece.place(_gear, linear, offset);
      if (!colours.contains(piece.colour)) colours.add(piece.colour);
      mesh.addPiece(
        shape: piece.shape,
        linear: linear,
        offset: offset,
        part: colours.indexOf(piece.colour),
        joint: bones + k,
      );
      _firstInverse.add(linear..invert());
      _firstOffset.add(offset);
    }
    if (jointCount > 256) bad('too many gear pieces');

    _measure(mesh);
    final metres = _skeleton.metres;
    final width = bounds[3] - bounds[0], depth = bounds[5] - bounds[2];
    mesh.addDisc(
      x: (bounds[0] + bounds[3]) / 2,
      y: 0,
      z: (bounds[2] + bounds[5]) / 2,
      radius: 0.48 * math.max(width, depth),
      part: colours.length,
      joint: jointCount - 2,
    );
    mesh.addDisc(
      x: 0,
      y: 0.001 / metres,
      z: 0,
      radius: 0.35 / metres,
      part: colours.length + 1,
      joint: jointCount - 1,
    );
    if (mesh.vertexCount > 65536) bad('the gear has too many vertices');
    _mesh = MotionMesh._(mesh, [...colours, 'floor', 'shadow']);
  }

  /// Fills [bounds] from the joints and the gear, sampled at every key and
  /// sixty times a second.
  void _measure(MeshBuilder mesh) {
    bounds.setAll(0, [
      double.infinity,
      double.infinity,
      double.infinity,
      double.negativeInfinity,
      double.negativeInfinity,
      double.negativeInfinity,
    ]);
    final frames = (_durationMicros / 1e6 * 60).ceil();
    final matrices = Float32List(jointCount * 12);
    final positions = Float32List(3);
    void include(double x, double y, double z) {
      bounds
        ..[0] = math.min(bounds[0], x)
        ..[1] = math.min(bounds[1], y)
        ..[2] = math.min(bounds[2], z)
        ..[3] = math.max(bounds[3], x)
        ..[4] = math.max(bounds[4], y)
        ..[5] = math.max(bounds[5], z);
    }

    for (final micros in [
      for (var f = 0; f < frames; f++) _durationMicros * f ~/ frames,
      for (final t in _times) (t * 1e6).round(),
    ]) {
      final time = Duration(microseconds: micros);
      sample(time, matrices);
      for (var b = 0; b < _skeleton.bones.length; b++) {
        _filePosition(_now.p[b], positions);
        include(positions[0], positions[1], positions[2]);
      }
      for (var v = 0; v < mesh.vertexCount; v++) {
        final m = mesh.joints[v] * 12;
        final x = mesh.positions[3 * v];
        final y = mesh.positions[3 * v + 1];
        final z = mesh.positions[3 * v + 2];
        include(
          matrices[m] * x +
              matrices[m + 1] * y +
              matrices[m + 2] * z +
              matrices[m + 3],
          matrices[m + 4] * x +
              matrices[m + 5] * y +
              matrices[m + 6] * z +
              matrices[m + 7],
          matrices[m + 8] * x +
              matrices[m + 9] * y +
              matrices[m + 10] * z +
              matrices[m + 11],
        );
      }
    }
  }

  /// Whether the motion comes to rest at key [k]: the first and the last
  /// key, a key that holds (the same pose as its neighbour) and one where
  /// the motion turns back (the same pose before and after). It passes
  /// through every other key at speed, so a mid pose shapes the path without
  /// a stop.
  bool _rests(int k) =>
      k == 0 ||
      k == _poses.length - 1 ||
      identical(_poses[k], _poses[k - 1]) ||
      identical(_poses[k], _poses[k + 1]) ||
      identical(_poses[k - 1], _poses[k + 1]);

  void _solve(Duration time) {
    final micros = time.inMicroseconds % _durationMicros;
    if (micros == _solvedAt) return;
    final seconds = micros / 1e6;
    var k = 0;
    while (k < _times.length - 2 && seconds > _times[k + 1]) {
      k++;
    }
    var from = k, to = k + 1;
    while (!_rests(from)) {
      from--;
    }
    while (!_rests(to)) {
      to++;
    }
    final span = _times[to] - _times[from];
    final eased =
        _times[from] +
        span * ease(((seconds - _times[from]) / span).clamp(0.0, 1.0));
    k = from;
    while (k < to - 1 && eased > _times[k + 1]) {
      k++;
    }
    final t = (eased - _times[k]) / (_times[k + 1] - _times[k]);
    _pose.setLerp(_poses[k], _poses[k + 1], t);
    _skeleton.solve(_pose, _now);
    _solvedAt = micros;
  }

  /// Writes 12 values per joint, a row-major 3x4 matrix that moves a vertex
  /// of the body file. Times past [duration] wrap.
  void sample(Duration time, Float32List out) {
    _solve(time);
    final bones = _skeleton.bones.length;
    for (var b = 0; b < bones; b++) {
      _v.setFrom(_skeleton.heads[b]);
      _now.r[b].transform(_v);
      _offset
        ..setFrom(_now.p[b])
        ..sub(_v);
      _write(out, b, _now.r[b], _offset);
    }
    _gear.now = _now;
    for (var k = 0; k < _gear.pieces.length; k++) {
      _gear.pieces[k].place(_gear, _linear, _offset);
      _linear.multiply(_firstInverse[k]);
      _linear.transformed(_firstOffset[k], _v);
      _offset.sub(_v);
      _write(out, bones + k, _linear, _offset);
    }
    _linear.setIdentity();
    _offset.setZero();
    _write(out, jointCount - 2, _linear, _offset);
    final pelvis = _now.p[_skeleton.pelvis];
    _offset.setValues(pelvis.x, pelvis.y, 0);
    _write(out, jointCount - 1, _linear, _offset);
  }

  /// Writes the position of every bone to mark for the mistake, three values
  /// each, at [time].
  void sampleMarkers(Duration time, Float32List out) {
    _solve(time);
    for (var i = 0; i < _ring.length; i++) {
      _filePosition(_now.p[_ring[i]], out, i * 3);
    }
  }

  /// Rig space (z up, facing -y, metres) to file space (y up, facing +z).
  void _filePosition(Vector3 p, Float32List out, [int at = 0]) {
    final metres = _skeleton.metres;
    out[at] = p.x / metres;
    out[at + 1] = p.z / metres;
    out[at + 2] = -p.y / metres;
  }

  void _write(Float32List out, int joint, Matrix3 m, Vector3 offset) {
    final o = joint * 12, metres = _skeleton.metres;
    out
      ..[o] = m.entry(0, 0)
      ..[o + 1] = m.entry(0, 2)
      ..[o + 2] = -m.entry(0, 1)
      ..[o + 3] = offset.x / metres
      ..[o + 4] = m.entry(2, 0)
      ..[o + 5] = m.entry(2, 2)
      ..[o + 6] = -m.entry(2, 1)
      ..[o + 7] = offset.z / metres
      ..[o + 8] = -m.entry(1, 0)
      ..[o + 9] = -m.entry(1, 2)
      ..[o + 10] = m.entry(1, 1)
      ..[o + 11] = -offset.y / metres;
  }
}

/// Looks up a pose of the clip by name, with what it extends folded in; a
/// mistake changes fields of the recipe's poses and may add poses of its own.
Map<String, Object?> Function(String) _posesOf(
  Map<String, Object?> recipe,
  Map<String, Object?>? fault,
) {
  final own = object(recipe['poses'], 'poses');
  final changes = object(
    fault?['poses'] ?? const <String, Object?>{},
    'mistake poses',
  );
  final done = <String, Map<String, Object?>>{};
  final pending = <String>{};
  Map<String, Object?> pose(String name) {
    if (done[name] case final pose?) return pose;
    if (!own.containsKey(name) && !changes.containsKey(name)) {
      bad('unknown pose $name');
    }
    if (!pending.add(name)) bad('pose $name extends itself');
    final spec = merged(
      object(own[name] ?? const <String, Object?>{}, 'pose $name'),
      object(changes[name] ?? const <String, Object?>{}, 'pose $name'),
    );
    final base = spec.remove('extends');
    return done[name] = base == null
        ? spec
        : merged(pose(text(base, 'extends')), spec);
  }

  return pose;
}
