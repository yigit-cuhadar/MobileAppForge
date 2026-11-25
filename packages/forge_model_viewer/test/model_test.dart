import 'package:flutter_test/flutter_test.dart';
import 'package:forge_model_viewer/src/model.dart';

import 'glb_builder.dart';

void main() {
  group('Model3D.joined', () {
    test('merges parts by name and offsets indices', () async {
      final body = await Model3D.fromGlb(
        quadsGlb({'a': quad(0, 0, 1, 1, 0), 'b': quad(1, 0, 2, 1, 0)}),
      );
      final gear = await Model3D.fromGlb(
        quadsGlb({'c': quad(-3, -1, -2, 0, 1), 'a': quad(0, 1, 1, 2, 0)}),
      );
      final joined = Model3D.joined([body, gear]);
      final mesh = meshOf(joined);

      expect(joined.partNames, ['a', 'b', 'c']);
      expect(mesh.vertexCount, 16);
      expect(mesh.vertexParts, [
        ...[0, 0, 0, 0, 1, 1, 1, 1],
        ...[2, 2, 2, 2, 0, 0, 0, 0],
      ]);
      expect(mesh.indices.sublist(12), [
        for (final base in [8, 12])
          for (final i in quadIndices) base + i,
      ]);
      expect(mesh.positions.sublist(24, 27), [-3, -1, 1]);
      expect(mesh.bounds, [-3, -1, 0, 2, 2, 1]);
      expect(mesh.joints, isNull);
      expect(joined.jointCount, 0);
    });

    test('joins skin data on shared joints', () async {
      final body = await Model3D.fromGlb(
        skinnedQuadsGlb({'a': quad(0, 0, 1, 1, 0)}, [1]),
      );
      final gear = await Model3D.fromGlb(
        skinnedQuadsGlb({'bar': quad(0, 1, 1, 2, 0)}, [3]),
      );
      final joined = Model3D.joined([body, gear]);
      final mesh = meshOf(joined);
      expect(mesh.joints, [
        for (var v = 0; v < 4; v++) ...[1, 0, 0, 0],
        for (var v = 0; v < 4; v++) ...[3, 0, 0, 0],
      ]);
      expect(mesh.weights, hasLength(32));
      expect(joined.jointCount, 4);
    });

    test('rejects mixing skinned and unskinned models', () async {
      final skinned = await Model3D.fromGlb(
        skinnedQuadsGlb({'a': quad(0, 0, 1, 1, 0)}, [0]),
      );
      final plain = await Model3D.fromGlb(quadsGlb({'b': quad(0, 0, 1, 1, 0)}));
      expect(() => Model3D.joined([skinned, plain]), throwsArgumentError);
    });

    test('rejects more than 65,536 vertices in all', () async {
      // Two halves of 32,769 vertices each.
      final b = GlbBuilder();
      final bytes = b.build(
        nodes: [
          {'mesh': 0},
        ],
        meshes: [
          {
            'primitives': [
              {
                'attributes': {
                  'POSITION': b.addVec3([
                    for (var t = 0; t < 10923; t++) ...[
                      0,
                      0,
                      0,
                      1,
                      0,
                      0,
                      0,
                      1,
                      0,
                    ],
                  ]),
                },
              },
            ],
          },
        ],
      );
      final half = await Model3D.fromGlb(bytes);
      expect(() => Model3D.joined([half, half]), throwsArgumentError);
    });
  });
}
