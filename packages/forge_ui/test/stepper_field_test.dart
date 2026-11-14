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
  }) => tester.pumpWidget(
    MaterialApp(
      theme: ForgeTheme.light(),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 200,
            child: StepperField(
              value: value,
              unit: '[UNIT]',
              step: step,
              min: min,
              max: max,
              hint: hint,
              errorText: errorText,
              enabled: enabled,
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
    await pump(tester, value: 60000, step: 1, errorText: 'Enter 1,000–50,000');

    expect(find.text('Enter 1,000–50,000'), findsOneWidget);
  });

  testWidgets('disabled, it fades and takes no taps', (tester) async {
    await pump(tester, enabled: false);

    await tester.tap(icon(ForgeIcons.add), warnIfMissed: false);
    await tester.tap(find.text('60.0'), warnIfMissed: false);
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
}
