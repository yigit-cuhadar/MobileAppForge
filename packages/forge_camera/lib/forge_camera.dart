/// Taking pictures with the `camera` plugin: [GhostCamera], a portrait
/// preview with an earlier picture laid faintly over it, driven by the app
/// through a [GhostCameraController].
///
/// ## App setup (camera 0.12)
///
/// iOS, `ios/Runner/Info.plist`: `NSCameraUsageDescription` (no microphone
/// key: audio is never enabled).
///
/// Android, `android/app/src/main/AndroidManifest.xml`: the plugin declares
/// audio and storage permissions and a required camera that pictures do not
/// need; drop them unless the app needs them elsewhere:
/// ```xml
/// <uses-permission android:name="android.permission.CAMERA"/>
/// <uses-permission android:name="android.permission.RECORD_AUDIO" tools:node="remove"/>
/// <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" tools:node="remove"/>
/// <uses-feature android:name="android.hardware.camera.any" android:required="false"
///     tools:replace="android:required"/>
/// ```
///
/// Only `camera` is a dependency, so an app can patch a platform
/// implementation (such as `camera_avfoundation`) with `dependency_overrides`.
library;

export 'src/ghost_camera.dart'
    show GhostCamera, GhostCameraController, GhostCameraStatus;
