import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:forge_model_viewer/forge_model_viewer.dart';
import 'package:forge_model_viewer/src/gltf/glb_parser.dart';
import 'package:forge_model_viewer/src/model.dart';
import 'package:forge_model_viewer/src/render/mesh_renderer.dart';

import 'glb_builder.dart';

bool _all(String part) => true;

/// A 2 x 2 x 2 cube: one +z face reused by six rotated nodes.
MeshData _cube() {
  final b = GlbBuilder();
  final positions = b.addVec3(quad(-1, -1, 1, 1, 1));
  final indices = b.addIndices(quadIndices);
  const h = math.sqrt1_2;
  final rotations = [
    [0.0, 0.0, 0.0, 1.0],
    [0.0, 1.0, 0.0, 0.0],
    [0.0, h, 0.0, h],
    [0.0, -h, 0.0, h],
    [-h, 0.0, 0.0, h],
    [h, 0.0, 0.0, h],
  ];
  return parseGlb(
    b.build(
      nodes: [
        for (final rotation in rotations)
          {'name': 'cube', 'mesh': 0, 'rotation': rotation},
      ],
      meshes: [
        {
          'primitives': [
            {
              'attributes': {'POSITION': positions},
              'indices': indices,
            },
          ],
        },
      ],
    ),
  );
}

void main() {
  // A small quad in front of a large one; both face the camera.
  final layered = parseGlb(
    quadsGlb({
      'front': quad(-0.5, -0.5, 0.5, 0.5, 0.5),
      'back': quad(-1, -1, 1, 1, -0.5),
    }),
  );
  const size = 200.0, center = size / 2;

  group('projection', () {
    test('centres the model and keeps y up', () {
      final renderer = MeshRenderer(
        parseGlb(quadsGlb({'q': quad(-1, -1, 1, 1, 0)})),
      )..update(size, size, 0, 0, 1);
      final s = renderer.screen;
      // Vertex 0 is bottom-left, vertex 2 top-right.
      expect(s[0] + s[4], closeTo(size, 1e-3));
      expect(s[1] + s[5], closeTo(size, 1e-3));
      expect(s[0], lessThan(center));
      expect(s[1], greaterThan(center));
    });

    test('zoom scales offsets in the centre plane', () {
      final renderer = MeshRenderer(
        parseGlb(quadsGlb({'q': quad(-1, -1, 1, 1, 0)})),
      )..update(size, size, 0, 0, 1);
      final offset = center - renderer.screen[0];
      renderer.update(size, size, 0, 0, 2);
      expect(center - renderer.screen[0], closeTo(offset * 2, 1e-3));
    });

    test('positive yaw moves the front to the right', () {
      final renderer = MeshRenderer(layered)..update(size, size, 0.3, 0, 1);
      // Front quad vertex 0 (x -0.5, z 0.5) moves right of its yaw-0 place.
      final turned = renderer.screen[0];
      renderer.update(size, size, 0, 0, 1);
      expect(turned, greaterThan(renderer.screen[0]));
    });

    test('keeps a deep model whole at maximum zoom', () {
      final controller = ModelViewerController();
      final renderer = MeshRenderer(_cube())
        ..update(size, size, 0.6, 0.5, controller.maxZoom);
      // Three faces turn to the camera; none is lost to the camera
      // entering the model.
      expect(renderer.drawIndexCount, 3 * 2 * 3);
      expect(renderer.screen.every((v) => v.isFinite), isTrue);
      controller.dispose();
    });

    test('culls back faces', () {
      final renderer = MeshRenderer(layered)..update(size, size, 0, 0, 1);
      expect(renderer.drawIndexCount, 12);
      renderer.update(size, size, math.pi, 0, 1);
      expect(renderer.drawIndexCount, 0);
    });
  });

  group('depth order', () {
    test('draws far triangles first', () {
      final renderer = MeshRenderer(layered)..update(size, size, 0, 0, 1);
      final parts = [
        for (var i = 0; i < renderer.drawIndexCount; i++)
          layered.vertexParts[renderer.drawIndices[i]],
      ];
      // Parts: 0 front, 1 back.
      expect(parts, [1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0]);
    });

    test('follows the view when the far side turns to the camera', () {
      final model = parseGlb(
        quadsGlb({
          // Two quads facing +z, staggered in depth and in x.
          'near': quad(-1, -1, 0, 1, 0.4),
          'far': quad(0, -1, 1, 1, -0.4),
        }),
      );
      final renderer = MeshRenderer(model)..update(size, size, 0, 0, 1);
      expect(model.vertexParts[renderer.drawIndices[0]], 1);
      // Yawed so the "far" quad (right side) swings toward the camera.
      renderer.update(size, size, -1.2, 0, 1);
      expect(model.vertexParts[renderer.drawIndices[0]], 0);
    });
  });

  group('picking', () {
    late MeshRenderer renderer;
    setUp(() => renderer = MeshRenderer(layered)..update(size, size, 0, 0, 1));

    test('returns the front-most part', () {
      expect(renderer.pick(center, center, _all), 'front');
    });

    test('returns a part seen around the occluder', () {
      expect(renderer.pick(center, 50, _all), 'back');
    });

    test('unselectable parts occlude but are not returned', () {
      expect(renderer.pick(center, center, (p) => p != 'front'), isNull);
      expect(renderer.pick(center, 50, (p) => p != 'front'), 'back');
    });

    test('a miss returns null', () {
      expect(renderer.pick(2, 2, _all), isNull);
    });
  });

  test('shade lights a camera-facing part in its colour', () {
    final renderer = MeshRenderer(layered)..update(size, size, 0, 0, 1);
    renderer.partColors
      ..[0] = 0xFFFF0000
      ..[1] = 0xFF0000FF;
    renderer.shade();
    final front = renderer.colors[0];
    expect((front >> 16) & 0xFF, greaterThan(200));
    expect(front & 0xFFFF, 0);
    expect(renderer.colors[4] & 0xFF, greaterThan(200));
  });
}
