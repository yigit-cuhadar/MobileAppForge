#!/usr/bin/env bash
# Creates apps/<name> from the template.
# Usage: tools/new_app.sh <name> <org> [--bundle-id=<id>] [--local] [--github]
#   <name>     snake_case app name, e.g. habit_tracker
#   <org>      reverse-domain prefix, e.g. com.yigitcuhadar
#   --bundle-id=<id>  exact iOS bundle id / Android applicationId, when it
#              should not be <org>.<name>. Permanent once published.
#   --local    depend on packages by path instead of the latest forge tag
#   --github   create the private repo yigit-cuhadar/<name> and push
set -euo pipefail
name="${1:?app name}"; org="${2:?org, e.g. com.example}"; shift 2
local=false; github=false; bundle=""
for arg in "$@"; do
  case "$arg" in
    --local) local=true ;;
    --github) github=true ;;
    --bundle-id=*) bundle="${arg#*=}" ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

forge="$(cd "$(dirname "$0")/.." && pwd)"
app="$forge/apps/$name"
[ -e "$app" ] && { echo "$app already exists" >&2; exit 1; }

flutter create --org "$org" --project-name "$name" --platforms ios,android "$app" >/dev/null
cd "$app"
rm -f lib/main.dart test/widget_test.dart README.md
cp -R "$forge/template/." .
sed -i.bak "s/{{APP_NAME}}/$name/g" SPEC.md AGENTS.md

# Firebase needs iOS 15+.
sed -i.bak 's/IPHONEOS_DEPLOYMENT_TARGET = [0-9.]*;/IPHONEOS_DEPLOYMENT_TARGET = 15.0;/' \
  ios/Runner.xcodeproj/project.pbxproj
rm -f SPEC.md.bak AGENTS.md.bak ios/Runner.xcodeproj/project.pbxproj.bak

if [ -n "$bundle" ]; then
  # The Android namespace (Kotlin package) keeps its generated value; only the
  # ids the stores see change.
  sed -i.bak "s/applicationId = \"[^\"]*\"/applicationId = \"$bundle\"/" \
    android/app/build.gradle.kts
  sed -i.bak -E "/RunnerTests;/!s/PRODUCT_BUNDLE_IDENTIFIER = [A-Za-z0-9._-]+;/PRODUCT_BUNDLE_IDENTIFIER = $bundle;/; \
    s/PRODUCT_BUNDLE_IDENTIFIER = [A-Za-z0-9._-]+\.RunnerTests;/PRODUCT_BUNDLE_IDENTIFIER = $bundle.RunnerTests;/" \
    ios/Runner.xcodeproj/project.pbxproj
  rm -f android/app/build.gradle.kts.bak ios/Runner.xcodeproj/project.pbxproj.bak
fi

packages=(forge_core forge_ui forge_firebase forge_auth)
deps=()
if $local; then
  for p in "${packages[@]}"; do deps+=("$p:{\"path\":\"../../packages/$p\"}"); done
else
  # Pin the commit of the latest tag, not the tag name: the packages depend on
  # each other by path, which pub resolves to this commit, and both must match.
  ref="$(git -C "$forge" rev-list -n1 "$(git -C "$forge" describe --tags --abbrev=0)")"
  url="https://github.com/yigit-cuhadar/MobileAppForge.git"
  for p in "${packages[@]}"; do
    deps+=("$p:{\"git\":{\"url\":\"$url\",\"ref\":\"$ref\",\"path\":\"packages/$p\"}}")
  done
fi
flutter pub add "${deps[@]}" firebase_core flutter_bloc get_it go_router \
  dev:bloc_test dev:mocktail >/dev/null

git init -q -b main
git add -A
git commit -q -m "Scaffold $name with MobileAppForge"
if $github; then
  gh repo create "yigit-cuhadar/$name" --private --source . --push
fi
echo "Created $app"
