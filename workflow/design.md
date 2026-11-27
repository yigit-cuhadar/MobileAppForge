# Design

Starts when every feature in `SPEC.md` is ticked and the user has used the
whole app with the default theme. A feature that waits on something outside
the code (store accounts) may stay open; record that in `SPEC.md`.

The rules are in `AGENTS.md`: Working with the user (every decision is drawn,
then asked), Design studios (the studio is the only design source) and
Widgetbook. This file only gives the order.

1. **UX pass**, when flows or structure need rework: walk every flow on the
   simulator, list findings per flow (the user's own notes first), draw the
   variants, ask, and build the picks with the default theme as in
   `workflow/build.md`. Nothing is removed without the user saying so; say
   where each moved thing lives.
2. **Direction**: draw two or three directions on one key screen, then the
   survivors on more screens; the pick becomes the app's studio and its theme.
3. **Screens and components**: draw each screen and component in the studio,
   ask what the drawing leaves open, then build it in code to match, with its
   Widgetbook use cases. Presentation layer only.
4. Add widget tests for the critical flows once the UI is stable.

Each batch's picks go under Design in `SPEC.md`, as one row.
