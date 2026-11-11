import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:forge_model_viewer/forge_model_viewer.dart';
import 'package:forge_model_viewer/src/gltf/glb_parser.dart';

import 'glb_builder.dart';

List<double> _vertex(Float32List data, int i) => [
  data[i * 3],
  data[i * 3 + 1],
  data[i * 3 + 2],
];

Matcher _closeList(List<double> expected) => pairwiseCompare<double, double>(
  expected,
  (a, b) => (a - b).abs() < 1e-5,
  'close to',
);

/// ROOT (translate y+1, scale 2) with two children: "left" (computed normals,
/// u16 indices) and "right" (matrix moving it x+1, normals, u8 indices).
Uint8List _twoPartGlb() {
  final b = GlbBuilder();
  final leftPositions = b.addVec3(quad(-1, 0, 0, 1, 0));
  final leftIndices = b.addIndices(quadIndices);
  final rightPositions = b.addVec3(quad(-1, 0, 0, 1, 0));
  final rightNormals = b.addVec3([
    for (var i = 0; i < 4; i++) ...[0, 0, 1],
  ]);
  final rightIndices = b.addIndices(quadIndices, componentType: 5121);
  return b.build(
    sceneNodes: [0],
    nodes: [
      {
        'name': 'ROOT',
        'children': [1, 2],
        'translation': [0, 1, 0],
        'scale': [2, 2, 2],
      },
      {'name': 'left', 'mesh': 0},
      {
        'name': 'right',
        'mesh': 1,
        'matrix': [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1],
      },
    ],
    meshes: [
      {
        'primitives': [
          {
            'attributes': {'POSITION': leftPositions},
            'indices': leftIndices,
          },
        ],
      },
      {
        'primitives': [
          {
            'attributes': {'POSITION': rightPositions, 'NORMAL': rightNormals},
            'indices': rightIndices,
          },
        ],
      },
    ],
  );
}

Uint8List _singlePrimitive(
  Map<String, Object?> Function(GlbBuilder b) primitive, {
  Map<String, Object?> node = const {},
  Map<String, Object?> extra = const {},
}) {
  final b = GlbBuilder();
  final p = primitive(b);
  return b.build(
    nodes: [
      {'name': 'part', 'mesh': 0, ...node},
    ],
    meshes: [
      {
        'primitives': [p],
      },
    ],
    extra: extra,
  );
}

