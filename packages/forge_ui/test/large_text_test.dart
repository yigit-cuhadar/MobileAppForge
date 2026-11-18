import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:forge_ui/src/widgets/day_circle.dart';

/// Every widget here lays out at the largest text sizes in a phone-wide
/// box, and keeps its drawn size at normal text.
void main() {
  const scales = [1.0, 2.0, 3.0];

  Future<void> pump(WidgetTester tester, double scale, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ForgeTheme.light(),
        builder: (context, page) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: page!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(width: 390, child: child),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull, reason: 'at ${scale}x');
  }

  double height(WidgetTester tester, Finder finder) =>
      tester.getSize(finder).height;

  group('ForgeButton', () {
    for (final scale in scales) {
      testWidgets('lays out at ${scale}x', (tester) async {
        await pump(
          tester,
          scale,
          Column(
            children: [
              for (final size in ForgeButtonSize.values)
                ForgeButton(
                  label: 'Log workout',
                  leadingIcon: ForgeIcons.add,
                  size: size,
                  onPressed: () {},
                ),
              Row(
                children: [
                  Expanded(
                    child: ForgeButton(label: 'Change days', onPressed: () {}),
                  ),
                  Expanded(
                    child: ForgeButton(label: 'Log workout', onPressed: () {}),
                  ),
                ],
              ),
              ForgeAddButton(label: 'Add item', onPressed: () {}),
            ],
          ),
        );
      });
    }

    testWidgets('keeps its heights at normal text', (tester) async {
      await pump(
        tester,
        1,
        Column(
          children: [
            for (final size in ForgeButtonSize.values)
              ForgeButton(label: 'Start', size: size, onPressed: () {}),
            ForgeAddButton(label: 'Add item', onPressed: () {}),
          ],
        ),
      );

      final boxes = find.descendant(
        of: find.byType(ForgeButton),
        matching: find.byType(Container),
      );
      expect(height(tester, boxes.at(0)), ForgeTheme.buttonHeight);
      expect(height(tester, boxes.at(1)), ForgeButton.smallHeight);
      expect(height(tester, boxes.at(2)), ForgeTheme.buttonHeightLg);
      expect(height(tester, find.byType(ForgeAddButton)), ForgeTheme.tapMin);
    });

    testWidgets('grows to its label at large text', (tester) async {
      await pump(tester, 3, ForgeButton(label: 'Start', onPressed: () {}));

      final box = find.descendant(
        of: find.byType(ForgeButton),
        matching: find.byType(Container),
      );
      expect(height(tester, box), greaterThan(ForgeTheme.buttonHeight));
      expect(
        height(tester, box),
        greaterThanOrEqualTo(height(tester, find.text('Start'))),
      );
    });
  });

  group('ForgeAppBar.value', () {
    ForgeAppBar bar() => ForgeAppBar.value(
      leading: ForgeAppBarAction.icon(
        icon: ForgeIcons.expandMore,
        label: 'Minimise',
        onPressed: () {},
      ),
      value: '24:16',
      subtitle: 'Item title · 1 of 6',
      actions: [
        ForgeButton(
          label: 'Finish',
          size: ForgeButtonSize.small,
          onPressed: () {},
        ),
        ForgeAppBarAction.icon(
          icon: ForgeIcons.moreHoriz,
          label: 'More',
          onPressed: () {},
        ),
      ],
    );

    for (final scale in scales) {
      testWidgets('lays out at ${scale}x', (tester) async {
        await pump(tester, scale, bar());

        final height = tester.getSize(find.byType(ForgeAppBar)).height;
        if (scale == 1) {
          expect(height, ForgeAppBar.valueHeight);
        } else {
          expect(height, greaterThan(ForgeAppBar.valueHeight));
        }
      });
    }

    testWidgets('keeps its actions beside the value at normal text', (
      tester,
    ) async {
      await pump(tester, 1, bar());

      expect(
        tester.getRect(find.text('Finish')).top,
        lessThan(tester.getRect(find.text('24:16')).bottom),
      );
    });

    testWidgets('puts its actions under the value at large text', (
      tester,
    ) async {
      await pump(tester, 3, bar());

      final finish = tester.getRect(find.text('Finish'));
      expect(
        finish.top,
        greaterThan(tester.getRect(find.text('Item title · 1 of 6')).bottom),
      );
      // At the end of the bar.
      expect(
        tester.getRect(find.byType(ForgeAppBarAction).last).right,
        tester.getRect(find.byType(ForgeAppBar)).right - Gap.xs,
      );
    });

    testWidgets('grows a Scaffold\'s app bar and the page starts under it', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ForgeTheme.light(),
          builder: (context, page) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(3)),
            child: page!,
          ),
          home: Center(
            child: SizedBox(
              width: 390,
              child: Scaffold(appBar: bar(), body: const Text('Body')),
            ),
          ),
        ),
      );

      final barRect = tester.getRect(find.byType(ForgeAppBar));
      expect(barRect.height, greaterThan(ForgeAppBar.valueHeight));
      expect(tester.getRect(find.text('Body')).top, barRect.bottom);
    });
  });

  group('StepperField', () {
    Widget fields({bool compact = false}) => Row(
      spacing: Gap.sm,
      children: [
        for (final unit in ['kg', 'reps', 'RIR'])
          Expanded(
            child: StepperField(
              value: 102.5,
              unit: unit,
              step: 2.5,
              compact: compact,
              errorText: 'Enter a number',
              onChanged: (_) {},
            ),
          ),
      ],
    );

    for (final scale in scales) {
      testWidgets('lays out at ${scale}x', (tester) async {
        await pump(
          tester,
          scale,
          Column(children: [fields(), fields(compact: true)]),
        );
      });
    }

    testWidgets('keeps its heights at normal text', (tester) async {
      await pump(
        tester,
        1,
        Column(
          children: [
            StepperField(value: 60, unit: 'kg', step: 2.5, onChanged: (_) {}),
            StepperField(
              value: 8,
              unit: 'reps',
              step: 1,
              compact: true,
              onChanged: (_) {},
            ),
          ],
        ),
      );

      expect(height(tester, find.byType(StepperField).at(0)), 50);
      expect(height(tester, find.byType(StepperField).at(1)), 40);
    });
  });

  group('WeekStrip', () {
    Widget strip() => WeekStrip(
      title: 'This week',
      days: [
        for (var i = 0; i < 7; i++)
          WeekStripDay(
            weekday: 'MTWTFSS'[i],
            number: '${24 + i}',
            state: DayState.values[i],
            semanticLabel: 'Day ${24 + i}',
          ),
      ],
      onDayTap: (_) {},
    );

    for (final scale in scales) {
      testWidgets('lays out at ${scale}x', (tester) async {
        await pump(tester, scale, strip());

        // Each date stays within its circle.
        for (final circle in tester.widgetList<DayCircle>(
          find.byType(DayCircle),
        )) {
          final circleRect = tester.getRect(find.byWidget(circle));
          final numberRect = tester.getRect(find.text(circle.number!));
          expect(circleRect.width, closeTo(DayCircle.daySize, 0.01));
          expect(circleRect.contains(numberRect.topLeft), isTrue);
          expect(circleRect.contains(numberRect.bottomRight), isTrue);
        }
      });
    }
  });

  group('SectionCard', () {
    Widget card() => SectionCard(
      title: 'Week',
      detail: '3 of 4 days',
      onTap: () {},
      child: const Text('Body'),
    );

    for (final scale in scales) {
      testWidgets('lays out at ${scale}x', (tester) async {
        await pump(
          tester,
          scale,
          Column(
            children: [
              card(),
              SectionCard.plain(
                title: 'Week',
                note: 'Tap a day to see it',
                actionLabel: 'Edit',
                onAction: () {},
              ),
              SectionCard.locked(
                title: 'Week',
                tag: const ForgeTag('Premium'),
                message: 'Item text',
                onTap: () {},
              ),
            ],
          ),
        );

        // The title never breaks inside its word (the test font draws
        // every letter 1em wide).
        for (final title in tester.widgetList(find.text('Week'))) {
          final size = tester.getSize(find.byWidget(title));
          final line = TextScaler.linear(scale).scale(20);
          expect(size.height, closeTo(line, 0.5));
        }
      });
    }

    testWidgets('keeps its trailing parts beside the title at normal text', (
      tester,
    ) async {
      await pump(tester, 1, card());

      expect(
        tester.getCenter(find.text('3 of 4 days')).dy,
        tester.getCenter(find.text('Week')).dy,
      );
    });

    testWidgets('puts its trailing parts under the title at large text', (
      tester,
    ) async {
      await pump(tester, 3, card());

      expect(
        tester.getRect(find.text('3 of 4 days')).top,
        greaterThan(tester.getRect(find.text('Week')).bottom),
      );
    });
  });
}
