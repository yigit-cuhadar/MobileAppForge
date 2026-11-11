#!/usr/bin/env bash
# Creates the dev and prod Firebase projects of an app and generates
# lib/firebase_options_{dev,prod}.dart. Needs `firebase login` once.
# Usage: tools/firebase_setup.sh <name> <project-id-base>
#   Projects become <base>-dev and <base>-prod (ids are global: 6-30 chars,
#   lowercase letters, digits, hyphens).
set -euo pipefail
name="${1:?app name}"; base="${2:?project id base}"
app="$(cd "$(dirname "$0")/.." && pwd)/apps/$name"
cd "$app"

bundle="$(sed -n 's/.*applicationId = "\(.*\)".*/\1/p' android/app/build.gradle.kts)"
[ -n "$bundle" ] || { echo "could not read applicationId" >&2; exit 1; }

# prod runs last on purpose: the native config files it leaves behind
# (google-services.json, GoogleService-Info.plist) must point at prod.
for env in dev prod; do
  project="$base-$env"
  # Ask for the project directly: a new one takes minutes to show in the list.
  firebase apps:list --project "$project" >/dev/null 2>&1 ||
    firebase projects:create "$project" --display-name "${name//_/-} $env"
  # flutterfire looks the project up in the list, which lags; retry.
  for attempt in 1 2 3 4 5 6 7 8 9 10; do
    flutterfire configure --yes --project "$project" --platforms ios,android \
      --ios-bundle-id "$bundle" --android-package-name "$bundle" \
      --out "lib/firebase_options_$env.dart" && break
    [ "$attempt" = 10 ] && { echo "flutterfire configure failed for $project" >&2; exit 1; }
    sleep 20
  done
done
echo "Firebase ready: $base-dev, $base-prod"
