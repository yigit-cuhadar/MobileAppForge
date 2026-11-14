import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';

void main() {
  Future<void> pump(WidgetTester tester, ForgeTag tag) => tester.pumpWidget(
    MaterialApp(
      theme: ForgeTheme.light(),
      home: Scaffold(body: Center(child: tag)),
    ),
  );

  testWidgets('is 22px tall with its label', (tester) async {
    await pump(tester, const ForgeTag('Custom'));

    expect(tester.getSize(find.byType(ForgeTag)).height, ForgeTag.height);
    expect(find.text('Custom'), findsOneWidget);
  });

  testWidgets('only the premium tag carries a lock', (tester) async {
    final lock = find.byWidgetPredicate(
      (w) => w is ForgeIcon && w.icon == ForgeIcons.lock,
    );
    for (final kind in ForgeTagKind.values) {
      await pump(tester, ForgeTag('Label', kind: kind));

      expect(
        lock,
        kind == ForgeTagKind.premium ? findsOneWidget : findsNothing,
      );
    }
  });

  testWidgets('a long label ends in an ellipsis in a tight row', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ForgeTheme.light(),
        home: const Scaffold(
          body: Center(
            child: SizedBox(
              width: 80,
              child: Row(
                children: [
                  Flexible(child: ForgeTag('A label far too long to fit')),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(ForgeTag)).width, 80);
  });

  testWidgets('an icon sits before the label', (tester) async {
    await pump(
      tester,
      const ForgeTag(
        'record',
        kind: ForgeTagKind.record,
        icon: ForgeIcons.emojiEvents,
      ),
    );

    final icon = find.byWidgetPredicate(
      (w) => w is ForgeIcon && w.icon == ForgeIcons.emojiEvents,
    );
    expect(
      tester.getCenter(icon).dx,
      lessThan(tester.getCenter(find.text('record')).dx),
    );
  });

  testWidgets('the plain tag has no fill and an ink-muted label', (
    tester,
  ) async {
    await pump(tester, const ForgeTag('Label', kind: ForgeTagKind.plain));

    final box = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(ForgeTag),
            matching: find.byType(Container),
          )
          .first,
    );
    expect((box.decoration! as BoxDecoration).color, isNull);
    expect(
      tester.widget<Text>(find.text('Label')).style!.color,
      ForgeTheme.light().extension<ForgeStyle>()!.colors.inkMuted,
    );
  });
}
