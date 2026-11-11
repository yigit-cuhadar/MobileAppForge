# Design

Starts only when every feature in `SPEC.md` is ticked and the user has used
the whole app with the default theme.

1. Ask for direction with options: mood, color, typography, references the
   user likes, light/dark, how much motion. Record it under Design in `SPEC.md`.
2. Build the app's theme in `lib/app/theme.dart` (colors, type scale, shapes,
   component themes) and swap it in for `ForgeTheme`. Most screens should
   change without being edited.
3. Show two or three key screens for approval before touching the rest.
4. Then go screen by screen for layout, hierarchy, empty/loading/error states,
   icons, app icon and splash. Presentation layer only.
5. Add widget tests for the critical flows now that the UI is stable.
