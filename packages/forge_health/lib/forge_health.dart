/// Daily step counts and workouts from Apple Health (iOS) and Health
/// Connect (Android), read only, or a deterministic fake.
///
/// Register `HealthModule()` for the platform store or
/// `HealthModule.fake(FakeHealthSteps(...))` for tests and simulators.
///
/// ## Flow
///
/// 1. `GetHealthAvailability`: on [HealthAvailability.notInstalled] offer
///    `OpenHealthSettings`, which opens the Health Connect store page; on
///    [HealthAvailability.unsupported] hide the feature.
/// 2. `RequestHealthPermission` when steps are first needed: one sheet for
///    steps, workouts and heart rate (iOS shows no second sheet right after
///    the first), answering for steps. Android answers
///    [HealthPermission.granted] or [HealthPermission.denied]; after two
///    refusals Health Connect shows no dialog, so offer `OpenHealthSettings`.
///    iOS always answers [HealthPermission.undetermined]: HealthKit hides
///    read access, and a refusal reads as zero steps, so say where to allow
///    access next to a zero count.
/// 3. `GetStepsOn` and `GetDailySteps` by local calendar day, at most
///    `maxStepDays` per call. Android without access fails with
///    `PermissionFailure`. Re-read on app resume: the user can change access
///    in settings at any time.
///
/// 4. Workouts have their own access, asked for in step 2:
///    `GetWorkoutsPermission`, then `GetHealthWorkouts` by local calendar
///    day. The same answers as for steps apply; on iOS a refusal reads as
///    no workouts. Heart rate is optional: without it a workout has no
///    average.
///
/// Health Connect reads only 30 days before the permission was first
/// granted, and only while the app is in the foreground. It names a
/// workout's source by package name only, and has no stationary bike kind
/// the plugin maps (it reads as [HealthWorkoutType.other]).
///
/// ## App setup (health 14.0)
///
/// iOS (15+): the HealthKit capability on the Runner target (Signing &
/// Capabilities; it adds the `com.apple.developer.healthkit` entitlement and
/// must be enabled on the App ID), and in `ios/Runner/Info.plist` the app's
/// own reason for reading steps:
/// ```xml
/// <key>NSHealthShareUsageDescription</key>
/// <string>...</string>
/// ```
/// Reading only needs no `NSHealthUpdateUsageDescription`. Workouts add no
/// iOS setup; the same reason covers them.
///
/// Android: `minSdk = 26` (Health Connect itself needs Android 9+; older
/// devices report [HealthAvailability.unsupported]), `compileSdk = 37` with
/// AGP 9.1+ and Gradle 9.3.1+ (the plugin's Health Connect client needs
/// them), and `MainActivity`
/// extending `FlutterFragmentActivity`, which the permission dialog needs:
/// ```kotlin
/// class MainActivity : FlutterFragmentActivity()
/// ```
/// `android/app/src/main/AndroidManifest.xml`:
/// ```xml
/// <manifest>
///   <uses-permission android:name="android.permission.health.READ_STEPS"/>
///   <!-- Asked for with steps, for workouts: -->
///   <uses-permission android:name="android.permission.health.READ_EXERCISE"/>
///   <uses-permission android:name="android.permission.health.READ_DISTANCE"/>
///   <uses-permission android:name="android.permission.health.READ_TOTAL_CALORIES_BURNED"/>
///   <uses-permission android:name="android.permission.health.READ_HEART_RATE"/>
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
/// Console before release, listing every type read (steps, and for
/// workouts exercise, distance, total calories and heart rate). The one
/// request asks for all of them, so declare each even when the app reads
/// only steps.
library;

export 'src/data/fake_health_steps.dart';
export 'src/domain/health_models.dart';
export 'src/domain/health_steps.dart';
export 'src/domain/health_usecases.dart';
export 'src/health_module.dart';
