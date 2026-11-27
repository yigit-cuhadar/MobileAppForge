# Release

Credentials, device checks and getting a build to testers. Ids, device names
and account facts of this machine are in `LOCAL.md` at the forge root; the
app's own targets, secrets and prerequisites are under Operations in its
`SPEC.md`.

## Credentials

- Secrets live in the macOS Keychain behind `tools/secret.sh` (`set <NAME>`
  prompts the owner, `get <NAME>` is used only inside a command). Functions'
  secrets live in each Firebase project (`firebase functions:secrets:set`).
- A Google access token for the Firebase projects:
  `GOOGLE_ACCESS_TOKEN="$(tools/google_token.sh)" <command>`. It belongs to
  the account the Firebase CLI is logged in as; do not rely on `gcloud`,
  which may be another account. Scripts that reach a project read that
  variable; it also opens Google and Firebase REST APIs the CLI has no
  command for (Firestore, Identity Toolkit, FCM, service usage).
- Deploy to a `-prod` project only at the owner's word, unless the app's
  SPEC names a standing exception.

## On the simulator

One simulator, iOS, debug or profile against `-dev`. To see Analytics events
without DebugView: turn debug mode on once (`xcrun simctl spawn booted
defaults write <bundle id> /google/measurement/debug_mode -bool YES`, the
same for `/google/firebase/debug_mode`), then stream `xcrun simctl spawn
booted log stream --level debug --predicate 'eventMessage CONTAINS
"[FirebaseAnalytics]"'`; "Logging event" lines are the events. Reserved
event names (`notification_open`, `app_exception`, `error`, …) throw inside
firebase_analytics and never arrive. `xcrun simctl push` with
`"gcm.message_id"` in the payload reaches the push tap handler. HealthKit
permissions cannot be reset on the simulator.

## On the owner's phone

In a worktree, one build at a time:

1. `flutter build ios --profile` (dev project), or `--release` for prod with
   the app's `--dart-define`s. Signing needs Xcode's account session alive;
   when it has expired the owner signs in again under Xcode › Settings ›
   Accounts. A first build with a new capability runs `xcodebuild …
   -allowProvisioningUpdates` once from `ios/`.
2. `xcrun devicectl device install app --device <id from LOCAL.md>
   build/ios/iphoneos/Runner.app`; retry on tunnel errors, phone unlocked
   and near. The owner opens the app; remote launch is refused.
3. Delete `build/` and the worktree's `DerivedData/Runner-*` entry.

Never a debug build on the phone: it cannot reach the Dart VM and hangs on
the splash screen. Check an install with `devicectl device info apps
--json-output`. Native failures show only in the device log: the owner runs
`sudo log collect --device-udid <id> --last 10m --output <path>`, read with
`/usr/bin/log show <path>`.

## TestFlight

1. Bump the build number in the app's `pubspec.yaml` on `main` (through a PR).
2. From the forge root, in a checkout of that `main`:
   `tools/ios_upload.sh <app dir> <app dir>/ios/Firebase/prod/GoogleService-Info.plist <flutter build args>`.
   It archives, sends the dSYMs to Crashlytics and uploads with the App
   Store Connect API key from the Keychain (`ASC_API_KEY_P8`, `ASC_KEY_ID`,
   `ASC_ISSUER_ID`). Flutter's own export failing with "No Accounts" is
   expected; the script uses the archive.
3. Processing takes about 15 minutes. Then delete the build files as above.

Submitting a version for review: price, content rights, review notes and the
build can be set through the App Store Connect API, but the regulated
medical device declaration and attaching an app's first subscriptions to the
version exist only on the website; the owner does those and submits there.
