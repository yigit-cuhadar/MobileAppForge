#!/usr/bin/env bash
# API keys live in the macOS Keychain, never in files or chat.
#   tools/secret.sh set NAME    prompts for the value (the user runs this)
#   tools/secret.sh get NAME    prints it; use only inside $(...), never echo it
#   tools/secret.sh has NAME    exit 0 if stored
set -euo pipefail
cmd="${1:?set|get|has}"; name="${2:?secret name}"
service="mobileappforge.$name"

case "$cmd" in
  set) security add-generic-password -U -a "$USER" -s "$service" -w ;;
  get) security find-generic-password -a "$USER" -s "$service" -w ;;
  has) security find-generic-password -a "$USER" -s "$service" >/dev/null 2>&1 ;;
  *) echo "unknown command: $cmd" >&2; exit 2 ;;
esac
