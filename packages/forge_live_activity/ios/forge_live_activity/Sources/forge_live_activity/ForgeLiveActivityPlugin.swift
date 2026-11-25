import ActivityKit
import Flutter
import UIKit

/// The app's one Live Activity, driven from Dart (`LiveActivity`).
///
/// The attributes type is shared with the app's widget extension by name:
/// the extension cannot link this plugin, so it declares the same type,
/// exactly as follows, and decodes `json` into the app's own content:
///
/// ```swift
/// struct ForgeLiveActivityAttributes: ActivityAttributes {
///   struct ContentState: Codable, Hashable {
///     var json: String
///   }
/// }
/// ```
///
/// `json` is the content Dart passed to `show`, JSON-encoded.
@available(iOS 16.1, *)
struct ForgeLiveActivityAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    var json: String
  }
}

/// Channels: `forge_live_activity` ("show", "end", "takeTap"; "tapped" to
/// Dart) and `forge_live_activity/presses` ("takePresses"; "press" to
/// Dart). Below iOS 16.2 nothing shows and "show" answers nil.
///
/// Set by the app in `application(_:didFinishLaunchingWithOptions:)`:
/// [tapURL], and, with buttons, [contentAfterPress]; the app's button
/// intents call [press].
public class ForgeLiveActivityPlugin: NSObject, FlutterPlugin, FlutterSceneLifeCycleDelegate {
  /// The extension's widgetURL. Taken here, not through Flutter's deep
  /// linking (`FlutterDeepLinkingEnabled` off), and kept until Dart takes
  /// it, so a tap that launched the app is not lost.
  public static var tapURL: URL?

  /// The content to show at once when a button is pressed, before Dart
  /// handles it: given the button's action and the shown content's JSON,
  /// the new JSON and its stale date; nil leaves it as it is.
  @MainActor public static var contentAfterPress:
    ((_ action: String, _ json: String) -> (json: String, staleDate: Date?)?)?

  /// The registrar keeps neither the scene delegate nor the channels.
  private static var instance: ForgeLiveActivityPlugin?
  @MainActor private static var presses: FlutterMethodChannel?

  private let channel: FlutterMethodChannel
  private var tapped = false

  private init(channel: FlutterMethodChannel) {
    self.channel = channel
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "forge_live_activity", binaryMessenger: registrar.messenger())
    let instance = ForgeLiveActivityPlugin(channel: channel)
    Self.instance = instance
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.addSceneDelegate(instance)
    let presses = FlutterMethodChannel(
      name: "forge_live_activity/presses", binaryMessenger: registrar.messenger())
    presses.setMethodCallHandler { call, result in
      guard call.method == "takePresses" else {
        result(FlutterMethodNotImplemented)
        return
      }
      result(KeptPresses.take())
    }
    MainActor.assumeIsolated { Self.presses = presses }
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "takeTap" {
      result(tapped)
      tapped = false
      return
    }
    guard #available(iOS 16.2, *) else {
      result(nil)
      return
    }
    switch call.method {
    case "show":
      guard let args = call.arguments as? [String: Any], let json = args["json"] as? String else {
        result(FlutterError(code: "bad-args", message: "show needs json", details: nil))
        return
      }
      let staleDate = (args["staleAt"] as? NSNumber).map {
        Date(timeIntervalSince1970: $0.doubleValue / 1000)
      }
      Task { @MainActor in
        do {
          result(try await Activities.show(json: json, staleDate: staleDate))
        } catch {
          result(FlutterError(code: "show-failed", message: error.localizedDescription, details: nil))
        }
      }
    case "end":
      Task { @MainActor in
        await Activities.end()
        result(nil)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// A button on the activity pressed ([action] is the app's name for
  /// it), from the app's `LiveActivityIntent`, which runs in the app's
  /// process, also when it launched the app in the background without
  /// Flutter: the activity shows [contentAfterPress] at once, and Dart gets
  /// the press now when it listens, else once it does (kept until then,
  /// also across launches). Returns once Dart has handled it, so iOS keeps
  /// the app awake until then.
  @MainActor public static func press(_ action: String) async {
    if #available(iOS 16.2, *), let contentAfterPress {
      await Activities.update { contentAfterPress(action, $0) }
    }
    guard let presses else {
      KeptPresses.keep(action)
      return
    }
    let taken = await withCheckedContinuation { continuation in
      presses.invokeMethod("press", arguments: action) { result in
        continuation.resume(
          returning: !(result is FlutterError)
            && (result as AnyObject?) !== FlutterMethodNotImplemented
        )
      }
    }
    if !taken {
      KeptPresses.keep(action)
    }
  }

  // Selectors pinned, so a renamed Swift signature cannot silently stop
  // matching the optional protocol methods.
  @objc(scene:willConnectToSession:options:)
  public func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions?
  ) -> Bool {
    // Only noted: the launch is left to the others.
    _ = open(connectionOptions?.urlContexts ?? [])
    return false
  }

  @objc(scene:openURLContexts:)
  public func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
    open(URLContexts)
  }

  private func open(_ contexts: Set<UIOpenURLContext>) -> Bool {
    guard let url = Self.tapURL, contexts.contains(where: { $0.url == url }) else { return false }
    tapped = true
    channel.invokeMethod("tapped", arguments: nil)
    return true
  }
}

