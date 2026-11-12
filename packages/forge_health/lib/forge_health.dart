/// Daily step counts from Apple Health (iOS) and Health Connect (Android),
/// read only, or a deterministic fake.
///
/// Register `HealthModule()` for the platform store or
/// `HealthModule.fake(FakeHealthSteps(...))` for tests and simulators.
///
/// ## Flow
///
/// 1. `GetHealthAvailability`: on [HealthAvailability.notInstalled] offer
///    `OpenHealthSettings`, which opens the Health Connect store page; on
///    [HealthAvailability.unsupported] hide the feature.
/// 2. `RequestStepsPermission` when steps are first needed. Android answers
///    [HealthPermission.granted] or [HealthPermission.denied]; after two
///    refusals Health Connect shows no dialog, so offer `OpenHealthSettings`.
///    iOS always answers [HealthPermission.undetermined]: HealthKit hides
///    read access, and a refusal reads as zero steps, so say where to allow
///    access next to a zero count.
/// 3. `GetStepsOn` and `GetDailySteps` by local calendar day. Re-read on
///    app resume: the user can change access in settings at any time.
///
/// Health Connect reads only 30 days before the permission was first
/// granted, and only while the app is in the foreground.
///
/// ## App setup (health 13.3)
///
/// iOS (15+): the HealthKit capability on the Runner target (Signing &
/// Capabilities; it adds the `com.apple.developer.healthkit` entitlement and
/// must be enabled on the App ID), and in `ios/Runner/Info.plist` the app's
/// own reason for reading steps:
/// ```xml
/// <key>NSHealthShareUsageDescription</key>
/// <string>...</string>
/// ```
/// Reading only needs no `NSHealthUpdateUsageDescription`.
///
/// Android: `minSdk = 26` (Health Connect itself needs Android 9+; older
/// devices report [HealthAvailability.unsupported]) and `MainActivity`
/// extending `FlutterFragmentActivity`, which the permission dialog needs:
/// ```kotlin
/// class MainActivity : FlutterFragmentActivity()
/// ```
/// `android/app/src/main/AndroidManifest.xml`:
/// ```xml
/// <manifest>
///   <uses-permission android:name="android.permission.health.READ_STEPS"/>
///   <queries>
///     <package android:name="com.google.android.apps.healthdata"/>
///     <intent>
///       <action android:name="androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE"/>
///     </intent>
///   </queries>
///   <application>
///     <activity android:name=".MainActivity" ...>
///       <!-- Android 13 and older: Health Connect's privacy policy link. -->
///       <intent-filter>
///         <action android:name="androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE"/>
///       </intent-filter>
///     </activity>
///     <!-- Android 14 and later: the same link. -->
///     <activity-alias
///       android:name="ViewPermissionUsageActivity"
///       android:exported="true"
///       android:targetActivity=".MainActivity"
///       android:permission="android.permission.START_VIEW_PERMISSION_USAGE">
///       <intent-filter>
///         <action android:name="android.intent.action.VIEW_PERMISSION_USAGE"/>
///         <category android:name="android.intent.category.HEALTH_PERMISSIONS"/>
///       </intent-filter>
///     </activity-alias>
///   </application>
/// </manifest>
/// ```
/// Both links open `MainActivity`, which should then show the app's privacy
/// policy. Google Play also requires the Health apps declaration in Play
/// Console before release.
library;

export 'src/data/fake_health_steps.dart';
export 'src/domain/health_models.dart';
export 'src/domain/health_steps.dart';
export 'src/domain/health_usecases.dart';
export 'src/health_module.dart';
