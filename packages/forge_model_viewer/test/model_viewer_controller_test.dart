import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:forge_model_viewer/forge_model_viewer.dart';

void main() {
  test('clamps pitch and zoom, leaves yaw free', () {
    final controller = ModelViewerController(minZoom: 1, maxZoom: 3)
      ..yaw = 10
      ..pitch = 5
      ..zoom = 9;
    expect(controller.yaw, 10);
    expect(controller.pitch, controller.maxPitch);
    expect(controller.zoom, 3);
    controller
      ..pitch = -5
      ..zoom = 0.1;
    expect(controller.pitch, -controller.maxPitch);
    expect(controller.zoom, 1);
  });

  test('clamps the initial view and resets to it', () {
    final controller = ModelViewerController(yaw: 1, pitch: 9, zoom: 9);
    expect(controller.initialPitch, controller.maxPitch);
    expect(controller.initialZoom, controller.maxZoom);
    controller
      ..yaw = 3
      ..pitch = 0
      ..zoom = 1
      ..reset();
    expect(controller.yaw, 1);
    expect(controller.pitch, controller.maxPitch);
    expect(controller.zoom, controller.maxZoom);
  });

  test('notifies only on change', () {
    var notified = 0;
    final controller = ModelViewerController()
      ..addListener(() => notified++)
      ..yaw = 0
      ..zoom = 0.5;
    expect(notified, 0);
    controller.yaw = 1;
    expect(notified, 1);
  });

  testWidgets('animateTo takes the short way round and lands on target', (
    tester,
  ) async {
    final controller = ModelViewerController(yaw: 0.2);
    var done = false;
    unawaited(
      controller.animateTo(2 * math.pi - 0.2, 0.3, 2).then((_) => done = true),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 175));
    // Halfway between 0.2 and -0.2 (the short way), not near pi.
    expect(controller.yaw.abs(), lessThan(0.1));
    await tester.pump(const Duration(milliseconds: 200));
    expect(done, isTrue);
    expect(controller.yaw, 2 * math.pi - 0.2);
    expect(controller.pitch, 0.3);
    expect(controller.zoom, 2);
    controller.dispose();
  });

  testWidgets('a direct change interrupts an animation', (tester) async {
    final controller = ModelViewerController();
    var done = false;
    unawaited(controller.animateTo(1, 0, 1).then((_) => done = true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    controller.yaw = -1;
    await tester.pump(const Duration(milliseconds: 400));
    expect(done, isTrue);
    expect(controller.yaw, -1);
    controller.dispose();
  });
}
