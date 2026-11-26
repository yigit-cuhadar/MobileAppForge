import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child, {double scale = 1}) =>
      tester.pumpWidget(
        MaterialApp(
          theme: ForgeTheme.light(),
          builder: (context, page) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: page!,
          ),
          home: Scaffold(body: Center(child: child)),
        ),
      );

  ForgePalette colors(WidgetTester tester) =>
      ForgeStyle.of(tester.element(find.byType(Scaffold))).colors;

  ForgeIcon icon(WidgetTester tester) =>
      tester.widget<ForgeIcon>(find.byType(ForgeIcon));

  testWidgets('a 20px icon on a 44px target that takes taps', (tester) async {
    var taps = 0;
    await pump(
      tester,
      ForgeIconButton(
        icon: ForgeIcons.close,
        label: 'Remove',
        onPressed: () => taps++,
      ),
    );

    expect(tester.getSize(find.byType(ForgeIconButton)), const Size(44, 44));
    expect(icon(tester).size, 20);
    await tester.tapAt(
      tester.getTopLeft(find.byType(ForgeIconButton)) + const Offset(3, 3),
    );
    expect(taps, 1);
  });

  testWidgets('keeps its size at large text', (tester) async {
    await pump(
      tester,
      ForgeIconButton(
        icon: ForgeIcons.close,
        label: 'Remove',
        onPressed: () {},
      ),
      scale: 3,
    );
    expect(tester.getSize(find.byType(ForgeIconButton)), const Size(44, 44));
  });

  testWidgets('each variant takes its colour', (tester) async {
    for (final (variant, color) in [
      (ForgeIconButtonVariant.muted, (ForgePalette p) => p.inkMuted),
      (ForgeIconButtonVariant.ink, (ForgePalette p) => p.ink),
      (ForgeIconButtonVariant.onFeatured, (ForgePalette p) => p.onFeatured),
    ]) {
      await pump(
        tester,
        ForgeIconButton(
          icon: ForgeIcons.moreHoriz,
          label: 'More',
          onPressed: () {},
          variant: variant,
        ),
      );
      expect(icon(tester).color, color(colors(tester)), reason: '$variant');
    }
  });

  testWidgets('reads as a labelled button, disabled without onPressed', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pump(
      tester,
      const ForgeIconButton(
        icon: ForgeIcons.playArrow,
        label: 'Start this day',
        onPressed: null,
      ),
    );

    expect(
      tester.getSemantics(find.byType(ForgeIconButton)),
      matchesSemantics(
        label: 'Start this day',
        isButton: true,
        hasEnabledState: true,
      ),
    );
    final opacity = tester.widget<Opacity>(
      find.ancestor(of: find.byType(ForgeIcon), matching: find.byType(Opacity)),
    );
    expect(opacity.opacity, 0.4);
    semantics.dispose();
  });

  testWidgets('a toggled icon is a muted outline off and filled accent on', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    for (final on in [false, true]) {
      await pump(
        tester,
        ForgeIconButton(
          icon: ForgeIcons.star,
          label: 'Favourite',
          toggled: on,
          onPressed: () => taps++,
        ),
      );
      final p = colors(tester);
      expect((
        icon(tester).color,
        icon(tester).filled,
      ), on ? (p.accent, true) : (p.inkMuted, false));
      expect(
        tester.getSemantics(find.byType(ForgeIconButton)),
        matchesSemantics(
          label: 'Favourite',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          hasToggledState: true,
          isToggled: on,
        ),
      );
      await tester.tap(find.byType(ForgeIconButton));
    }
    expect(taps, 2);
    semantics.dispose();
  });

  BoxDecoration circle(WidgetTester tester) =>
      tester
              .widget<Container>(
                find.descendant(
                  of: find.byType(ForgeIconButton),
                  matching: find.byType(Container),
                ),
              )
              .decoration!
          as BoxDecoration;

  testWidgets('a sunken fill is a 36px surface-sunken circle on a 44px '
      'target', (tester) async {
    var taps = 0;
    await pump(
      tester,
      ForgeIconButton(
        icon: ForgeIcons.playArrow,
        label: 'Play',
        variant: ForgeIconButtonVariant.ink,
        fill: ForgeIconButtonFill.sunken,
        onPressed: () => taps++,
      ),
    );
    final p = colors(tester);

    expect(tester.getSize(find.byType(ForgeIconButton)), const Size(44, 44));
    expect(
      tester.getSize(
        find.descendant(
          of: find.byType(ForgeIconButton),
          matching: find.byType(Container),
        ),
      ),
      const Size.square(36),
    );
    expect(circle(tester).color, p.surfaceSunken);
    expect(circle(tester).border, isNull);
    expect(icon(tester).color, p.ink);
    await tester.tapAt(
      tester.getTopLeft(find.byType(ForgeIconButton)) + const Offset(2, 2),
    );
    expect(taps, 1);
  });

  testWidgets('a surface fill is a 40px surface circle with a line border', (
    tester,
  ) async {
    await pump(
      tester,
      ForgeIconButton(
        icon: ForgeIcons.pause,
        label: 'Pause',
        variant: ForgeIconButtonVariant.ink,
        fill: ForgeIconButtonFill.surface,
        onPressed: () {},
      ),
    );
    final p = colors(tester);

    expect(
      tester.getSize(
        find.descendant(
          of: find.byType(ForgeIconButton),
          matching: find.byType(Container),
        ),
      ),
      const Size.square(40),
    );
    expect(circle(tester).color, p.surface);
    expect(circle(tester).border, Border.all(color: p.line));
  });

  testWidgets('the text form shows its text and toggles to accent-soft', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    for (final on in [false, true]) {
      await pump(
        tester,
        ForgeIconButton.text(
          '0.5×',
          label: 'Half speed',
          variant: ForgeIconButtonVariant.ink,
          fill: ForgeIconButtonFill.surface,
          toggled: on,
          onPressed: () {},
        ),
      );
      final p = colors(tester);

      expect(find.byType(ForgeIcon), findsNothing);
      expect(
        tester.widget<Text>(find.text('0.5×')).style!.color,
        on ? p.onAccent : p.ink,
      );
      expect(circle(tester).color, on ? p.accent : p.surface);
      expect(circle(tester).border, on ? null : Border.all(color: p.line));
      expect(
        tester.getSemantics(find.byType(ForgeIconButton)),
        matchesSemantics(
          label: 'Half speed',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          hasToggledState: true,
          isToggled: on,
        ),
      );
    }
    semantics.dispose();
  });

  testWidgets('the text stays inside its circle at large text', (tester) async {
    await pump(
      tester,
      ForgeIconButton.text(
        '0.5×',
        label: 'Half speed',
        fill: ForgeIconButtonFill.surface,
        onPressed: () {},
      ),
      scale: 3,
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(ForgeIconButton)), const Size(44, 44));
    expect(
      tester.getRect(find.text('0.5×')).width,
      lessThanOrEqualTo(ForgeIconButton.surfaceSize),
    );
  });
}
