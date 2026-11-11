#!/usr/bin/env bash
# Creates apps/<name> from the template.
# Usage: tools/new_app.sh <name> <org> [--local] [--github]
#   <name>     snake_case app name, e.g. habit_tracker
#   <org>      reverse-domain prefix, e.g. com.yigitcuhadar
#   --local    depend on packages by path instead of the latest forge tag
#   --github   create the private repo yigit-cuhadar/<name> and push
set -euo pipefail
name="${1:?app name}"; org="${2:?org, e.g. com.example}"; shift 2
local=false; github=false
for arg in "$@"; do
  case "$arg" in
    --local) local=true ;;
    --github) github=true ;;
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
