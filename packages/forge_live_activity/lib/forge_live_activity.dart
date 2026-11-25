/// One iOS Live Activity, started, updated and ended from Dart, with its
/// taps and its buttons' presses. The app draws it in its own widget
/// extension; the package carries the app's content to it as JSON.
///
/// ## App setup (iOS, Swift Package Manager)
///
/// - `Info.plist`: `NSSupportsLiveActivities` true. Below a deployment
///   target of 16.1, `-weak_framework ActivityKit` in the Runner's
///   `OTHER_LDFLAGS` (and `AppIntents` with buttons).
/// - The widget extension (16.2+) declares `ForgeLiveActivityAttributes`
///   exactly as `ForgeLiveActivityPlugin.swift` documents it and decodes
///   its `json` into the app's content type (dates with
///   `.millisecondsSince1970`), drawing from its `isStale` past `staleAt`.
/// - Taps: the extension's `widgetURL` uses a scheme in
///   `CFBundleURLTypes`, `FlutterDeepLinkingEnabled` is false, and
///   `AppDelegate` sets `ForgeLiveActivityPlugin.tapURL` to that URL in
///   `application(_:didFinishLaunchingWithOptions:)`.
/// - Buttons (iOS 17+): `LiveActivityIntent`s compiled into both the
///   Runner and the extension; run in the app, they call
///   `await ForgeLiveActivityPlugin.press("<action>")` (through a handler
///   the Runner sets at launch, as the extension cannot link the plugin).
///   `ForgeLiveActivityPlugin.contentAfterPress`, set at launch too, shows
///   a press at once, also while Flutter does not run.
library;

export 'src/live_activity.dart';
