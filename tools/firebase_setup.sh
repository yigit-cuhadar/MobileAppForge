#!/usr/bin/env bash
# Creates the dev and prod Firebase projects of an app and generates
# lib/firebase_options_{dev,prod}.dart and the native config files. Needs `firebase login` once.
# Usage: tools/firebase_setup.sh <name> <project-id-base>
#   Projects become <base>-dev and <base>-prod (ids are global: 6-30 chars,
#   lowercase letters, digits, hyphens).
set -euo pipefail
name="${1:?app name}"; base="${2:?project id base}"
app="$(cd "$(dirname "$0")/.." && pwd)/apps/$name"
cd "$app"

bundle="$(sed -n 's/.*applicationId = "\(.*\)".*/\1/p' android/app/build.gradle.kts)"
[ -n "$bundle" ] || { echo "could not read applicationId" >&2; exit 1; }

# The environment follows the build mode: debug and profile builds use the dev
# project, release builds use prod. Each native build configuration gets its
# own config file, so the natively initialized app always matches the Dart
# options (a mismatch fails at startup with core/duplicate-app).
configure() { # <env> <ios build config> <android build type>
  local project="$base-$1" attempt
  # flutterfire looks the project up in the list, which lags for new projects.
  for attempt in 1 2 3 4 5 6 7 8 9 10; do
    flutterfire configure --yes --project "$project" --platforms ios,android \
      --ios-bundle-id "$bundle" --android-package-name "$bundle" \
      --ios-build-config "$2" --ios-out "ios/Firebase/$1/GoogleService-Info.plist" \
      --android-out "android/app/src/$3/google-services.json" \
      --out "lib/firebase_options_$1.dart" && return
    sleep 20
  done
  echo "flutterfire configure failed for $project ($2)" >&2; exit 1
}

for env in dev prod; do
  project="$base-$env"
  # Ask for the project directly: a new one takes minutes to show in the list.
  firebase apps:list --project "$project" >/dev/null 2>&1 ||
    firebase projects:create "$project" --display-name "${name//_/-} $env"
done
configure dev Debug debug
configure dev Profile profile
configure prod Release release
echo "Firebase ready: $base-dev, $base-prod"
