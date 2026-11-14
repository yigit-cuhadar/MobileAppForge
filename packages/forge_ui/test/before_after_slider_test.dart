import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:forge_ui/src/widgets/forge_slider.dart' show SliderTrack;

import 'test_photo.dart';

void main() {
  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      theme: ForgeTheme.light(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: BeforeAfterSlider(
            views: [
              for (final name in ['View A', 'View B'])
                BeforeAfterView(
                  name: name,
                  before: photo,
                  after: photo,
                  beforeDate: '$name 1',
                  afterDate: '$name 2',
                  change: '[CHANGE]',
                ),
            ],
            sliderLabel: 'Before and after',
          ),
        ),
      ),
    ),
  );

  Opacity later(WidgetTester tester) => tester.widget(
    find.descendant(
      of: find.byType(BeforeAfterSlider),
      matching: find.byType(Opacity),
    ),
  );

  testWidgets('opens on the later photo of the first view', (tester) async {
    await pump(tester);

    expect(find.text('View A'), findsNWidgets(2));
    expect(find.text('View A 1 → View A 2 · [CHANGE]'), findsOneWidget);
    expect(find.text('View A 2 · 100%'), findsOneWidget);
    expect(later(tester).opacity, 1);
  });

  testWidgets('a tap on the slider fades to that blend', (tester) async {
    await pump(tester);
    final track = tester.getRect(find.byType(SliderTrack));

    await tester.tapAt(track.centerLeft + Offset(track.width * 0.3, 0));
    await tester.pump();

    expect(later(tester).opacity, closeTo(0.3, 0.01));
    expect(find.text('View A 1 · 30%'), findsOneWidget);
  });

  testWidgets('a chip switches the view', (tester) async {
    await pump(tester);

    await tester.tap(find.widgetWithText(ForgeChip, 'View B'));
    await tester.pump();

    expect(find.text('View B 1 → View B 2 · [CHANGE]'), findsOneWidget);
  });

  testWidgets('the slider reads out its name and blend', (tester) async {
    await pump(tester);

    final slider = tester
        .getSemantics(find.bySemanticsLabel('Before and after'))
        .getSemanticsData();
    expect(slider.value, '100%');
    expect(slider.hasAction(SemanticsAction.increase), isTrue);
  });
}
