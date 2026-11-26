import 'dart:math' as math;
import 'dart:typed_data';

import 'package:forge_motion/forge_motion.dart';
import 'package:test/test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'fixtures.dart';

const cell = 0.09;

void main() {
  final metres = (rigJson['metres']! as num).toDouble();
  // Bone heads in file space: y up, facing +z, the file's unit.
  final heads = [
    for (final head in rigJson['bone_heads']! as List<Object?>)
      Vector3.array([
        for (final v in head! as List<Object?>) (v! as num).toDouble() / metres,
      ]),
  ].map((h) => Vector3(h.x, h.z, -h.y)).toList();

  Vector3 moved(Float32List out, int joint, Vector3 p) => Vector3(
    out[joint * 12] * p.x +
        out[joint * 12 + 1] * p.y +
        out[joint * 12 + 2] * p.z +
        out[joint * 12 + 3],
    out[joint * 12 + 4] * p.x +
        out[joint * 12 + 5] * p.y +
        out[joint * 12 + 6] * p.z +
        out[joint * 12 + 7],
    out[joint * 12 + 8] * p.x +
        out[joint * 12 + 9] * p.y +
        out[joint * 12 + 10] * p.z +
        out[joint * 12 + 11],
  );

  List<Duration> times(Motion motion) => [
    for (final f in [0.0, 0.13, 0.37, 0.5, 0.71, 0.94])
      Duration(microseconds: (motion.duration.inMicroseconds * f).round()),
  ];

  for (final name in recipes) {
    group(name, () {
      final motion = Motion(rig: rig, kits: kits, recipe: recipe(name));
      final bones = rig.bones.length;
      final mesh = motion.gear;

      test('loops: a time past the duration wraps', () {
        final a = Float32List(motion.jointCount * 12);
        final b = Float32List(motion.jointCount * 12);
        for (final t in times(motion)) {
          motion.sample(t, a);
          motion.sample(t + motion.duration, b);
          expect(b, a);
        }
      });

      test('bounds hold every joint and the gear', () {
        final out = Float32List(motion.jointCount * 12);
        final low = Vector3.array(motion.bounds.sublist(0, 3));
        final high = Vector3.array(motion.bounds.sublist(3));
        void within(Vector3 p) {
          for (var axis = 0; axis < 3; axis++) {
            expect(
              p[axis],
              inInclusiveRange(low[axis] - 1e-4, high[axis] + 1e-4),
            );
          }
        }

        for (final t in times(motion)) {
          motion.sample(t, out);
          for (var b = 0; b < bones; b++) {
            within(moved(out, b, heads[b]));
          }
          for (var v = 0; v < mesh.joints.length; v++) {
            if (mesh.joints[v] >= motion.jointCount - 2) continue;
            within(
              moved(out, mesh.joints[v], Vector3.array(mesh.positions, 3 * v)),
            );
          }
        }
      });

      test('the floor stays put and the shadow under the pelvis', () {
        final out = Float32List(motion.jointCount * 12);
        final floor = motion.jointCount - 2, shadow = motion.jointCount - 1;
        for (final t in times(motion)) {
          motion.sample(t, out);
          expect(out.sublist(floor * 12, floor * 12 + 12), [
            1,
            0,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            0,
            1,
            0,
          ]);
          final pelvis = moved(out, 0, heads[0]);
          expect(out.sublist(shadow * 12, shadow * 12 + 12), [
            1, 0, 0, closeTo(pelvis.x, 1e-6), //
            0, 1, 0, 0,
            0, 0, 1, closeTo(pelvis.z, 1e-6),
          ]);
        }
        final floorVertices = [
          for (var v = 0; v < mesh.joints.length; v++)
            if (mesh.partNames[mesh.vertexParts[v]] == 'floor') v,
        ];
        expect(floorVertices.map((v) => mesh.joints[v]), everyElement(floor));
        expect(
          floorVertices.map((v) => mesh.positions[3 * v + 1]),
          everyElement(0),
        );
        final b = motion.bounds;
        final radius = floorVertices
            .map(
              (v) => math.sqrt(
                math.pow(mesh.positions[3 * v] - (b[0] + b[3]) / 2, 2) +
                    math.pow(mesh.positions[3 * v + 2] - (b[2] + b[5]) / 2, 2),
              ),
            )
            .reduce(math.max);
        expect(
          radius,
          closeTo(0.48 * math.max(b[3] - b[0], b[5] - b[2]), 1e-5),
        );
        final shadowRadius = [
          for (var v = 0; v < mesh.joints.length; v++)
            if (mesh.joints[v] == shadow)
              Vector2(mesh.positions[3 * v], mesh.positions[3 * v + 2]).length,
        ].reduce(math.max);
        expect(shadowRadius * metres, closeTo(0.35, 1e-5));
      });

      test('the mesh is whole, faces outward and is cut into small cells', () {
        final count = mesh.joints.length;
        expect(mesh.positions.length, count * 3);
        expect(mesh.normals.length, count * 3);
        expect(mesh.vertexParts.length, count);
        expect(mesh.indices.length % 3, 0);
        expect(mesh.indices, everyElement(lessThan(count)));
        expect(
          mesh.joints,
          everyElement(inInclusiveRange(bones, motion.jointCount - 1)),
        );
        expect(mesh.vertexParts, everyElement(lessThan(mesh.partNames.length)));
        expect(mesh.partNames, containsAllInOrder(['floor', 'shadow']));
        Vector3 at(Float32List list, int v) => Vector3.array(list, 3 * v);
        for (var v = 0; v < count; v++) {
          expect(at(mesh.normals, v).length, closeTo(1, 1e-5));
        }
        for (var i = 0; i < mesh.indices.length; i += 3) {
          final [a, b, c] = [
            for (var k = 0; k < 3; k++) at(mesh.positions, mesh.indices[i + k]),
          ];
          final edges = [(b - a).length, (c - b).length, (a - c).length]
            ..sort();
          expect(edges[1] * metres, lessThan(cell * 1.001));
          final face = (b - a).cross(c - a);
          if (face.length * metres * metres < 1e-8) continue;
          final normal =
              at(mesh.normals, mesh.indices[i]) +
              at(mesh.normals, mesh.indices[i + 1]) +
              at(mesh.normals, mesh.indices[i + 2]);
          expect(face.dot(normal), greaterThan(0));
        }
      });
    });
  }

  group('mistakes', () {
    test('markers follow their bones', () {
      final motion = Motion(
        rig: rig,
        kits: kits,
        recipe: recipe('stand_and_sit'),
        mistake: 0,
      );
      expect(motion.markerCount, 2);
      final out = Float32List(motion.jointCount * 12);
      final markers = Float32List(motion.markerCount * 3);
      for (final t in times(motion)) {
        motion.sampleMarkers(t, markers);
        motion.sample(t, out);
        for (final (i, bone) in ['knee_L', 'knee_R'].indexed) {
          final b = rig.bones.indexOf(bone);
          final want = moved(out, b, heads[b]);
          expect(
            Vector3.array(markers, 3 * i).distanceTo(want),
            lessThan(1e-6),
          );
        }
      }
    });

    test('the correct form has no markers', () {
      expect(
        Motion(
          rig: rig,
          kits: kits,
          recipe: recipe('stand_and_sit'),
        ).markerCount,
        0,
      );
    });

    test('a mistake with its own keys has its own duration', () {
      final motion = Motion(
        rig: rig,
        kits: kits,
        recipe: recipe('stand_and_sit'),
        mistake: 1,
      );
      expect(motion.duration, seconds(3.6));
    });

    test('a mistake that is not shown throws', () {
      expect(
        () => Motion(
          rig: rig,
          kits: kits,
          recipe: recipe('stand_and_sit'),
          mistake: 2,
        ),
        throwsArgumentError,
      );
    });
  });

  test('view is the recipe view', () {
    expect(Motion(rig: rig, kits: kits, recipe: recipe('hang_and_pull')).view, (
      160,
      5,
    ));
  });

  group('the format', () {
    Motion changed(void Function(Map<String, Object?> recipe) change) {
      final spec = recipe('lie_and_press');
      change(spec);
      return Motion(rig: rig, kits: kits, recipe: spec);
    }

    test('rejects an unknown kit', () {
      expect(
        () =>
            changed((r) => (r['gear']! as List<Object?>).add({'kit': 'sled'})),
        throwsFormatException,
      );
    });

    test('rejects an unknown pose in the keys', () {
      expect(
        () => changed(
          (r) => (r['keys']! as List<Object?>).insert(1, [0.5, 'side']),
        ),
        throwsFormatException,
      );
    });

    test('rejects an unknown mover', () {
      final kitSet = {
        ...kits,
        'sled': {
          'pieces': [
            {
              'box': {
                'at': [0, 0, 0],
                'with': 'slide',
              },
              'size': [1, 1, 1],
            },
          ],
        },
      };
      final spec = recipe('lie_and_press');
      (spec['gear']! as List<Object?>).add({'kit': 'sled'});
      expect(
        () => Motion(rig: rig, kits: kitSet, recipe: spec),
        throwsFormatException,
      );
    });
  });
}
