# Build

## Scaffold (once per app)

1. `tools/new_app.sh <name> <org> --github` — confirm the repo name with the
   user first; it creates a private GitHub repo.
2. `tools/firebase_setup.sh <name> <project-id-base>` — creates `<base>-dev`
   and `<base>-prod`. Confirm the id base first; project ids are permanent.
3. Enable what the spec needs in both projects:
   - Firestore: `gcloud services enable firestore.googleapis.com --project <id>
     --account <firebase login account>`, then `firebase firestore:databases:create
     "(default)" --location <region> --project <id>` (ask for the region once;
     retry if the API is still propagating).
   - Auth and rules: add `"firestore": {"rules": "firestore.rules"}` and
     `"auth": {"providers": {...}}` to `firebase.json`, then
     `firebase deploy --only auth,firestore:rules --project <id>`. Do not use
     the Identity Platform REST API; it requires billing.
4. If the spec has no accounts, remove `forge_auth` from `pubspec.yaml`,
   `bootstrap.dart` and `router.dart`.
5. `flutter run` on the iOS simulator; confirm sign-up
   works end to end. Commit, push, tick nothing yet.

## Feature loop

Take the first unticked feature in `SPEC.md`, plus up to two more unticked
ones that are independent of it and of each other, and run this loop for each
in parallel. Merge each as soon as its review and CI pass; the user approves
at feature-group demos, not per PR. For each feature:

1. **Architect** — write a short brief: entities, repository interface, use
   cases, cubit states, screens, Firestore paths and rules. Ask the user only
   if the brief needs a decision the spec does not cover.
2. **Implementer** — on branch `feat/<feature>`: domain → data → presentation
   → module → route → security rules → tests. Run format, analyze, test.
3. **Reviewer** — review the diff: layer boundaries, failure handling, rules
   that match the data model, tests that would catch a real regression, no
   dead or speculative code. Implementer fixes; repeat until clean.
4. Run the app on the simulator and exercise the feature, including the
   failure and empty states.
5. Open a PR, wait for CI, squash-merge, tick the feature in `SPEC.md`.

After each feature group, show the user a short demo and get approval before
the next group. Record scope changes in `SPEC.md` first, then build them.

A bug that survives two fix attempts goes back to the Architect.
