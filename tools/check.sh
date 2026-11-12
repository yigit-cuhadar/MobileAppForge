#!/usr/bin/env bash
# Format check, analyze and test the shared packages.
# Usage: tools/check.sh [package ...]   (default: all)
set -euo pipefail
cd "$(dirname "$0")/../packages"

for pkg in "${@:-forge_core forge_ui forge_firebase forge_auth forge_model_viewer forge_notifications forge_purchases forge_health}"; do
  for p in $pkg; do
    echo "== $p"
    (
      cd "$p"
      if grep -q 'sdk: flutter' pubspec.yaml; then tool=flutter; else tool=dart; fi
      $tool pub get >/dev/null
      dart format --output=none --set-exit-if-changed lib $([ -d test ] && echo test)
      $tool analyze
      if [ -d test ] && [ -n "$(ls test)" ]; then $tool test; fi
      # Local-day logic: run again in a zone with daylight saving time, as
      # CI runs in UTC.
      if [ "$p" = forge_health ]; then TZ=Europe/Berlin $tool test; fi
    )
  done
done
