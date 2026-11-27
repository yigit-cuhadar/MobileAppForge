# MobileAppForge

A system for building many Flutter + Firebase apps. This repo holds the
workflow, shared packages and app template. Each app is its own repo, cloned
into `apps/<name>` (gitignored here). Always work from this root.

Talk to the user in their language. Code, comments and commits are English.

Everything needed to continue is in the two repos and in `LOCAL.md`; nothing
depends on one tool's memory or chat history. Any agent in any tool works
from this file.

## Layout

| Path | Purpose |
|---|---|
| `workflow/` | One file per phase. Read only the phase you are in. |
| `packages/` | The shared `forge_*` packages. Every app starts with `forge_core`, `forge_ui`, `forge_firebase` and `forge_auth`. |
| `template/` | Overlay copied onto `flutter create` by `tools/new_app.sh`. |
| `tools/` | Scripts; each opens with its own usage. |
| `design/studio.html` | MobileAppForge Studio, the shared components' design. An app's is `apps/<name>/design/studio.html`. |
| `widgetbook/` | Widgetbook of the `forge_ui` components. Each app has its own in `apps/<name>/widgetbook`. |
| `apps/<name>/SPEC.md` | The app's state. Resume any app from here. |
| `LOCAL.md` | Gitignored notes of this machine and these accounts: ids, devices, how credentials are reached here. Read it when it exists. |

## Phases

1. **Discovery** — `workflow/discovery.md`. Ends with an approved `SPEC.md`.
2. **Build** — `workflow/build.md`. Scaffold, then one feature at a time.
3. **Design** — `workflow/design.md`. After every feature is ticked; a UX pass
   first when flows need rework.
4. **Release** — `workflow/release.md`. Credentials, device installs,
   TestFlight. Store listing, submission and Android are not automated yet:
   build them with the first app that reaches them, then move them into
   `tools/`.

To resume: read `apps/<name>/SPEC.md` from the top through Open. Now says
where the app stands and what is next; read only the sections it points to,
and the workflow file of the phase that work belongs to.

## Working with the user

- Ask before decisions that are costly or hard to reverse: product scope, data
  model, auth methods, paid services (Blaze plan, Cloud Functions), anything
  public or irreversible (creating repos/projects, publishing, deleting data).
  Offer 2-4 options with a recommendation first.
- Put each such decision to the user as a question with options at the
  moment it comes up, through the tool's question dialog, one question per
  decision. Never leave it as a note inside a status report or a sub-agent's
  summary. Work that does not depend on the answer goes on meanwhile.
- Sub-agents never take these decisions: they stop and report each one with
  2-4 options and a recommendation, and the main session asks the user.
- In the design phase every question is drawn before it is asked
  (`workflow/design.md`).
- Decide the rest yourself and note it in `SPEC.md`: app-wide decisions under
  Decisions, how a feature behaves under Feature notes.
- Never ask the user to do by hand what an API or CLI can do. If a credential
  is missing, ask them to run `tools/secret.sh set <NAME>` (it prompts; the
  value never enters the chat) and then do the work yourself. Read secrets
  only as `$(tools/secret.sh get <NAME>)` inside a command; never print them.
- Approval points: SPEC, data model, then a short demo after each feature group.

## Where things are written

- `SPEC.md` is the app's state: decisions with a one-line reason, behaviour
  the code does not make obvious, external setup, open work. Keep its Now
  block and Open list true in the same change that moves the work. It holds
  no deliverables (store listings, legal text, mail and notification copy:
  files of their own), no looks (the studio), nothing the code plainly says
  and no story of how a decision was reached.
- Rules for every app go here; a phase's procedure goes in its workflow file.
- A fact about this machine or these accounts goes in `LOCAL.md`, never in a
  repo: both repos may be public.
- No other new `.md` files. Comment only what the code cannot say.

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
- UI before the design phase: `forge_ui` widgets, `Gap` spacing, theme colors
  only. No custom styling, no hard-coded colors or sizes.
- Write current Flutter and Dart best practice. Code generation through
  `build_runner` is allowed: new models may use freezed and
  json_serializable; existing hand-written models stay as they are.
