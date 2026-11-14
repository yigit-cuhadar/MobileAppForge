import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:forge_ui/src/widgets/forge_slider.dart' show SliderTrack;

void main() {
  late List<double> changes;

  setUp(() => changes = []);

  const width = 300.0;

  Future<void> pump(
    WidgetTester tester, {
    double value = 60,
    double? step,
    bool enabled = true,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: ForgeTheme.light(),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: ForgeSlider(
              label: 'Label',
              unit: 'u',
              min: 0,
              max: 100,
              step: step,
              value: value,
              onChanged: enabled ? changes.add : null,
            ),
          ),
        ),
      ),
    ),
  );

  Rect track(WidgetTester tester) => tester.getRect(find.byType(SliderTrack));

  testWidgets('shows the label, the value with its unit and the ends', (
    tester,
  ) async {
    await pump(tester, step: 1);

    expect(find.text('Label'), findsOneWidget);
    expect(find.text('60 u'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('100'), findsOneWidget);
  });

  testWidgets('a tap on the track moves the thumb there', (tester) async {
    await pump(tester);

    await tester.tapAt(track(tester).centerLeft + const Offset(width / 4, 0));

    expect(changes.single, closeTo(25, 0.01));
  });

  testWidgets('with a step the value snaps and a mark sits at each step', (
    tester,
  ) async {
    await pump(tester, step: 25);

    await tester.tapAt(track(tester).centerLeft + const Offset(width * 0.3, 0));

    expect(changes.single, 25);
    // Five marks, the track, the fill and the thumb.
    expect(
      find.descendant(
        of: find.byType(SliderTrack),
        matching: find.byType(Positioned),
      ),
      findsNWidgets(8),
    );
  });

  testWidgets('while dragged the thumb grows and a bubble shows the value', (
    tester,
  ) async {
    await pump(tester, step: 1);
    final thumb = find.byKey(SliderTrack.thumbKey);
    expect(tester.getSize(thumb).width, 20);

    final gesture = await tester.startGesture(
      track(tester).centerLeft + const Offset(width * 0.6, 0),
    );
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump();

    expect(tester.getSize(thumb).width, 28);
    expect(find.text('60 u'), findsNWidgets(2));

    await gesture.up();
    await tester.pump();

    expect(tester.getSize(thumb).width, 20);
    expect(find.text('60 u'), findsOneWidget);
    expect(changes, isNotEmpty);
  });

  testWidgets('disabled, it fades and takes no taps', (tester) async {
    await pump(tester, enabled: false);

    await tester.tapAt(track(tester).center);

    expect(changes, isEmpty);
    expect(
      tester
          .widget<Opacity>(
            find.descendant(
              of: find.byType(ForgeSlider),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      0.4,
    );
  });

  testWidgets('reads as a slider that steps', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, step: 5);
    final node = tester.getSemantics(find.byType(ForgeSlider));

    expect(
      node,
      matchesSemantics(
        isSlider: true,
        hasEnabledState: true,
        isEnabled: true,
        label: 'Label',
        value: '60 u',
        hasIncreaseAction: true,
        hasDecreaseAction: true,
      ),
    );
    node.owner!.performAction(node.id, SemanticsAction.increase);
    expect(changes, [65]);
    handle.dispose();
  });

  testWidgets('steps over an empty range mark the start, not NaN', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ForgeTheme.light(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: ForgeSlider(
                label: 'Label',
                unit: 'u',
                min: 5,
                max: 5,
                step: 1,
                value: 5,
                onChanged: changes.add,
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final steps = tester.widget<SliderTrack>(find.byType(SliderTrack)).steps!;
    expect(steps, [0.0]);
  });
}
