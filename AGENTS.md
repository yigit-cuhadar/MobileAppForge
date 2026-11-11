# MobileAppForge

A system for building many Flutter + Firebase apps. This repo holds the
workflow, shared packages and app template. Each app is its own repo, cloned
into `apps/<name>` (gitignored here). Always work from this root.

Talk to the user in their language. Code, comments and commits are English.

## Layout

| Path | Purpose |
|---|---|
| `workflow/` | One file per phase. Read only the phase you are in. |
| `packages/` | `forge_core`, `forge_ui`, `forge_firebase`, `forge_auth` — used by every app. |
| `template/` | Overlay copied onto `flutter create` by `tools/new_app.sh`. |
| `tools/` | `new_app.sh`, `firebase_setup.sh`, `secret.sh`, `check.sh`. |
| `apps/<name>/SPEC.md` | The app's state. Resume any app from here. |

## Phases

1. **Discovery** — `workflow/discovery.md`. Ends with an approved `SPEC.md`.
2. **Build** — `workflow/build.md`. Scaffold, then one feature at a time.
3. **Design** — `workflow/design.md`. Only after every feature is ticked.
4. **Release** — not automated yet. Build it with the first app that reaches
   it (App Store Connect API + Play Developer API), then move it into `tools/`.

To resume: read `apps/<name>/SPEC.md`, find the first unticked feature or open
question, read that phase's workflow file, continue.

## Working with the user

- Ask before decisions that are costly or hard to reverse: product scope, data
  model, auth methods, paid services (Blaze plan, Cloud Functions), anything
  public or irreversible (creating repos/projects, publishing, deleting data).
  Offer 2-4 options with a recommendation first.
- Decide the rest yourself and note it in `SPEC.md` under Decisions.
- Never ask the user to do by hand what an API or CLI can do. If a credential
  is missing, ask them to run `tools/secret.sh set <NAME>` (it prompts; the
  value never enters the chat) and then do the work yourself. Read secrets
  only as `$(tools/secret.sh get <NAME>)` inside a command; never print them.
- Approval points: SPEC, data model, then a short demo after each feature group.

## Architecture

Clean Architecture, feature-first: `lib/features/<feature>/{domain,data,presentation}`.

- **domain** — entities, repository interfaces, use cases. Pure Dart; imports
  nothing from Flutter, Firebase or `data`.
- **data** — repository implementations and data sources. Data sources throw;
  repositories wrap every call in `guard(..., mapper: mapFirebaseError)` and
  return `Result<T>`. Use `FirestoreCollection<T>` for Firestore.
- **presentation** — Cubits and widgets. Cubits call use cases only, never
  repositories. Widgets hold no business logic.
- State: `flutter_bloc` Cubits with `Equatable` states. Use a full Bloc only
  when events need transforming (debounce, restartable).
- DI: `get_it` through `sl`. Each feature has one `FeatureModule`, registered
  in `lib/app/bootstrap.dart`. Only modules and pages creating cubits touch `sl`.
- Routing: `go_router`, every route in `lib/app/router.dart`.
- No code generation (`build_runner`, freezed, json_serializable): write
  `fromMap`/`toMap` by hand.
- UI before the design phase: `forge_ui` widgets, `Gap` spacing, theme colors
  only. No custom styling, no hard-coded colors or sizes.
- Small use cases of a feature share one `<feature>_usecases.dart`.
  `packages/forge_auth` is the reference implementation of all of the above.

Keep it lean: no abstractions without a second user, no speculative options,
no new `.md` files (state goes in `SPEC.md`, rules go here). Comment only what
the code cannot say.

## Shared packages

Code moves into `packages/` when a second app needs it, not before. Changing a
package: edit, `tools/check.sh <package>`, PR to this repo, then tag `vX.Y.Z`
on main. Apps pin a tag and upgrade deliberately by changing the `ref`.

## Tests

Unit-test use cases with logic, repositories and cubits (`mocktail`,
`bloc_test`, `fake_cloud_firestore`). No widget or integration tests before
the design phase; verify screens on the simulator instead.

## Git

- `gh` CLI for everything on GitHub. Forge: `yigit-cuhadar/MobileAppForge`
  (public). Apps: `yigit-cuhadar/<name>` (private).
- Never commit to `main`. One branch and PR per feature; squash-merge when CI
  is green. Commit messages: imperative, what and why.
- Before every commit: `dart format`, `flutter analyze`, `flutter test` in the
  package or app you touched. CI repeats this on every PR.

## Machine limits (M1, 16 GB)

- One simulator at a time; iOS for daily work, Android at feature-group demos.
- No Firebase Emulator. Develop against the app's `-dev` project.
- At most two parallel sub-agents. Never two Flutter builds at once.
- Analyze and test only what you changed; CI covers the rest.

## Roles

The workflow is written in roles so it runs in any tool. A tool without
sub-agents plays all roles itself, in order.

| Role | Does | Claude Code |
|---|---|---|
| Architect | Discovery, data model, feature breakdown, hard bugs, final call | main session, Fable |
| Implementer | One feature end to end, with tests | `implementer` agent, Opus |
| Reviewer | Reviews each feature diff against this file and the spec | `reviewer` agent, Opus |
| Scaffolder | Mechanical work: scaffolding, renames, test boilerplate, config | `scaffolder` agent, Sonnet |
