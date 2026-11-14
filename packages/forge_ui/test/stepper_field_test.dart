import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';

void main() {
  late List<double?> changes;

  setUp(() => changes = []);

  Future<void> pump(
    WidgetTester tester, {
    double? value = 60,
    double step = 2.5,
    double? min,
    double? max,
    double? hint,
    String? errorText,
    bool enabled = true,
    bool grouped = true,
    bool signed = false,
    bool invalid = false,
    bool compact = false,
    double width = 200,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: ForgeTheme.light(),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: StepperField(
              value: value,
              unit: '[UNIT]',
              step: step,
              min: min,
              max: max,
              hint: hint,
              errorText: errorText,
              enabled: enabled,
              grouped: grouped,
              signed: signed,
              invalid: invalid,
              compact: compact,
              onChanged: changes.add,
            ),
          ),
        ),
      ),
    ),
  );

  Finder icon(ForgeIconData data) =>
      find.byWidgetPredicate((w) => w is ForgeIcon && w.icon == data);

  Opacity fadeOf(WidgetTester tester, ForgeIconData data) => tester.widget(
    find.ancestor(of: icon(data), matching: find.byType(Opacity)).first,
  );

  testWidgets('minus and plus move the value by the step', (tester) async {
    await pump(tester, value: 82.5);

    await tester.tap(icon(ForgeIcons.add));
    await tester.tap(icon(ForgeIcons.remove));

    expect(changes, [85, 80]);
    expect(find.text('82.5'), findsOneWidget);
  });

  testWidgets('at the lower bound minus fades and stops', (tester) async {
    await pump(tester, value: 0, step: 1, min: 0);

    await tester.tap(icon(ForgeIcons.remove));

    expect(changes, isEmpty);
    expect(fadeOf(tester, ForgeIcons.remove).opacity, 0.4);
    expect(fadeOf(tester, ForgeIcons.add).opacity, 1);
  });

  testWidgets('plus never passes the upper bound', (tester) async {
    await pump(tester, value: 49, step: 5, max: 50);

    await tester.tap(icon(ForgeIcons.add));

    expect(changes, [50]);
  });

  testWidgets('empty, it shows the hint faded and steps from it', (
    tester,
  ) async {
    await pump(tester, value: null, hint: 62.5);

    final hint = tester.widget<Text>(find.text('62.5'));
    expect(
      hint.style!.color,
      ForgeTheme.light().extension<ForgeStyle>()!.colors.inkSubtle,
    );

    await tester.tap(icon(ForgeIcons.add));
    expect(changes, [65]);
  });

  testWidgets('empty without a hint, it shows a dash', (tester) async {
    await pump(tester, value: null);

    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('tapping the value types it and reports each edit', (
    tester,
  ) async {
    await pump(tester, value: 60, step: 1);

    await tester.tap(find.text('60'));
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), '62.');
    await tester.enterText(find.byType(TextField), '');
    await tester.enterText(find.byType(TextField), '60000');

    expect(changes, [62, null, 60000]);
  });

  testWidgets('the error shows under the pill', (tester) async {
    // The test font draws every glyph 1em wide.
    await pump(
      tester,
      value: 60000,
      step: 1,
      errorText: 'Enter 1,000–50,000',
      width: 240,
    );

    expect(find.text('60,000'), findsOneWidget);
    expect(find.text('Enter 1,000–50,000'), findsOneWidget);
  });

  testWidgets('typing starts from the value without grouping', (tester) async {
    await pump(tester, value: 60000, step: 1, width: 240);

    await tester.tap(find.text('60,000'));
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '60000',
    );
  });

  testWidgets('groups the thousands by default', (tester) async {
    await pump(tester, value: 1000, step: 1);

    expect(find.text('1,000'), findsOneWidget);
  });

  testWidgets('a year stays whole when grouping is off', (tester) async {
    await pump(tester, value: 1995, step: 1, grouped: false);

    expect(find.text('1995'), findsOneWidget);
  });

  testWidgets('disabled, it fades and takes no taps', (tester) async {
    await pump(tester, enabled: false);

    await tester.tap(icon(ForgeIcons.add), warnIfMissed: false);
    await tester.tap(find.text('60'), warnIfMissed: false);
    await tester.pump();

    expect(changes, isEmpty);
    expect(find.byType(TextField), findsNothing);
    expect(
      tester
          .widget<Opacity>(
            find
                .descendant(
                  of: find.byType(StepperField),
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity,
      0.4,
    );
  });

  testWidgets('shows the fewest decimals the step allows', (tester) async {
    await pump(tester, value: 60, step: 2.5);
    expect(find.text('60'), findsOneWidget);

    await pump(tester, value: 62.5, step: 2.5);
    expect(find.text('62.5'), findsOneWidget);

    await pump(tester, value: 82.5, step: 5);
    expect(find.text('82.5'), findsOneWidget);
  });

  testWidgets('typing starts from the shown decimals', (tester) async {
    await pump(tester, value: 60, step: 2.5);

    await tester.tap(find.text('60'));
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '60',
    );
  });

  testWidgets('the signed form marks a value above zero with +', (
    tester,
  ) async {
    await pump(tester, value: 10, step: 2.5, signed: true);
    expect(find.text('+10'), findsOneWidget);

    await pump(tester, value: 0, step: 2.5, signed: true);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('the compact form is 40px with 30px buttons', (tester) async {
    await pump(tester, compact: true);

    final pill = find
        .descendant(
          of: find.byType(StepperField),
          matching: find.byType(Container),
        )
        .first;
    expect(tester.getSize(pill).height, StepperField.compactHeight);
    expect(
      tester
          .getSize(
            find
                .ancestor(
                  of: icon(ForgeIcons.add),
                  matching: find.byType(Container),
                )
                .first,
          )
          .height,
      StepperField.compactButtonSize,
    );

    await tester.tap(icon(ForgeIcons.add));
    expect(changes, [62.5]);
  });

  testWidgets('invalid rings the pill without a message', (tester) async {
    await pump(tester, value: null, invalid: true);

    final pill = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(StepperField),
            matching: find.byType(Container),
          )
          .first,
    );
    final ring = (pill.foregroundDecoration! as BoxDecoration).border!;
    expect(
      ring.top.color,
      ForgeTheme.light().extension<ForgeStyle>()!.colors.danger,
    );
    expect(find.byType(Text), findsNWidgets(2));
  });

  testWidgets('StepperFieldError shows the row message in danger', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ForgeTheme.light(),
        home: const Scaffold(body: StepperFieldError('Enter a value')),
      ),
    );

    expect(
      tester.widget<Text>(find.text('Enter a value')).style!.color,
      ForgeTheme.light().extension<ForgeStyle>()!.colors.danger,
    );
  });
}
