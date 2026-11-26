import 'dart:typed_data';

import 'package:vector_math/vector_math_64.dart';

import 'json.dart';
import 'math.dart';

/// How far the grip point sits from the wrist: along the fingers, into the palm.
const _grip = (0.064, 0.036);
const _sides = ['L', 'R'];
const _signs = [1.0, -1.0];
const _trunk = ['pelvis', 'lumbar', 'chest', 'neck', 'head'];
const _limbs = [
  'clavicle', 'upper_arm', 'forearm', 'wrist', 'hand', 'fingers', //
  'fingertips', 'thumb', 'thigh', 'shin', 'foot', 'shoulder', 'elbow', 'hip',
  'knee',
];

// Where each field sits in a pose's values. Angles are in degrees.
const _pelvisRot = 3;
const _sideStart = 18;
const _sideSize = 24;
const _clavicle = 0;
const _handPos = 2;
const _fingers = 5;
const _palm = 8;
const _curl = 11;
const _elbow = 12;
const _footPos = 15; // pos, or at and an unused slot for a standing foot
const _yaw = 18;
const _pitch = 19;
const _floor = 20;
const _knee = 21;

/// A pose with both sides spelled out, as numbers that interpolate and a
/// structure that comes from the earlier key (see `lerp` in pose.py).
class Pose {
  final values = Float64List(_sideStart + 2 * _sideSize);

  /// The trunk bone a hand or foot is given in, or -1 for the world.
  final handRel = [-1, -1];
  final footRel = [-1, -1];
  final stands = [false, false];
  final hasKnee = [false, false];

  /// Whether a clip may ease from this pose to [next].
  bool leadsTo(Pose next) {
    for (var s = 0; s < 2; s++) {
      if (stands[s] != next.stands[s] || hasKnee[s] && !next.hasKnee[s]) {
        return false;
      }
    }
    return true;
  }

  void setLerp(Pose a, Pose b, double t) {
    for (var s = 0; s < 2; s++) {
      handRel[s] = a.handRel[s];
      footRel[s] = a.footRel[s];
      stands[s] = a.stands[s];
      hasKnee[s] = a.hasKnee[s];
    }
    for (var i = 0; i < values.length; i++) {
      values[i] = a.values[i] + (b.values[i] - a.values[i]) * t;
    }
  }
}

class _Side {
  _Side(Map<String, int> index, String side)
    : clavicle = index['clavicle_$side']!,
      upperArm = index['upper_arm_$side']!,
      forearm = index['forearm_$side']!,
      wrist = index['wrist_$side']!,
      hand = index['hand_$side']!,
      fingers = index['fingers_$side']!,
      fingertips = index['fingertips_$side']!,
      thumb = index['thumb_$side']!,
      thigh = index['thigh_$side']!,
      shin = index['shin_$side']!,
      foot = index['foot_$side']!,
      shoulder = index['shoulder_$side']!,
      elbow = index['elbow_$side']!,
      hip = index['hip_$side']!,
      knee = index['knee_$side']!;

  final int clavicle, upperArm, forearm, wrist, hand, fingers, fingertips;
  final int thumb, thigh, shin, foot, shoulder, elbow, hip, knee;
}

class _Rest {
  _Rest({
    required this.upperArm,
    required this.forearm,
    required this.hand,
    required this.thigh,
    required this.shin,
    required this.arm,
    required this.leg,
    required this.grip,
    required this.ball,
  });

  final Matrix3 upperArm, forearm, hand, thigh, shin;
  final (double, double) arm, leg;

  /// The grip point from the wrist, and the ball of the foot from the ankle.
  final Vector3 grip, ball;
}

/// World rotation and position of every bone.
class Solved {
  Solved(int bones)
    : r = List.generate(bones, (_) => Matrix3.zero()),
      p = List.generate(bones, (_) => Vector3.zero());

  final List<Matrix3> r;
  final List<Vector3> p;
}

/// The rig's joints and the solver of pose.py. Axes: z up, the body faces -y,
/// its left is +x; lengths in metres.
class Skeleton {
  Skeleton._(this.bones, this.heads, this.tails, this.metres) {
    for (var i = 0; i < bones.length; i++) {
      index[bones[i]] = i;
    }
    for (final name in [
      ..._trunk,
      for (final limb in _limbs)
        for (final side in _sides) '${limb}_$side',
    ]) {
      if (!index.containsKey(name)) bad('the rig has no bone $name');
    }
    if (index.length != bones.length || bones.length != 5 + 2 * _limbs.length) {
      bad('the rig has bones the solver does not pose');
    }
    pelvis = index['pelvis']!;
    chest = index['chest']!;
    _trunkBones = [for (final name in _trunk) index[name]!];
    _bones = [for (final side in _sides) _Side(index, side)];
  }