- Small use cases of a feature share one `<feature>_usecases.dart`.
  `packages/forge_auth` is the reference implementation of all of the above.

Keep it lean: no speculative options or unused parameters, in packages too.

## Shared packages

Anything not specific to one app's product is built as a package in
`packages/` from the start: infrastructure, generic widgets, engines and
integrations another app could use (auth, a 3D viewer, purchases, health
data, notifications). Only the app's own features, data model and content
live in the app. When unsure, make it a package. This repo is public, so
packages hold no secrets and no app content.

A package knows nothing about the app using it: no app names, no app-specific
codes or strings; the app passes those in.

Changing a package: edit, `tools/check.sh <package>`, PR to this repo, then
tag `vX.Y.Z` on main. Apps pin the tag's commit and upgrade deliberately by
changing the `ref` of every forge package, in the app and its `widgetbook/`,
to the new tag's commit (`git rev-list -n1 vX.Y.Z`). While a package and an
app are developed together, point the app and its `widgetbook/` at the local
copy with a gitignored `pubspec_overrides.yaml` (`dependency_overrides` with
a `path` to `packages/<name>`); merge and tag the package before the app PR
that needs it. When several app features change Forge at once they share that
pin: test them from one integration branch and land them as one app PR.

## Design

The studio pages are the only design source: `design/studio.html` here for
the shared components, `apps/<name>/design/studio.html` for an app. Each is
one self-contained page that opens in any browser. An app's SPEC keeps design
decisions as a table, never how things look. Colours stay muted. Every
component built in code has Widgetbook use cases. The rules for drawing,
asking, studios and Widgetbook are in `workflow/design.md`.

## Tests

Unit-test use cases with logic, repositories and cubits (`mocktail`,
`bloc_test`, `fake_cloud_firestore`). No widget or integration tests of app
screens before the design phase; verify screens on the simulator instead.
Packages test their widgets' behaviour (gestures, callbacks) with widget tests.

## Git

- `gh` CLI for everything on GitHub. The forge and each app are separate
  repos under one owner (`gh repo view` in each names it).
- Never commit to `main`. One branch and PR per feature; squash-merge when CI
  is green. Commit messages: imperative, what and why.
- Before every commit: `dart format`, `flutter analyze`, `flutter test` in the
  package or app you touched. CI repeats this on every PR.
- The two main checkouts, this root and `apps/<name>`, stay on `main`: pull
  them before reading or starting anything, and do no work in them. Work
  happens in a git worktree beside them (`git worktree add`), which is
  removed with its local branch when its PR is merged. A worktree left behind
  is unfinished work: its branch name says what.

## Machine limits (M1, 16 GB)

- One simulator at a time. Every device check runs on iOS; no test of any
  kind runs on Android (emulator or device) until an app's Android release
  is being prepared.
- No Firebase Emulator. Develop against the app's `-dev` project.
- Run independent work in parallel: at most three sub-agents at once, each on
  its own branch, and in its own git worktree when two share a repo. Work is
  independent when it touches different files and neither needs the other's
  result.
- Never two Flutter builds or simulator runs at once: sub-agents only format,
  analyze and unit-test; the Architect does every device check, one at a time.
- Memory turns into swap on the same disk: run tests with `--timeout 60s`,
  never build while an agent runs the full suite, and kill a runaway
  `flutter_tester` first when free disk drops. After a device check delete the
  worktree's `build/` and its `DerivedData/Runner-*` entry.
- Analyze and test only what you changed; CI covers the rest.

## Roles

The workflow is written in roles so it runs in any tool. A tool without
sub-agents plays all roles itself, in order. Where a tool has sub-agents,
give the Architect the strongest model and the Scaffolder the cheapest;
Claude Code's definitions are in `.claude/agents/`.

| Role | Does |
|---|---|
| Architect | Discovery, data model, feature breakdown, hard bugs, every device check, final call. The main session. |
| Implementer | One feature end to end, with tests |
| Reviewer | Reviews each feature diff against this file and the spec |
| Scaffolder | Mechanical work: scaffolding, renames, test boilerplate, config |
