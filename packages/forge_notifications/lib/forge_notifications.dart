/// Local notifications scheduled on the device: now, once, weekly and every
/// few weeks, with tap payloads for navigation.
///
/// ## App setup (flutter_local_notifications 23)
///
/// Android, `android/app/build.gradle.kts`:
/// ```kotlin
/// android {
///     compileSdk = 37 // at least
///     compileOptions { isCoreLibraryDesugaringEnabled = true }
/// }
/// dependencies { coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") }
/// ```
/// Android Gradle Plugin 9.1.1 or later (`android/settings.gradle.kts`).
///
/// Android, `android/app/src/main/AndroidManifest.xml` (the plugin itself
/// declares `POST_NOTIFICATIONS` and `VIBRATE`):
/// ```xml
/// <manifest>
///   <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
///   <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
///   <application>
///     <receiver android:exported="false"
///       android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>
///     <receiver android:exported="false"
///       android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
///       <intent-filter>
///         <action android:name="android.intent.action.BOOT_COMPLETED"/>
///         <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
///         <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
///         <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
///       </intent-filter>
///     </receiver>
///   </application>
/// </manifest>
/// ```
/// With `showCountdown`, also
/// `<uses-permission android:name="android.permission.POST_PROMOTED_NOTIFICATIONS"/>`
/// (Android 16 Live Updates; not a runtime permission).
///
/// Android, the small icon: a white-on-transparent drawable at
/// `res/drawable/<androidIcon>.png`, kept from resource shrinking by
/// `res/raw/keep.xml`:
/// `<resources xmlns:tools="http://schemas.android.com/tools" tools:keep="@drawable/<androidIcon>"/>`.
///
/// iOS (13+), `ios/Runner/AppDelegate.swift`, in
/// `application(_:didFinishLaunchingWithOptions:)` before `return super...`:
/// ```swift
/// UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
/// ```
/// No `Info.plist` keys or capabilities are needed.
///
/// ## App lifecycle
///
/// At start: `init`, then re-apply every repeating schedule. On resume:
/// `refreshTimeZone`, and re-apply repeating schedules if it changed.
library;

export 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show Importance;

export 'src/local_notifications.dart';
export 'src/notification_taps.dart';
export 'src/notifications.dart';
export 'src/schedule.dart' show ClockTime, iosPendingLimit, seriesLength;