void main() {
  group('parseGlb', () {
    test('reads parts, node transforms and bounds', () async {
      final model = await Model3D.fromGlb(_twoPartGlb());

      expect(model.partNames, ['left', 'right']);
      expect(model.vertexCount, 8);
      expect(model.triangleCount, 4);
      // left: x -2..0, right: x 0..2 after ROOT scale; y 1..3 after ROOT.
      expect(_vertex(model.positions, 0), _closeList([-2, 1, 0]));
      expect(_vertex(model.positions, 4), _closeList([0, 1, 0]));
      expect(model.bounds.min.storage, _closeList([-2, 1, 0]));
      expect(model.bounds.max.storage, _closeList([2, 3, 0]));
      expect(model.vertexParts, [0, 0, 0, 0, 1, 1, 1, 1]);
      expect(model.indices, [0, 1, 2, 0, 2, 3, 4, 5, 6, 4, 6, 7]);
    });

    test('computes normals when absent and keeps given ones', () {
      final model = parseGlb(_twoPartGlb());
      for (var v = 0; v < 8; v++) {
        expect(_vertex(model.normals, v), _closeList([0, 0, 1]));
      }
    });

    test('rotates normals with the node', () {
      final model = parseGlb(
        _singlePrimitive(
          (b) => {
            'attributes': {
              'POSITION': b.addVec3(quad(0, 0, 1, 1, 0)),
              'NORMAL': b.addVec3([
                for (var i = 0; i < 4; i++) ...[0, 0, 1],
              ]),
            },
            'indices': b.addIndices(quadIndices),
          },
          node: {
            // 90 degrees around y: +z turns to +x.
            'rotation': [0, math.sin(math.pi / 4), 0, math.cos(math.pi / 4)],
          },
        ),
      );
      expect(_vertex(model.normals, 0), _closeList([1, 0, 0]));
    });

    test('reads u32 indices and non-indexed triangles', () {
      final indexed = parseGlb(
        _singlePrimitive(
          (b) => {
            'attributes': {'POSITION': b.addVec3(quad(0, 0, 1, 1, 0))},
            'indices': b.addIndices(quadIndices, componentType: 5125),
          },
        ),
      );
      expect(indexed.indices, quadIndices);

      final plain = parseGlb(
        _singlePrimitive(
          (b) => {
            'attributes': {
              'POSITION': b.addVec3([0, 0, 0, 1, 0, 0, 0, 1, 0]),
            },
          },
        ),
      );
      expect(plain.indices, [0, 1, 2]);
    });

    test('flips winding under a mirroring transform', () {
      final model = parseGlb(
        _singlePrimitive(
          (b) => {
            'attributes': {
              'POSITION': b.addVec3([0, 0, 0, 1, 0, 0, 0, 1, 0]),
            },
          },
          node: {
            'scale': [-1, 1, 1],
          },
        ),
      );
      expect(model.indices, [0, 2, 1]);
      expect(_vertex(model.normals, 0), _closeList([0, 0, 1]));
    });

    test('merges nodes with the same name into one part', () {
      final b = GlbBuilder();
      final positions = b.addVec3([0, 0, 0, 1, 0, 0, 0, 1, 0]);
      final mesh = {
        'primitives': [
          {
            'attributes': {'POSITION': positions},
          },
        ],
      };
      final model = parseGlb(
        b.build(
          nodes: [
            {'name': 'a', 'mesh': 0},
            {'name': 'a', 'mesh': 0},
          ],
          meshes: [mesh],
        ),
      );
      expect(model.partNames, ['a']);
      expect(model.vertexCount, 6);
    });

    group('rejects', () {
      Matcher fails(String message) => throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains(message),
        ),
      );

      Map<String, Object?> triangle(GlbBuilder b) => {
        'attributes': {
          'POSITION': b.addVec3([0, 0, 0, 1, 0, 0, 0, 1, 0]),
        },
      };

      test('non-GLB bytes', () {
        expect(
          () => parseGlb(Uint8List.fromList(utf8.encode('{"asset":{}} pad'))),
          fails('Not a GLB'),
        );
      });

      test('glTF 1', () {
        expect(
          () => parseGlb(glb(utf8.encode('{}'), Uint8List(0), version: 1)),
          fails('version 1'),
        );
      });

      test('Draco and other required extensions', () {
        expect(
          () => parseGlb(
            _singlePrimitive(
              triangle,
              extra: {
                'extensionsRequired': ['KHR_draco_mesh_compression'],
              },
            ),
          ),
          fails('KHR_draco_mesh_compression'),
        );
      });

      test('sparse accessors', () {
        final b = GlbBuilder();
        final primitive = triangle(b);
        b.accessors[0]['sparse'] = {'count': 1};
        expect(
          () => parseGlb(
            b.build(
              nodes: [
                {'mesh': 0},
              ],
              meshes: [
                {
                  'primitives': [primitive],
                },
              ],
            ),
          ),
          fails('Sparse'),
        );
      });

      test('non-triangle modes', () {
        expect(
          () => parseGlb(_singlePrimitive((b) => {...triangle(b), 'mode': 1})),
          fails('mode 1'),
        );
      });

      test('external buffers', () {
        expect(
          () => parseGlb(
            _singlePrimitive(
              triangle,
              extra: {
                'buffers': [
                  {'byteLength': 36, 'uri': 'model.bin'},
                ],
              },
            ),
          ),
          fails('embedded'),
        );
      });

      test('models without triangles', () {
        expect(
          () => parseGlb(GlbBuilder().build(nodes: [{}], meshes: [])),
          fails('no triangles'),
        );
      });

      test('malformed JSON structure', () {
        expect(
          () => parseGlb(
            GlbBuilder().build(
              nodes: [
                {'mesh': 3},
              ],
              meshes: [],
            ),
          ),
          fails('Malformed'),
        );
      });
    });
  });
}
