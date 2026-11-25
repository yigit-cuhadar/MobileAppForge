#!/usr/bin/env bash
# Archives an app for the App Store, sends its debug symbols to Crashlytics
# and uploads the build to App Store Connect (TestFlight).
#
#   tools/ios_upload.sh <app dir> <release GoogleService-Info.plist> [flutter build args...]
#   e.g. tools/ios_upload.sh apps/get_workout apps/get_workout/ios/Firebase/prod/GoogleService-Info.plist \
#          --dart-define=REVENUECAT_IOS_KEY="$(tools/secret.sh get REVENUECAT_IOS_KEY)"
#
# Bump the build number in pubspec.yaml first. Needs the keychain secrets
# ASC_API_KEY_P8 (base64 of the .p8), ASC_KEY_ID and ASC_ISSUER_ID.
set -euo pipefail

app="$(cd "${1:?app dir}" && pwd)"
gsp="$(cd "$(dirname "${2:?release GoogleService-Info.plist}")" && pwd)/$(basename "$2")"
shift 2
secret="$(cd "$(dirname "$0")" && pwd)/secret.sh"
cd "$app"

archive=build/ios/archive/Runner.xcarchive
rm -rf "$archive"
# Flutter's own export needs an Xcode account session; the archive is all
# that is used from it.
flutter build ipa --release --export-method app-store "$@" || [[ -d "$archive" ]]

# Symbols first: a crash report from this build is unreadable without them.
upload_symbols="$(find build/ios/SourcePackages ios/Pods -type f \
  -path '*Crashlytics/upload-symbols' -print -quit 2>/dev/null || true)"
[[ -x "$upload_symbols" ]] || { echo "Crashlytics upload-symbols not found" >&2; exit 1; }
"$upload_symbols" -gsp "$gsp" -p ios "$archive/dSYMs"

umask 077
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
key_id="$("$secret" get ASC_KEY_ID)"
"$secret" get ASC_API_KEY_P8 | base64 -d > "$work/AuthKey_$key_id.p8"
team="$(grep -m1 -o 'DEVELOPMENT_TEAM = [A-Z0-9]*' ios/Runner.xcodeproj/project.pbxproj | cut -d' ' -f3)"
# uploadSymbols stays off: the Firebase frameworks ship without dSYMs, which
# fails the export; Crashlytics has the app's symbols from above.
cat > "$work/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>upload</string>
  <key>signingStyle</key><string>automatic</string>
  <key>teamID</key><string>$team</string>
  <key>uploadSymbols</key><false/>
</dict></plist>
PLIST
xcodebuild -exportArchive -archivePath "$archive" \
  -exportOptionsPlist "$work/ExportOptions.plist" -exportPath "$work/export" \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$work/AuthKey_$key_id.p8" \
  -authenticationKeyID "$key_id" \
  -authenticationKeyIssuerID "$("$secret" get ASC_ISSUER_ID)"
echo "Uploaded. App Store Connect processes the build in about 15 minutes."
