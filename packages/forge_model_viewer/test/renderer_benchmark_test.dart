// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:forge_model_viewer/src/gltf/glb_parser.dart';
import 'package:forge_model_viewer/src/render/mesh_renderer.dart';

// CPU cost of one frame for a real model. Run with
// `flutter test test/renderer_benchmark_test.dart --dart-define=glb=<file>`.
const _glb = String.fromEnvironment('glb');

void main() {
  test('frame cost', () {
    final watch = Stopwatch()..start();
    final model = parseGlb(File(_glb).readAsBytesSync());
    print(
      'parse ${watch.elapsedMilliseconds} ms, '
      '${model.vertexCount} vertices, ${model.triangleCount} triangles',
    );
    final renderer = MeshRenderer(model);
    renderer.partColors.fillRange(0, renderer.partColors.length, 0xFF808080);
    const frames = 300;
    for (var warmup = 0; warmup < 50; warmup++) {
      renderer
        ..update(400, 800, warmup * 0.02, 0.1, 1)
        ..shade();
    }
    final update = Stopwatch(), shade = Stopwatch(), pick = Stopwatch();
    for (var f = 0; f < frames; f++) {
      update.start();
      renderer.update(400, 800, f * 0.02, 0.1, 1);
      update.stop();
      shade.start();
      renderer.shade();
      shade.stop();
      pick.start();
      renderer.pick(200, 400, (_) => true);
      pick.stop();
    }
    String perFrame(Stopwatch s) =>
        '${(s.elapsedMicroseconds / frames / 1000).toStringAsFixed(2)} ms';
    print(
      'update ${perFrame(update)}, shade ${perFrame(shade)}, '
      'pick ${perFrame(pick)} per frame',
    );
  }, skip: _glb.isEmpty ? 'needs --dart-define=glb=<model.glb>' : false);
}
