import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';

void main() {
  Future<void> pump(WidgetTester tester, {double scale = 1}) =>
      tester.pumpWidget(
        MaterialApp(
          theme: ForgeTheme.light(),
          builder: (context, page) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: page!,
          ),
          home: const Scaffold(
            body: SizedBox(
              width: 390,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [SectionLabel('Section title')],
              ),
            ),
          ),
        ),
      );

  testWidgets('13px semibold ink-muted, 8px above and below', (tester) async {
    await pump(tester);

    final label = find.text('Section title');
    final style = tester.widget<Text>(label).style!;
    final colors = ForgeStyle.of(tester.element(label)).colors;
    expect(style.fontSize, 13);
    expect(style.fontWeight, FontWeight.w600);
    expect(style.color, colors.inkMuted);
    final box = tester.getRect(find.byType(SectionLabel));
    final text = tester.getRect(label);
    expect(text.top - box.top, 8);
    expect(box.bottom - text.bottom, 8);
    expect(text.left - box.left, 4);
    expect(box.height, 18 + 16);
  });

  testWidgets('reads as a heading', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);
    expect(
      tester.getSemantics(find.text('Section title')),
      matchesSemantics(label: 'Section title', isHeader: true),
    );
    semantics.dispose();
  });

  for (final scale in [2.0, 3.0]) {
    testWidgets('wraps at ${scale}x text without overflow', (tester) async {
      await pump(tester, scale: scale);
      expect(tester.takeException(), isNull);
    });
  }
}
