# Build

## Scaffold (once per app)

1. `tools/new_app.sh <name> <org> --github` — confirm the repo name with the
   user first; it creates a private GitHub repo.
2. `tools/firebase_setup.sh <name> <project-id-base>` — creates `<base>-dev`
   and `<base>-prod`. Confirm the id base first; project ids are permanent.
3. Enable what the spec needs in both projects through the Firebase CLI or
   REST APIs: Firestore database (ask for the region once), the chosen Auth
   providers. Deploy `firestore.rules`.
4. If the spec has no accounts, remove `forge_auth` from `pubspec.yaml`,
   `bootstrap.dart` and `router.dart`.
5. `flutter run -t lib/main_dev.dart` on the iOS simulator; confirm sign-up
   works end to end. Commit, push, tick nothing yet.

## Feature loop

For the first unticked feature in `SPEC.md`:

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
