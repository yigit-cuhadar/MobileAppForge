# Design

Starts only when every feature in `SPEC.md` is ticked and the user has used
the whole app with the default theme. The user may start it with a feature
still open when that feature waits on something outside the code (store
accounts); record that in `SPEC.md`.

## UX pass

If the user wants structure or flows changed, do that first, with the default
theme, so nothing is styled that will be rebuilt. It is build work, not design:

1. Walk every flow on the simulator and list findings per flow; the user's own
   notes come first.
2. For each flow to rebuild, show two or three wireframe variants (layout and
   steps only) with a recommendation, the navigation skeleton first. The user
   picks.
3. Record the picks under Feature notes and add the flows as a feature group
   in `SPEC.md`. Nothing is removed without the user saying so; say where each
   moved thing lives.
4. Build them one at a time as in `workflow/build.md`.

## Visual design

1. Ask for direction with options: mood, color, typography, references the
   user likes, light/dark, how much motion. Record it under Design in `SPEC.md`.
2. Build the app's theme in `lib/app/theme.dart` (colors, type scale, shapes,
   component themes) and swap it in for `ForgeTheme`. Most screens should
   change without being edited.
3. Show two or three key screens for approval before touching the rest.
4. Then go screen by screen for layout, hierarchy, empty/loading/error states,
   icons, app icon and splash. Presentation layer only.
5. Add widget tests for the critical flows now that the UI is stable.
