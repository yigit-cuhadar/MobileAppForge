import 'package:material_ui/material_ui.dart';
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
    expect(
      tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
      isFalse,
    );
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
    final ring =
        ((pill.foregroundDecoration! as ShapeDecoration).shape as StadiumBorder)
            .side;
    expect(
      ring.color,
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

  testWidgets('loading is a shimmering pill across the width', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ForgeTheme.light(),
        home: Scaffold(
          body: Center(
            child: SizedBox(width: 200, child: StepperField.loading()),
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(SkeletonBar)),
      const Size(200, StepperField.height),
    );
  });

  group('a row typed one after another', () {
    late FocusNode weight;
    late FocusNode reps;
    late List<String> log;

    setUp(() {
      weight = FocusNode();
      reps = FocusNode();
      log = [];
    });

    tearDown(() {
      weight.dispose();
      reps.dispose();
    });

    Future<void> pumpRow(
      WidgetTester tester, {
      bool bar = true,
      double scale = 1,
    }) async {
      var values = <String, double?>{'kg': 100, 'reps': 10};
      await tester.pumpWidget(
        MaterialApp(
          theme: ForgeTheme.light(),
          builder: (context, page) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: page!,
          ),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  const SizedBox(height: 100, child: Text('Elsewhere')),
                  Row(
                    spacing: Gap.sm,
                    children: [
                      for (final (unit, node, next) in [
                        ('kg', weight, reps),
                        ('reps', reps, null),
                      ])
                        Expanded(
                          child: StepperField(
                            value: values[unit],
                            unit: unit,
                            step: 1,
                            focusNode: node,
                            nextLabel: bar ? 'Next' : null,
                            onNext: next == null || !bar
                                ? null
                                : () {
                                    log.add('next');
                                    next.requestFocus();
                                  },
                            doneLabel: bar ? 'Done' : null,
                            onChanged: (v) {
                              log.add('$unit $v');
                              setState(() => values = {...values, unit: v});
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    TextField box(WidgetTester tester, int i) =>
        tester.widget<TextField>(find.byType(TextField).at(i));

    testWidgets('the app can start the typing', (tester) async {
      await pumpRow(tester);
      weight.requestFocus();
      await tester.pump();

      expect(box(tester, 0).controller!.text, '100');
      expect(
        box(tester, 0).controller!.selection,
        const TextSelection(baseOffset: 0, extentOffset: 3),
      );
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('one tap types the value with the keyboard open', (
      tester,
    ) async {
      await pumpRow(tester);
      await tester.tap(find.text('100'));
      await tester.pump();

      expect(weight.hasFocus, isTrue);
      expect(tester.testTextInput.hasAnyClients, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('the bar sits on the keyboard, which the Scaffold hides '
        'from the field', (tester) async {
      addTearDown(tester.view.resetViewInsets);
      await pumpRow(tester);
      await tester.tap(find.text('100'));
      await tester.pump();
      tester.view.viewInsets = const FakeViewPadding(bottom: 900);
      await tester.pump();

      final keyboardTop =
          tester.view.physicalSize.height / tester.view.devicePixelRatio -
          900 / tester.view.devicePixelRatio;
      expect(
        tester
            .getRect(
              find.ancestor(
                of: find.text('Done'),
                matching: find.byType(Container),
              ),
            )
            .bottom,
        keyboardTop,
      );
      expect(weight.hasFocus, isTrue);
    });

    testWidgets('Next sits at the bar\'s start and Done at its end', (
      tester,
    ) async {
      await pumpRow(tester);
      await tester.tap(find.text('100'));
      await tester.pump();

      final bar = tester.getRect(
        find
            .ancestor(of: find.text('Done'), matching: find.byType(Container))
            .first,
      );
      expect(tester.getTopLeft(find.text('Next')).dx, bar.left + Gap.md);
      expect(tester.getTopRight(find.text('Done')).dx, bar.right - Gap.md);
    });

    testWidgets('one tap on the next value moves the typing there and '
        'keeps what was typed', (tester) async {
      await pumpRow(tester, bar: false);
      await tester.tap(find.text('100'));
      await tester.pump();
      await tester.enterText(find.byType(TextField).at(0), '102');
      await tester.pump();

      await tester.tap(find.text('10'));
      await tester.pump();
      expect(weight.hasFocus, isFalse);
      expect(reps.hasFocus, isTrue);
      expect(find.text('102'), findsOneWidget);
      expect(log, ['kg 102.0']);
    });

    testWidgets('a tap elsewhere ends the typing', (tester) async {
      await pumpRow(tester);
      await tester.tap(find.text('100'));
      await tester.pump();
      expect(weight.hasFocus, isTrue);

      await tester.tap(find.text('Elsewhere'));
      await tester.pump();
      expect(weight.hasFocus, isFalse);
      expect(find.text('Done'), findsNothing);
    });

    testWidgets('Next moves on, Done closes the keyboard', (tester) async {
      await pumpRow(tester);
      await tester.tap(find.text('100'));
      await tester.pump();

      final bar = tester.getRect(
        find.ancestor(of: find.text('Done'), matching: find.byType(Container)),
      );
      expect(bar.height, StepperField.barHeight);
      final colors = ForgeStyle.of(tester.element(find.text('Done'))).colors;
      final frame = tester.widget<Container>(
        find.ancestor(of: find.text('Done'), matching: find.byType(Container)),
      );
      expect((frame.decoration! as BoxDecoration).color, colors.surfaceBar);
      expect(bar.bottom, tester.getRect(find.byType(Scaffold)).bottom);
      expect(
        tester.getCenter(find.text('Next')).dx,
        lessThan(tester.getCenter(find.text('Done')).dx),
      );

      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(log, ['next']);
      expect(reps.hasFocus, isTrue);
      expect(find.text('Done'), findsOneWidget);

      // The last field has no next: Next is greyed and does nothing.
      expect(
        tester.widget<Text>(find.text('Next')).style!.color,
        colors.lineStrong,
      );
      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(log, ['next']);

      await tester.tap(find.text('Done'));
      await tester.pump();
      expect(reps.hasFocus, isFalse);
      expect(find.text('Done'), findsNothing);
    });

    testWidgets('without a Done label there is no bar', (tester) async {
      await pumpRow(tester, bar: false);
      await tester.tap(find.text('100'));
      await tester.pump();
      expect(weight.hasFocus, isTrue);
      expect(find.text('Done'), findsNothing);
    });

    for (final scale in [1.0, 2.0, 3.0]) {
      testWidgets('the bar lays out at ${scale}x text', (tester) async {
        await pumpRow(tester, scale: scale);
        weight.requestFocus();
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('Next'), findsOneWidget);
      });
    }
  });
}
