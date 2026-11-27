#!/usr/bin/env bash
# Prints a Google access token for the account the Firebase CLI is logged in
# as (`firebase login`), for scripts that read GOOGLE_ACCESS_TOKEN and for
# Google and Firebase REST APIs the CLI has no command for.
#
#   GOOGLE_ACCESS_TOKEN="$(tools/google_token.sh)" <command>
#
# Use it only inside a command, as above; never print the token. It reads
# the token the CLI keeps, after letting the CLI refresh it when it has
# expired, so it works where `gcloud` is logged into another account or not
# installed.
set -euo pipefail

store="$HOME/.config/configstore/firebase-tools.json"
token() {
  python3 - "$store" <<'PY'
import json, sys, time

try:
    with open(sys.argv[1]) as f:
        tokens = json.load(f)["tokens"]
except (OSError, KeyError):
    sys.exit(2)
if tokens.get("expires_at", 0) / 1000 < time.time() + 120:
    sys.exit(3)
print(tokens["access_token"], end="")
PY
}

token && exit 0
# Any authenticated command makes the CLI refresh and store its token.
firebase projects:list >/dev/null 2>&1 || {
  echo "The Firebase CLI is not logged in: run \`firebase login\`." >&2
  exit 1
}
token || { echo "The Firebase CLI did not store a fresh token." >&2; exit 1; }
