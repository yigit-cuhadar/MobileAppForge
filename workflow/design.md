# Design

Starts when every feature in `SPEC.md` is ticked and the user has used the
whole app with the default theme. A feature that waits on something outside
the code (store accounts) may stay open; record that in `SPEC.md`. A design
decision on a later feature follows the same rules whenever it comes up.

## Order

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

## Drawing a decision, then asking

The owner decides from drawings. Every design-phase question (looks, texts,
flows, and any choice a board or an earlier answer leaves open) is drawn
before it is asked.

- One canvas per batch: a page of phone drawings, one row per decision, rows
  in one column in the order they will be asked. In Claude it is a Design
  canvas artifact; in another tool, a self-contained HTML page written to the
  gitignored `design/canvas/` and opened in the browser. A row is named
  "<code> · <short question>" with a one or two line intro (in the owner's
  language) on what differs and why it is a decision.
- Columns, each a 390px phone drawn as a real screen in the studio's look
  with every element present: first what the code does now (or the board,
  when only the board has it), then option A, B, … with a one-line note.
  Exactly one option is the recommendation, with a green tag and border. Only
  the option's difference changes between columns; nothing is clipped.
- Different states or aspects get separate rows, never rival bundles.
- Then ask in canvas order, one decision per question (up to four per
  dialog), recommendation first and labelled as recommended, naming the row.
  Record each answer at once; an answer that adds something new becomes a
  new drawn row before it is built.
- The app's SPEC gets one row per batch under Design: date, topic, the picks
  in a few words, the canvas link when there is one.
- Colours stay muted: neutral grounds, one desaturated accent, colour only
  for status.

## Studios

Each app's design lives in its studio page; MobileAppForge Studio holds the
shared components. The page in git is the source: `design/studio.html` in
this repo, `design/studio.html` in the app's repo. It is one self-contained
file that opens in any browser.

- Change a studio by editing the page's data (`<script id="data">`), run
  `tools/studio_check.py <page>` (`--fix` rebuilds the lists below), and
  commit. The claude.ai link of a studio (in the app's SPEC under Design) is
  a published copy for the owner to open anywhere: a Claude session
  republishes the file to it in the same change; another tool says in its
  report that the link is behind.
- Each thing is drawn once. A Forge component is drawn only in MobileAppForge
  Studio; an app's studio lists the Forge components it uses with their
  screens and links each to its card. A screen is a screen board, not also a
  component card; a component's forms and states share one card; a rule
  lives in one guide, and component looks live in their cards.
- MobileAppForge Studio is app-free like the packages: neutral placeholder
  content ("Item title", [VALUE]), sample pages with [APP NAME], neutral
  state names (done, light, planned, missed, today) that apps map, and no
  app's name or origin story. Its cards list usage inside Forge only.
- Every drawn part names its components in the markup (`data-c="Name"`,
  several names separated by spaces; `Text` and `Layout` for plain text and
  wrappers). "uses" and "used in" are built from these tags by the check,
  never kept by hand. The check stops on an untagged part or a tag naming a
  missing component. A component used nowhere is allowed; it sits last in
  its group.
- Before drawing a new part, pick its component; a part with no component
  is a decision for the owner first, then a new component.

## Widgetbook

Every component built in code has Widgetbook use cases for the forms and
states on its studio card: a Forge component in `widgetbook/`, an app
component in `apps/<name>/widgetbook`. Use cases are `@UseCase` functions
(widgetbook_generator); the catalog has the preset and brightness, device
frame, text scale and 8px grid addons. Run it locally on the web
(`flutter run -d chrome` in the catalog's folder); CI generates and builds
both catalogs on every PR.