  factory Skeleton.fromJson(Map<String, Object?> json) {
    final bones = [
      for (final name in array(json['bone_names'], 'bone_names'))
        text(name, 'bone name'),
    ];
    List<Vector3> points(String key) {
      final list = array(json[key], key);
      if (list.length != bones.length) bad('$key needs one point per bone');
      return [for (final point in list) vec3(point, key)];
    }

    final skeleton = Skeleton._(
      bones,
      points('bone_heads'),
      points('bone_tails'),
      number(json['metres'], 'metres'),
    );
    final palms = array(json['palms'], 'palms');
    if (palms.length != 2) bad('palms needs two directions');
    for (var s = 0; s < 2; s++) {
      skeleton._rest.add(skeleton._restOf(s, vec3(palms[s], 'palms')));
    }
    return skeleton;
  }

  final List<String> bones;
  final List<Vector3> heads, tails;

  /// Metres per unit of the body file.
  final double metres;
  final index = <String, int>{};
  late final int pelvis, chest;
  late final List<int> _trunkBones;
  late final List<_Side> _bones;
  final _rest = <_Rest>[];

  _Rest _restOf(int s, Vector3 palm) {
    final b = _bones[s];
    final shoulder = heads[b.upperArm], elbow = heads[b.forearm];
    final wrist = heads[b.hand], fingers = tails[b.fingertips];
    final hip = heads[b.thigh], knee = heads[b.shin], ankle = heads[b.foot];
    final armNormal = (wrist - shoulder).normalized().cross(Vector3(0, 1, 0));
    final legNormal = (ankle - hip).normalized().cross(Vector3(0, -1, 0));
    Matrix3 frame(Vector3 axis, Vector3 normal) {
      final out = Matrix3.zero();
      setFrame(out, axis, normal);
      return out;
    }

    final hand = frame(fingers - wrist, (fingers - wrist).cross(palm));
    return _Rest(
      upperArm: frame(elbow - shoulder, armNormal),
      forearm: frame(wrist - elbow, armNormal),
      hand: hand,
      thigh: frame(knee - hip, legNormal),
      shin: frame(ankle - knee, legNormal),
      arm: ((elbow - shoulder).length, (wrist - elbow).length),
      leg: ((knee - hip).length, (ankle - knee).length),
      grip: hand.transformed(Vector3(_grip.$1, _grip.$2, 0)),
      ball: tails[b.foot] - ankle,
    );
  }

  /// A recipe pose (pose.py's fields) as a [Pose].
  Pose pose(Map<String, Object?> json) {
    final out = Pose();
    final v = out.values;
    void put(int at, List<double> numbers, {bool mirror = false}) {
      v.setAll(at, numbers);
      if (mirror) v[at] = -v[at];
    }

    put(0, numbers(json['pelvis'], 3, 'pelvis'));
    put(_pelvisRot, numbers(json['pelvis_rot'] ?? [0, 0, 0], 3, 'pelvis_rot'));
    for (var j = 1; j < _trunk.length; j++) {
      final angles = json[_trunk[j]] ?? 0;
      put(
        3 * j + 3,
        angles is num
            ? [angles.toDouble(), 0, 0]
            : numbers(angles, 3, _trunk[j]),
      );
    }
    int rel(Object? name) {
      if (name == null) return -1;
      final bone = text(name, 'rel');
      if (!_trunk.contains(bone)) bad('rel must name a trunk bone: $bone');
      return index[bone]!;
    }

    for (var s = 0; s < 2; s++) {
      final o = _sideStart + s * _sideSize;
      // The left side's fields are mirrored to the right unless it has its own.
      (Object?, bool) field(String key) {
        final own = json['${key}_${_sides[s]}'];
        return own != null ? (own, false) : (json[key], s == 1);
      }

      put(
        o + _clavicle,
        numbers(
          json['clavicle_${_sides[s]}'] ?? json['clavicle'] ?? [0, 0],
          2,
          'clavicle',
        ),
      );

      final (handJson, mirrorHand) = field('hand');
      final hand = object(handJson, 'hand');
      for (final (at, key) in [
        (_handPos, 'pos'),
        (_fingers, 'fingers'),
        (_palm, 'palm'),
      ]) {
        put(o + at, numbers(hand[key], 3, 'hand $key'), mirror: mirrorHand);
      }
      v[o + _curl] = number(hand['curl'] ?? 0, 'curl');
      out.handRel[s] = rel(hand['rel']);

      final (elbow, mirrorElbow) = field('elbow');
      put(
        o + _elbow,
        numbers(elbow ?? [0.3, 1.0, -0.3], 3, 'elbow'),
        mirror: mirrorElbow,
      );

      final (footJson, mirrorFoot) = field('foot');
      final foot = object(footJson, 'foot');
      out.stands[s] = foot.containsKey('at');
      put(
        o + _footPos,
        out.stands[s]
            ? [...numbers(foot['at'], 2, 'foot at'), 0]
            : numbers(foot['pos'], 3, 'foot pos'),
        mirror: mirrorFoot,
      );
      v[o + _yaw] = number(foot['yaw'] ?? 10, 'yaw');
      v[o + _pitch] = number(foot['pitch'] ?? 0, 'pitch');
      v[o + _floor] = number(foot['floor'] ?? 0, 'floor');
      out.footRel[s] = rel(foot['rel']);

      final (knee, mirrorKnee) = field('knee');
      out.hasKnee[s] = knee != null;
      if (knee != null) {
        put(o + _knee, numbers(knee, 3, 'knee'), mirror: mirrorKnee);
      }
    }
    return out;
  }

