import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:forge_model_viewer/src/gltf/glb_parser.dart';
import 'package:forge_model_viewer/src/model.dart';
import 'package:forge_model_viewer/src/render/mesh_renderer.dart';

import 'glb_builder.dart';

/// Two quads facing +z, raw: 'left' on joint 0, 'right' on joint 1.
Model3D _raw({
  List<String> partNames = const ['left', 'right'],
  int? vertexCount,
  List<double>? normals,
  List<int>? vertexParts,
  List<int>? indices,
  List<int>? joints = const [0, 0, 0, 0, 1, 1, 1, 1],
}) {
  final positions = [...quad(-1, -0.5, 0, 0.5, 0), ...quad(0, -0.5, 1, 0.5, 0)];
  final count = vertexCount ?? 8;
  return Model3D.fromMesh(
    partNames: partNames,
    positions: Float32List.fromList([
      for (var v = 0; v < count; v++)
        ...positions.sublist(v % 8 * 3, v % 8 * 3 + 3),
    ]),
    normals: Float32List.fromList(
      normals ??
          [
            for (var v = 0; v < count; v++) ...[0, 0, 1],
          ],
    ),
    vertexParts: Uint16List.fromList(
      vertexParts ?? [for (var v = 0; v < count; v++) v % 8 ~/ 4],
    ),
    indices: Uint16List.fromList(
      indices ?? [...quadIndices, for (final i in quadIndices) i + 4],
    ),
    joints: joints == null ? null : Uint8List.fromList(joints),
  );
}

void main() {
  group('Model3D.fromMesh', () {
    test('draws like the same model from a GLB', () {
      final glb = parseGlb(
        quadsGlb({
          'left': quad(-1, -0.5, 0, 0.5, 0),
          'right': quad(0, -0.5, 1, 0.5, 0),
        }),
      );
      final model = _raw(joints: null);
      final mesh = meshOf(model);
      expect(model.partNames, ['left', 'right']);
      expect(model.jointCount, 0);
      expect(mesh.bounds, glb.bounds);
      final expected = MeshRenderer(glb)..update(200, 200, 0.3, 0.2, 1);
      final raw = MeshRenderer(mesh)..update(200, 200, 0.3, 0.2, 1);
      expect(raw.screen, expected.screen);
      expect(raw.drawIndices, expected.drawIndices);
      for (final renderer in [expected, raw]) {
        renderer.partColors
          ..[0] = 0xFFFF0000
          ..[1] = 0xFF0000FF;
        renderer.shade();
      }
      expect(raw.colors, expected.colors);
    });

    test('binds every vertex fully to its joint', () {
      final model = _raw();
      final mesh = meshOf(model);
      expect(model.jointCount, 2);
      expect(mesh.joints, [
        for (final joint in [0, 0, 0, 0, 1, 1, 1, 1]) ...[joint, 0, 0, 0],
      ]);
      expect(mesh.weights, [
        for (var v = 0; v < 8; v++) ...[1, 0, 0, 0],
      ]);
    });

    group('rejects', () {
      test('lengths that disagree', () {
        expect(() => _raw(normals: [0, 0, 1]), throwsArgumentError);
        expect(() => _raw(joints: [0, 0, 0, 0]), throwsArgumentError);
        expect(
          () => _raw(vertexParts: [0, 0, 0, 0, 1, 1, 1]),
          throwsArgumentError,
        );
        expect(() => _raw(indices: [0, 1, 2, 0]), throwsArgumentError);
        expect(() => _raw(indices: []), throwsArgumentError);
      });

      test('indices out of range', () {
        expect(() => _raw(indices: [0, 1, 8]), throwsArgumentError);
        expect(
          () => _raw(vertexParts: [0, 0, 0, 0, 1, 1, 1, 2]),
          throwsArgumentError,
        );
      });

      test('a repeated part name', () {
        expect(() => _raw(partNames: ['a', 'a']), throwsArgumentError);
      });

      test('more than 65,536 vertices', () {
        expect(
          _raw(vertexCount: maxVertices, joints: null).partNames,
          hasLength(2),
        );
        expect(
          () => _raw(vertexCount: maxVertices + 1, joints: null),
          throwsArgumentError,
        );
      });
    });

    test('joined with a skinned GLB model, poses on shared joints', () async {
      // The body's quad on joint 0, the raw gear's on joint 1.
      final body = await Model3D.fromGlb(
        skinnedQuadsGlb({'body': quad(-1, -0.5, 0, 0.5, 0)}, [0]),
      );
      final gear = Model3D.fromMesh(
        partNames: ['bar'],
        positions: Float32List.fromList(quad(0, -0.5, 1, 0.5, 0)),
        normals: Float32List.fromList([
          for (var v = 0; v < 4; v++) ...[0, 0, 1],
        ]),
        vertexParts: Uint16List(4),
        indices: Uint16List.fromList(quadIndices),
        joints: Uint8List.fromList([1, 1, 1, 1]),
      );
      final joined = Model3D.joined([body, gear]);
      expect(joined.partNames, ['body', 'bar']);
      expect(joined.jointCount, 2);
      final renderer = MeshRenderer(
        meshOf(joined),
        bounds: Float64List.fromList([-1, -0.5, 0, 1, 1.5, 0]),
      )..update(200, 200, 0, 0, 1);
      final rest = Float32List.fromList(renderer.screen);
      renderer
        ..pose(
          Float32List.fromList([
            ...translation(0, 0, 0),
            ...translation(0, 1, 0),
          ]),
        )
        ..update(200, 200, 0, 0, 1);
      final s = renderer.screen;
      for (var v = 0; v < 8; v++) {
        expect(s[v * 2], closeTo(rest[v * 2], 1e-3));
        if (v < 4) {
          expect(s[v * 2 + 1], closeTo(rest[v * 2 + 1], 1e-3));
        } else {
          expect(s[v * 2 + 1], lessThan(rest[v * 2 + 1] - 10));
        }
      }
    });
  });

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
