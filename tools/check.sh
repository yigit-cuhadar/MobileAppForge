#!/usr/bin/env bash
# Format check, analyze and test the shared packages.
# Usage: tools/check.sh [package ...]   (default: all)
set -euo pipefail
cd "$(dirname "$0")/../packages"

[ $# -gt 0 ] || set -- */
for p in "$@"; do
  p="${p%/}"
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
