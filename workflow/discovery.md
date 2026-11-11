# Discovery

Goal: an approved `SPEC.md`. No code in this phase.

Ask in rounds, general to specific. Each round is at most 4 questions, each
with 2-4 options and your recommendation first. Use what earlier answers imply
instead of asking again; skip questions the idea already answers.

1. **Product** — what problem, for whom, the one thing a user does most
   often, what "done for v1" means.
2. **Scope** — propose a v1 feature list from round 1 and let the user cut or
   add. Push back on anything not needed for the core loop.
3. **Accounts and data** — sign-in methods (or none), what is private vs
   shared between users, offline needs, languages.
4. **Money and services** — free / ads / subscription / one-time; push
   notifications; anything needing Cloud Functions or a third-party API. State
   the cost of each (Blaze plan, store fees, API pricing).
5. **Screens** — propose the screen list and navigation per feature; confirm.

Then:

- Derive the Firestore data model (collections, fields, access rules) and the
  ordered feature list. Order by dependency, core loop first.
- Run `tools/new_app.sh <name> <org>` only after the user approves the name;
  write `SPEC.md` in the new app. Until then keep the draft in the chat.
- Present the spec summary and get explicit approval before the build phase.
