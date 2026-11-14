import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_camera/forge_camera.dart';
import 'package:forge_ui/forge_ui.dart';

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
  late List<String> captured;

  Widget camera({String? ghostFile}) => MaterialApp(
    theme: ForgeTheme.light(),
    home: Scaffold(
      body: GhostCamera(
        ghostFile: ghostFile,
        captureLabel: 'capture',
        switchLabel: 'switch',
        startingTitle: 'starting',
        startingDetail: 'starting detail',
        unavailableTitle: 'unavailable',
        unavailableDetail: 'unavailable detail',
        onCaptured: captured.add,
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
    captured = [];
  });

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
    await tester.pumpWidget(camera());
    await tester.pumpAndSettle();

    expect(platform.opened, [_back]);
    expect(platform.locked, [DeviceOrientation.portraitUp]);
    expect(find.byTooltip('capture'), findsOneWidget);
    expect(find.byTooltip('switch'), findsOneWidget);
    expect(find.text('unavailable'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    expect(orientations, [
      ['DeviceOrientation.portraitUp'],
      <String>[],
    ]);
  });

  testWidgets('capture hands the picture to the callback', (tester) async {
    await tester.pumpWidget(camera());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('capture'));
    await tester.pumpAndSettle();

    expect(captured, ['/tmp/0.jpg']);
  });

  testWidgets('switching closes the camera and opens the other lens', (
    tester,
  ) async {
    await tester.pumpWidget(camera());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('switch'));
    await tester.pumpAndSettle();

    expect(platform.opened, [_back, _front]);
    expect(platform.disposed, [0]);
    expect(find.byTooltip('capture'), findsOneWidget);
  });

  testWidgets('one camera shows no switch', (tester) async {
    platform = _FakeCameraPlatform([_back]);
    CameraPlatform.instance = platform;
    await tester.pumpWidget(camera());
    await tester.pumpAndSettle();

    expect(find.byTooltip('switch'), findsNothing);
  });

  testWidgets('no camera shows the unavailable text', (tester) async {
    platform = _FakeCameraPlatform([]);
    CameraPlatform.instance = platform;
    await tester.pumpWidget(camera());
    await tester.pumpAndSettle();

    expect(find.text('unavailable'), findsOneWidget);
    expect(find.byTooltip('capture'), findsNothing);
  });

  testWidgets('refused access shows the unavailable text', (tester) async {
    platform.initError = CameraException('CameraAccessDenied', 'denied');
    await tester.pumpWidget(camera());
    await tester.pumpAndSettle();

    expect(find.text('unavailable'), findsOneWidget);
    expect(platform.disposed, [0]);
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

    await tester.tap(find.byTooltip('switch'));
    await tester.pumpAndSettle();
    expect(ghostMirrored(tester), isTrue);
  });
}