/// One activity at a time. Without push updates the app updates and ends
/// it only while it runs; its stale date lets the extension draw it
/// differently from then on by itself. iOS ends it after 8 hours; the next
/// show then starts a new one.
@available(iOS 16.2, *)
private enum Activities {
  typealias Attributes = ForgeLiveActivityAttributes

  /// Whether it shows; false with Live Activities turned off. Throws when
  /// the app may not start one (not in front).
  @MainActor static func show(json: String, staleDate: Date?) async throws -> Bool {
    let content = ActivityContent(state: Attributes.ContentState(json: json), staleDate: staleDate)
    let running = Activity<Attributes>.activities.filter {
      $0.activityState == .active || $0.activityState == .stale
    }
    if let current = running.first {
      await current.update(content)
      for extra in running.dropFirst() {
        await extra.end(nil, dismissalPolicy: .immediate)
      }
      return true
    }
    guard ActivityAuthorizationInfo().areActivitiesEnabled else { return false }
    // One iOS ended (8 hours) stays on the lock screen up to 4 hours more:
    // removed, so it is not shown next to the new one.
    for ended in Activity<Attributes>.activities where ended.activityState == .ended {
      await ended.end(nil, dismissalPolicy: .immediate)
    }
    _ = try Activity<Attributes>.request(
      attributes: Attributes(), content: content, pushType: nil)
    return true
  }

  /// Each active one shown as [change] makes its JSON, where it gives one.
  @MainActor static func update(_ change: (String) -> (json: String, staleDate: Date?)?) async {
    for activity in Activity<Attributes>.activities where activity.activityState == .active {
      guard let changed = change(activity.content.state.json) else { continue }
      await activity.update(
        ActivityContent(
          state: Attributes.ContentState(json: changed.json), staleDate: changed.staleDate))
    }
  }

  @MainActor static func end() async {
    for activity in Activity<Attributes>.activities {
      await activity.end(nil, dismissalPolicy: .immediate)
    }
  }
}

/// Presses Dart has not taken yet, kept across launches: one pressed while
/// the app did not run reaches Dart when it next listens.
private enum KeptPresses {
  private static let key = "forgeLiveActivityPresses"

  static func keep(_ action: String) {
    let kept = UserDefaults.standard.stringArray(forKey: key) ?? []
    UserDefaults.standard.set(kept + [action], forKey: key)
  }

  static func take() -> [String] {
    defer { UserDefaults.standard.removeObject(forKey: key) }
    return UserDefaults.standard.stringArray(forKey: key) ?? []
  }
}
