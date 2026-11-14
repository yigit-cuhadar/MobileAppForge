import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_camera/forge_camera.dart';

const _back = CameraDescription(
  name: 'back',
  lensDirection: CameraLensDirection.back,
  sensorOrientation: 90,
);
const _front = CameraDescription(
  name: 'front',
  lensDirection: CameraLensDirection.front,
  sensorOrientation: 270,
);

/// Camera ids are the index into [opened].
class _FakeCameraPlatform extends CameraPlatform {
  _FakeCameraPlatform(this.cameras);

  final List<CameraDescription> cameras;
  final opened = <CameraDescription>[];
  final disposed = <int>[];
  final locked = <DeviceOrientation>[];
  CameraException? initError;
  Completer<void>? initGate;

  @override
  Future<List<CameraDescription>> availableCameras() async => cameras;

  @override
  Future<int> createCameraWithSettings(
    CameraDescription cameraDescription,
    MediaSettings? mediaSettings,
  ) async {
    opened.add(cameraDescription);
    return opened.length - 1;
  }

  @override
  Future<void> initializeCamera(
    int cameraId, {
    ImageFormatGroup imageFormatGroup = ImageFormatGroup.unknown,
  }) async {
    if (initError case final error?) throw error;
    await initGate?.future;
  }

  @override
  Stream<CameraInitializedEvent> onCameraInitialized(int cameraId) =>
      Stream.value(
        CameraInitializedEvent(
          cameraId,
          1080,
          1920,
          ExposureMode.auto,
          true,
          FocusMode.auto,
          true,
        ),
      );

  @override
  Stream<CameraErrorEvent> onCameraError(int cameraId) =>
      StreamController<CameraErrorEvent>().stream;

  @override
  Stream<DeviceOrientationChangedEvent> onDeviceOrientationChanged() =>
      StreamController<DeviceOrientationChangedEvent>().stream;

  @override
  Future<void> lockCaptureOrientation(
    int cameraId,
    DeviceOrientation orientation,
  ) async => locked.add(orientation);

  @override
  Future<XFile> takePicture(int cameraId) async => XFile('/tmp/$cameraId.jpg');

  @override
  Widget buildPreview(int cameraId) => const SizedBox.expand();

  @override
  Future<void> dispose(int cameraId) async => disposed.add(cameraId);
}

void main() {
  late _FakeCameraPlatform platform;
  late GhostCameraController controller;
  late List<GhostCameraStatus> statuses;

  Widget camera({String? ghostFile, Widget? overlay}) => MaterialApp(
    home: Scaffold(
      body: GhostCamera(
        controller: controller,
        ghostFile: ghostFile,
        overlay: overlay,
      ),
    ),
  );

  /// Whether the ghost is drawn flipped horizontally.
  bool ghostMirrored(WidgetTester tester) {
    final flip = tester.widget<Transform>(
      find
          .ancestor(of: find.byType(Image), matching: find.byType(Transform))
          .first,
    );
    return flip.transform.storage[0] < 0;
  }

  setUp(() {
    platform = _FakeCameraPlatform([_front, _back]);
    CameraPlatform.instance = platform;
    statuses = [];
    controller = GhostCameraController()
      ..addListener(() => statuses.add(controller.status));
  });

  tearDown(() => controller.dispose());

  testWidgets('shows the back camera, held and captured in portrait', (
    tester,
  ) async {
    final orientations = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemChrome.setPreferredOrientations') {
          orientations.add(call.arguments);
        }
        return null;
      },
    );
    final gate = platform.initGate = Completer<void>();
    await tester.pumpWidget(camera(overlay: const Text('overlay')));
    await tester.pump();
    expect(controller.status, GhostCameraStatus.starting);
    expect(find.text('overlay'), findsNothing);
    gate.complete();
    await tester.pumpAndSettle();

    expect(platform.opened, [_back]);
    expect(platform.locked, [DeviceOrientation.portraitUp]);
    expect(controller.status, GhostCameraStatus.ready);
    expect(controller.canSwitch, isTrue);
    expect(find.text('overlay'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    expect(orientations, [
      ['DeviceOrientation.portraitUp'],
      <String>[],
    ]);
  });

  testWidgets('capture returns the picture', (tester) async {
    await tester.pumpWidget(camera());
    await tester.pumpAndSettle();

    final picture = await controller.capture();

    expect(picture, '/tmp/0.jpg');
  });

  testWidgets('capture before the camera is ready returns null', (
    tester,
  ) async {
    platform.initGate = Completer<void>();
    await tester.pumpWidget(camera());
    await tester.pump();

    expect(await controller.capture(), isNull);
    platform.initGate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('switching closes the camera and opens the other lens', (
    tester,
  ) async {
    await tester.pumpWidget(camera());
    await tester.pumpAndSettle();
    statuses.clear();

    await controller.switchCamera();
    await tester.pumpAndSettle();

    expect(platform.opened, [_back, _front]);
    expect(platform.disposed, [0]);
    expect(statuses, [GhostCameraStatus.starting, GhostCameraStatus.ready]);
  });

  testWidgets('one camera cannot switch', (tester) async {
    platform = _FakeCameraPlatform([_back]);
    CameraPlatform.instance = platform;
    await tester.pumpWidget(camera());
    await tester.pumpAndSettle();

    expect(controller.status, GhostCameraStatus.ready);
    expect(controller.canSwitch, isFalse);
  });

  testWidgets('no camera reports noCamera and draws nothing', (tester) async {
    platform = _FakeCameraPlatform([]);
    CameraPlatform.instance = platform;
    await tester.pumpWidget(camera(overlay: const Text('overlay')));
    await tester.pumpAndSettle();

    expect(controller.status, GhostCameraStatus.noCamera);
    expect(find.text('overlay'), findsNothing);
    expect(await controller.capture(), isNull);
  });

  testWidgets('refused access reports accessDenied', (tester) async {
    platform.initError = CameraException('CameraAccessDenied', 'denied');
    await tester.pumpWidget(camera());
    await tester.pumpAndSettle();

    expect(controller.status, GhostCameraStatus.accessDenied);
    expect(platform.disposed, [0]);
  });

  testWidgets('a camera that fails to start reports noCamera', (tester) async {
    platform.initError = CameraException('setupFailed', 'broken');
    await tester.pumpWidget(camera());
    await tester.pumpAndSettle();

    expect(controller.status, GhostCameraStatus.noCamera);
  });

  testWidgets('disposed while starting, it closes the camera quietly', (
    tester,
  ) async {
    final gate = platform.initGate = Completer<void>();
    await tester.pumpWidget(camera());
    await tester.pump();
    expect(platform.opened, [_back]);

    await tester.pumpWidget(const SizedBox());
    gate.complete();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(platform.disposed, [0]);
    expect(await controller.capture(), isNull);
  });

  testWidgets('the ghost is mirrored on the front camera only', (tester) async {
    final dir = Directory.systemTemp.createTempSync('ghost');
    addTearDown(() => dir.deleteSync(recursive: true));
    final ghost = File('${dir.path}/ghost.png')
      ..writeAsBytesSync(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
        ),
      );
    await tester.pumpWidget(camera(ghostFile: ghost.path));
    await tester.pumpAndSettle();
    expect(ghostMirrored(tester), isFalse);

    await controller.switchCamera();
    await tester.pumpAndSettle();
    expect(ghostMirrored(tester), isTrue);
  });
}
