import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:forge_ui/src/widgets/forge_slider.dart' show SliderTrack;

import 'test_photo.dart';

void main() {
  Future<void> pumpSlider(WidgetTester tester, BeforeAfterSlider slider) =>
      tester.pumpWidget(
        MaterialApp(
          theme: ForgeTheme.light(),
          home: Scaffold(body: SingleChildScrollView(child: slider)),
        ),
      );

  Future<void> pump(
    WidgetTester tester, {
    ComparedPhoto? before,
    ComparedPhoto? after,
  }) => pumpSlider(
    tester,
    BeforeAfterSlider(
      views: [
        for (final name in ['View A', 'View B'])
          BeforeAfterView(
            name: name,
            before: before ?? ComparedPhoto(photo),
            after: after ?? ComparedPhoto(photo),
            beforeDate: '$name 1',
            afterDate: '$name 2',
            change: '[CHANGE]',
          ),
        BeforeAfterView.single(
          name: 'View C',
          photo: ComparedPhoto(photo),
          date: 'View C 1',
        ),
      ],
      sliderLabel: 'Before and after',
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

  testWidgets('a missing side is a frame with its text that fades', (
    tester,
  ) async {
    await pump(tester, after: const ComparedPhoto.missing('No photo'));

    expect(find.text('No photo'), findsOneWidget);
    expect(
      find.ancestor(of: find.text('No photo'), matching: find.byType(Opacity)),
      findsOneWidget,
    );
    expect(find.text('View A 2 · 100%'), findsOneWidget);
  });

  testWidgets('a side being fetched shimmers', (tester) async {
    await pump(tester, before: const ComparedPhoto.loading());

    expect(find.byType(SkeletonBar), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('a single view shows its date and no slider', (tester) async {
    await pump(tester);

    await tester.tap(find.widgetWithText(ForgeChip, 'View C'));
    await tester.pump();

    expect(find.byType(SliderTrack), findsNothing);
    expect(find.text('View C 1'), findsNWidgets(2));
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('loading shimmers the frame and the slider', (tester) async {
    await pumpSlider(tester, const BeforeAfterSlider.loading());

    expect(find.byType(SkeletonBar), findsNWidgets(2));
    expect(find.byType(ForgeChip), findsNothing);
  });

  testWidgets('the later date is an accent link when it can be tapped', (
    tester,
  ) async {
    var taps = 0;
    await pumpSlider(
      tester,
      BeforeAfterSlider(
        views: [
          BeforeAfterView(
            name: 'View A',
            before: ComparedPhoto(photo),
            after: ComparedPhoto(photo),
            beforeDate: 'Day 1',
            afterDate: 'Day 2',
            change: '[CHANGE]',
          ),
        ],
        sliderLabel: 'Before and after',
        onLaterDateTap: () => taps++,
      ),
    );
    final link = find.text('Day 2').first;
    final context = tester.element(link);
    expect(
      tester.widget<Text>(link).style?.color,
      ForgeStyle.of(context).colors.accent,
    );
    await tester.tap(link);
    expect(taps, 1);
  });

  testWidgets('one view shows no chips', (tester) async {
    await pumpSlider(
      tester,
      BeforeAfterSlider(
        views: [
          BeforeAfterView.single(
            name: 'View A',
            photo: ComparedPhoto(photo),
            date: 'Day 1',
          ),
        ],
        sliderLabel: 'Before and after',
      ),
    );
    expect(find.byType(ForgeChip), findsNothing);
    expect(find.text('View A'), findsOneWidget);
  });

  testWidgets('without a change the line holds the dates alone', (
    tester,
  ) async {
    await pumpSlider(
      tester,
      BeforeAfterSlider(
        views: [
          BeforeAfterView(
            name: 'View A',
            before: ComparedPhoto(photo),
            after: ComparedPhoto(photo),
            beforeDate: 'Day 1',
            afterDate: 'Day 2',
          ),
        ],
        sliderLabel: 'Before and after',
      ),
    );
    expect(find.text('Day 1 → Day 2'), findsOneWidget);
  });
}
