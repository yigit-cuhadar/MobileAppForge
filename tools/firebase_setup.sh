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
  firebase projects:list 2>/dev/null | grep -q " $project " ||
    firebase projects:create "$project" --display-name "$name $env"
  flutterfire configure --yes --project "$project" --platforms ios,android \
    --ios-bundle-id "$bundle" --android-package-name "$bundle" \
    --out "lib/firebase_options_$env.dart"
done
echo "Firebase ready: $base-dev, $base-prod"