  // Scratch for solve.
  final _m = Matrix3.zero();
  final _hand = Matrix3.zero();
  final _curlTurn = Matrix3.zero();
  final _swing = Matrix3.zero();
  final _fingerDir = Vector3.zero();
  final _palmDir = Vector3.zero();
  final _root = Vector3.zero();
  final _target = Vector3.zero();
  final _pole = Vector3.zero();
  final _mid = Vector3.zero();
  final _end = Vector3.zero();
  final _normal = Vector3.zero();
  final _d = Vector3.zero();
  final _e = Vector3.zero();

  /// Places [bone] after its rotation is set: its head moves with [parent].
  void _place(Solved s, int bone, int parent) {
    s.p[bone]
      ..setFrom(heads[bone])
      ..sub(heads[parent]);
    s.r[parent].transform(s.p[bone]);
    s.p[bone].add(s.p[parent]);
  }

  void _world(
    Solved s,
    Pose pose,
    int at,
    int rel,
    Vector3 out, {
    required bool position,
  }) {
    final v = pose.values;
    out.setValues(v[at], v[at + 1], v[at + 2]);
    if (rel < 0) return;
    s.r[rel].transform(out);
    if (position) out.add(s.p[rel]);
  }

  /// World rotation and position of every bone for [pose].
  void solve(Pose pose, Solved s) {
    final v = pose.values, r = s.r, p = s.p;
    setEuler(r[pelvis], v[_pelvisRot], v[_pelvisRot + 1], v[_pelvisRot + 2]);
    p[pelvis].setValues(v[0], v[1], v[2]);
    for (var j = 1; j < _trunk.length; j++) {
      final b = _trunkBones[j], parent = _trunkBones[j - 1];
      setEuler(_m, v[3 * j + 3], v[3 * j + 4], v[3 * j + 5]);
      r[b]
        ..setFrom(r[parent])
        ..multiply(_m);
      _place(s, b, parent);
    }

    for (var side = 0; side < 2; side++) {
      final sign = _signs[side], rest = _rest[side];
      final o = _sideStart + side * _sideSize;
      final b = _bones[side];
      final clavicle = b.clavicle, upperArm = b.upperArm, forearm = b.forearm;
      final wrist = b.wrist, hand = b.hand, fingers = b.fingers;
      final fingertips = b.fingertips, thumb = b.thumb;
      final thigh = b.thigh, shin = b.shin, foot = b.foot;

      r[clavicle].setFrom(r[chest]);
      _m.setRotationZ(radians(-sign * v[o + _clavicle + 1]));
      r[clavicle].multiply(_m);
      _m.setRotationY(radians(-sign * v[o + _clavicle]));
      r[clavicle].multiply(_m);
      _place(s, clavicle, chest);

      final handRel = pose.handRel[side];
      _world(s, pose, o + _fingers, handRel, _fingerDir, position: false);
      _fingerDir.normalize();
      _world(s, pose, o + _palm, handRel, _palmDir, position: false);
      _fingerDir.crossInto(_palmDir, _d);
      setFrame(_hand, _fingerDir, _d);
      r[hand]
        ..setFrom(_hand)
        ..multiplyTranspose(rest.hand);
      final curl = radians(v[o + _curl]);
      _d.setValues(_hand.entry(0, 2), _hand.entry(1, 2), _hand.entry(2, 2));
      setRotationAxis(_curlTurn, _d, curl);
      r[fingers]
        ..setFrom(_curlTurn)
        ..multiply(r[hand]);
      r[fingertips]
        ..setFrom(_curlTurn)
        ..multiply(r[fingers]);
      _root
        ..setFrom(heads[upperArm])
        ..sub(heads[clavicle]);
      r[clavicle].transform(_root);
      _root.add(p[clavicle]);
      _pole.setValues(v[o + _elbow], v[o + _elbow + 1], v[o + _elbow + 2]);
      if (handRel >= 0) r[handRel].transform(_pole);
      _world(s, pose, o + _handPos, handRel, _target, position: true);
      _d.setValues(_grip.$1, _grip.$2, 0);
      _hand.transform(_d);
      _target.sub(_d);
      solveLimb(
        _root,
        _target,
        rest.arm.$1,
        rest.arm.$2,
        _pole,
        mid: _mid,
        end: _end,
        normal: _normal,
      );
      _d
        ..setFrom(_mid)
        ..sub(_root);
      setFrame(r[upperArm], _d, _normal);
      r[upperArm].multiplyTranspose(rest.upperArm);
      _d
        ..setFrom(_end)
        ..sub(_mid);
      setFrame(_swing, _d, _normal);
      _swing.multiplyTranspose(rest.forearm);
      _m
        ..setFrom(r[hand])
        ..multiplyTranspose(_swing);
      _e.setValues(
        rest.forearm.entry(0, 1),
        rest.forearm.entry(1, 1),
        rest.forearm.entry(2, 1),
      );
      _swing.transform(_e);
      final twist = twistAbout(_m, _d, _e);
      setRotationAxis(r[forearm], _d, twist / 3);
      r[forearm].multiply(_swing);
      setRotationAxis(r[wrist], _d, twist * 2 / 3);
      r[wrist].multiply(_swing);
      p[upperArm].setFrom(_root);
      p[forearm].setFrom(_mid);
      p[wrist]
        ..setFrom(_mid)
        ..add(_end)
        ..scale(0.5);
      p[hand].setFrom(_end);
      // The thumb closes round the fingers' direction, toward the palm.
      setRotationAxis(r[thumb], _fingerDir, sign * curl * 1.2);
      r[thumb].multiply(r[hand]);
      _place(s, fingers, hand);
      _place(s, fingertips, fingers);
      _place(s, thumb, hand);

      final footRel = pose.footRel[side];
      final turn = radians(sign * (v[o + _yaw] - 10));
      r[foot].setRotationZ(turn);
      _m.setRotationX(radians(v[o + _pitch]));
      r[foot].multiply(_m);
      if (footRel >= 0) {
        _m.setFrom(r[foot]);
        r[foot]
          ..setFrom(r[footRel])
          ..multiply(_m);
      }
      if (pose.hasKnee[side]) {
        _pole.setValues(v[o + _knee], v[o + _knee + 1], v[o + _knee + 2]);
        if (footRel >= 0) r[footRel].transform(_pole);
      } else {
        _pole.setValues(0, -1, 0);
        _m.setRotationZ(radians(sign * 10));
        _m.transform(_pole);
        r[foot].transform(_pole);
      }
      _root
        ..setFrom(heads[thigh])
        ..sub(heads[pelvis]);
      r[pelvis].transform(_root);
      _root.add(p[pelvis]);
      if (pose.stands[side]) {
        // The ball of the foot stays where the flat foot puts it.
        _target.setValues(
          v[o + _footPos],
          v[o + _footPos + 1],
          v[o + _floor] + heads[foot].z,
        );
        _m.setRotationZ(turn);
        _m.transformed(rest.ball, _d);
        _target.add(_d);
        r[foot].transformed(rest.ball, _d);
        _target.sub(_d);
      } else {
        _world(s, pose, o + _footPos, footRel, _target, position: true);
      }
      solveLimb(
        _root,
        _target,
        rest.leg.$1,
        rest.leg.$2,
        _pole,
        mid: _mid,
        end: _end,
        normal: _normal,
      );
      _d
        ..setFrom(_mid)
        ..sub(_root);
      setFrame(r[thigh], _d, _normal);
      r[thigh].multiplyTranspose(rest.thigh);
      _d
        ..setFrom(_end)
        ..sub(_mid);
      setFrame(r[shin], _d, _normal);
      r[shin].multiplyTranspose(rest.shin);
      p[thigh].setFrom(_root);
      p[shin].setFrom(_mid);
      p[foot].setFrom(_end);

      _helper(s, b.shoulder, clavicle, upperArm);
      _helper(s, b.elbow, upperArm, forearm);
      _helper(s, b.hip, pelvis, thigh);
      _helper(s, b.knee, thigh, shin);
    }
  }

  void _helper(Solved s, int helper, int above, int below) {
    setHalfway(s.r[helper], s.r[above], s.r[below]);
    s.p[helper].setFrom(s.p[below]);
  }

  /// Where hand [side] holds: the point the pose's hand pos asked for.
  void grip(Solved s, int side, Vector3 out) {
    final hand = _bones[side].hand;
    s.r[hand].transformed(_rest[side].grip, out);
    out.add(s.p[hand]);
  }
}
