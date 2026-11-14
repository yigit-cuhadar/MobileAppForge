import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// What a [GhostCamera] can do right now.
enum GhostCameraStatus {
  /// The camera is opening, at first and again when the app comes back.
  starting,

  /// The preview shows and pictures can be taken.
  ready,

  /// Access to the camera was refused; only the system settings can turn
  /// it on again. The camera opens by itself when the app comes back with
  /// access.
  accessDenied,

  /// The device has no camera, or none would start.
  noCamera,
}

/// The app's handle on a [GhostCamera]: its [status], and taking pictures
/// and switching cameras from the app's own controls. Listeners hear every
/// change of [status] and [canSwitch]. Serves one [GhostCamera] at a time.
class GhostCameraController extends ChangeNotifier {
  _GhostCameraState? _camera;
  GhostCameraStatus _status = GhostCameraStatus.starting;
  bool _canSwitch = false;

  GhostCameraStatus get status => _status;

  /// Whether the device has another camera to switch to.
  bool get canSwitch => _canSwitch;

  /// Takes a picture and returns its path, a temporary file; nothing is
  /// written to the gallery. Null when the camera is not ready, a picture
  /// is already being taken, or taking it failed; the preview stays either
  /// way.
  Future<String?> capture() async => _camera?._capture();

  /// Closes the camera showing and opens the next one; [status] is
  /// [GhostCameraStatus.starting] meanwhile.
  Future<void> switchCamera() async => _camera?._switch();

  void _update(GhostCameraStatus status, bool canSwitch) {
    if (status == _status && canSwitch == _canSwitch) return;
    _status = status;
    _canSwitch = canSwitch;
    notifyListeners();
  }
}

/// A live camera preview with [ghostFile], an earlier picture, laid faintly
/// over it, so a new picture can be lined up with the old one; the app's
/// [overlay] lies over both. Draws nothing but the preview: the app reads
/// [controller] for the status, shows its own controls and its own texts
/// for every status but ready, and takes pictures through [controller].
///
/// Starts on the back camera. Always portrait: the screen is held upright
/// while it shows, and the capture is locked to portrait, so the preview,
/// the ghost and the picture agree however the phone is tilted. A retake
/// is the caller showing it again.
class GhostCamera extends StatefulWidget {
  const GhostCamera({
    super.key,
    required this.controller,
    this.ghostFile,
    this.overlay,
  });

  final GhostCameraController controller;

  /// Path of the picture shown over the preview, if any.
  final String? ghostFile;

  /// Laid over the preview and the ghost, sized to the preview.
  final Widget? overlay;

  @override
  State<GhostCamera> createState() => _GhostCameraState();
}

class _GhostCameraState extends State<GhostCamera> {
  static const _ghostOpacity = 0.35;

  /// The cameras showing: one replacing another (the next picture) starts
  /// before the old one is disposed, so the screen is freed only after
  /// the last.
  static var _shown = 0;

  late final AppLifecycleListener _lifecycle;
  List<CameraDescription> _cameras = const [];
  CameraDescription? _camera;
  CameraController? _controller;

  /// Why the camera cannot show, until it does.
  GhostCameraStatus? _failure;

  /// The cameras being closed; the next one opens after them.
  Future<void> _closing = Future.value();
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    widget.controller._camera = this;
    if (_shown++ == 0) {
      unawaited(
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
      );
    }
    // The camera is released while the app is away, as the platforms
    // require, and opened again on return.
    _lifecycle = AppLifecycleListener(
      onInactive: _release,
      onResume: () => unawaited(_open()),
    );
    unawaited(_start());
  }

  @override
  void didUpdateWidget(GhostCamera oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller._camera == this) {
        oldWidget.controller._camera = null;
      }
      widget.controller._camera = this;
      // Listeners may rebuild; not while this build runs.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _report();
      });
    }
  }

  /// Rebuilds and tells the controller.
  void _changed() {
    if (!mounted) return;
    setState(() {});
    _report();
  }

  void _report() {
    final controller = _controller;
    widget.controller._update(
      _failure ??
          (controller != null && controller.value.isInitialized
              ? GhostCameraStatus.ready
              : GhostCameraStatus.starting),
      _cameras.length > 1,
    );
  }

  Future<void> _start() async {
    try {
      _cameras = await availableCameras();
    } on CameraException {
      _cameras = const [];
    }
    if (!mounted) return;
    _camera = _cameras
        .where((camera) => camera.lensDirection == CameraLensDirection.back)
        .followedBy(_cameras)
        .firstOrNull;
    await _open();
  }

  Future<void> _open() async {
    final camera = _camera;
    if (camera == null) {
      _failure = GhostCameraStatus.noCamera;
      _changed();
      return;
    }
    if (_controller != null) return;
    // A camera still closing would make this one fail to start (Android,
    // right after the permission prompt).
    await _closing;
    if (!mounted || _controller != null) return;
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _controller = controller;
    try {
      await controller.initialize();
      // Without the lock, the plugin turns the capture, and the preview
      // with it, with the phone, also while the screen stays portrait.
      await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      _failure = null;
      _changed();
    } on Object catch (error) {
      // Released again while starting: [_release] disposed it.
      if (_controller != controller) return;
      _controller = null;
      await _close(controller);
      _failure =
          error is CameraException && error.code.startsWith('CameraAccess')
          ? GhostCameraStatus.accessDenied
          : GhostCameraStatus.noCamera;
      _changed();
    }
  }

  /// Disposing one that never finished starting throws (the system's
  /// permission prompt makes the app inactive mid-start); nothing to undo.
  Future<void> _close(CameraController controller) async {
    try {
      await controller.dispose();
    } on Object {
      // Already gone.
    }
  }

  void _release() {
    final controller = _controller;
    _controller = null;
    if (controller != null) _closing = _closing.then((_) => _close(controller));
    _changed();
  }

  Future<void> _switch() async {
    final current = _camera;
    if (current == null || _cameras.length < 2 || _capturing) return;
    _camera = _cameras[(_cameras.indexOf(current) + 1) % _cameras.length];
    _release();
    await _open();
  }

  Future<String?> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _capturing) {
      return null;
    }
    _capturing = true;
    try {
      return (await controller.takePicture()).path;
    } on CameraException {
      return null;
    } finally {
      _capturing = false;
    }
  }

  @override
  void dispose() {
    if (--_shown == 0) {
      // Back to what the app declares.
      unawaited(SystemChrome.setPreferredOrientations(const []));
    }
    if (widget.controller._camera == this) widget.controller._camera = null;
    _lifecycle.dispose();
    final controller = _controller;
    if (controller != null) unawaited(_close(controller));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_failure != null ||
        controller == null ||
        !controller.value.isInitialized) {
      return const SizedBox.expand();
    }
    final ghost = widget.ghostFile;
    final overlay = widget.overlay;
    return Center(
      child: CameraPreview(
        controller,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (ghost != null)
              IgnorePointer(
                child: Opacity(
                  opacity: _ghostOpacity,
                  child: Transform.flip(
                    flipX: mirrorGhost(controller.description),
                    child: Image.file(File(ghost), fit: BoxFit.cover),
                  ),
                ),
              ),
            ?overlay,
          ],
        ),
      ),
    );
  }
}

/// Whether the ghost is flipped to match the preview of [camera]. Both
/// platforms show the front camera's preview mirrored, like a mirror, but
/// save its pictures unmirrored, as every ghost is; the back camera is
/// mirrored in neither. Verify on iOS and Android whenever the camera
/// plugin changes.
bool mirrorGhost(CameraDescription camera) =>
    camera.lensDirection == CameraLensDirection.front;
