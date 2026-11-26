import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:forge_motion/forge_motion.dart';
import 'package:test/test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'fixtures.dart';

void main() {
  final golden = jsonDecode(
    File('test/fixtures/golden.json').readAsStringSync(),
  ) as Map<String, Object?>;

  for (final MapEntry(key: name, value: clips) in golden.entries) {
    for (final clip in (clips! as List<Object?>).cast<Map<String, Object?>>()) {
      final mistake = clip['mistake'] as int?;
      test(
        '$name, ${mistake == null ? 'correct form' : 'mistake $mistake'}',
        () {
          final motion = Motion(
            rig: rig,
            kits: kits,
            recipe: recipe(name),
            mistake: mistake,
          );
          expect(motion.duration, seconds(clip['duration']! as num));
          final samples = (clip['samples']! as List<Object?>)
              .cast<Map<String, Object?>>();
          final bones = rig.bones.length;
          final first = samples.first['gear']! as List<Object?>;
          expect(motion.jointCount, bones + first.length + 2);

          // The mesh holds each piece where the first key puts it; through the
          // golden placement there, its vertices are the unit shape's.
          final pieces = [
            for (final (k, piece) in first.cast<Map<String, Object?>>().indexed)
              _Piece(motion.gear, bones + k, piece),
          ];
          expect(samples.first['t'], 0);

          final out = Float32List(motion.jointCount * 12);
          for (final sample in samples) {
            motion.sample(seconds(sample['t']! as num), out);
            final joints = (sample['joints']! as List<Object?>);
            for (var b = 0; b < bones; b++) {
              final want = _rows(joints[b]);
              for (var i = 0; i < 12; i++) {
                expect(
                  out[b * 12 + i],
                  closeTo(want[i], tolerance),
                  reason: '${rig.bones[b]} at ${sample['t']}',
                );
              }
            }
            final gear = (sample['gear']! as List<Object?>)
                .cast<Map<String, Object?>>();
            for (final (k, piece) in gear.indexed) {
              pieces[k].check(out, _rows(piece['matrix']), '${sample['t']}');
            }
          }
        },
      );
    }
  }
}

const tolerance = 1e-4;

List<double> _rows(Object? matrix) => [
  for (final row in matrix! as List<Object?>)
    for (final v in row! as List<Object?>) (v! as num).toDouble(),
];

/// A 3x4 row-major matrix as a 4x4 one.
Matrix4 _matrix(List<double> rows) => Matrix4(
  rows[0],
  rows[4],
  rows[8],
  0, //
  rows[1],
  rows[5],
  rows[9],
  0,
  rows[2],
  rows[6],
  rows[10],
  0,
  rows[3],
  rows[7],
  rows[11],
  1,
);

class _Piece {
  _Piece(MotionMesh mesh, this.joint, Map<String, Object?> golden) {
    final placement = _matrix(_rows(golden['matrix']));
    final inverse = Matrix4.inverted(placement);
    for (var v = 0; v < mesh.joints.length; v++) {
      if (mesh.joints[v] != joint) continue;
      expect(mesh.partNames[mesh.vertexParts[v]], golden['colour']);
      final stored = Vector3(
        mesh.positions[3 * v],
        mesh.positions[3 * v + 1],
        mesh.positions[3 * v + 2],
      );
      vertices.add(stored);
      unit.add(inverse.transformed3(stored));
    }
    expect(vertices, isNotEmpty);
    final cylinder = golden['shape'] == 'cyl';
    for (final u in unit) {
      final onSurface = cylinder
          ? (u.x * u.x + u.y * u.y - 1).abs() < 1e-3 &&
                    u.z.abs() <= 0.5 + 1e-3 ||
                (u.z.abs() - 0.5).abs() < 1e-3 &&
                    u.x * u.x + u.y * u.y <= 1 + 1e-3
          : [u.x, u.y, u.z].every((c) => c.abs() <= 0.5 + 1e-3) &&
                [u.x, u.y, u.z].any((c) => (c.abs() - 0.5).abs() < 1e-3);
      expect(
        onSurface,
        isTrue,
        reason: '$u is not on a unit ${golden['shape']}',
      );
    }
  }

  final int joint;
  final vertices = <Vector3>[];
  final unit = <Vector3>[];

  /// Where the joint moves each vertex is where [placement] puts its unit point.
  void check(Float32List out, List<double> placement, String at) {
    final moved = _matrix(out.sublist(joint * 12, joint * 12 + 12));
    final placed = _matrix(placement);
    for (var i = 0; i < vertices.length; i++) {
      final got = moved.transformed3(vertices[i]);
      final want = placed.transformed3(unit[i]);
      expect(
        (got - want).length,
        lessThan(tolerance),
        reason: 'piece joint $joint at $at',
      );
    }
  }
}
