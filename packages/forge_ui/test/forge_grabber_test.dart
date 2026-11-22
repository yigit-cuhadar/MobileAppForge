import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';

void main() {
  testWidgets('a 36 × 4 rounded bar in the strong line colour, centred', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ForgeTheme.light(),
        home: const Scaffold(body: SizedBox(width: 390, child: ForgeGrabber())),
      ),
    );

    final bar = find.descendant(
      of: find.byType(ForgeGrabber),
      matching: find.byType(Container),
    );
    expect(tester.getSize(bar), const Size(36, 4));
    expect(tester.getCenter(bar).dx, 195);
    final decoration =
        tester.widget<Container>(bar).decoration! as BoxDecoration;
    final colors = ForgeStyle.of(tester.element(bar)).colors;
    expect(decoration.color, colors.lineStrong.withValues(alpha: 0.6));
    expect(decoration.borderRadius, BorderRadius.circular(2));
  });

  testWidgets('tops a bottom sheet', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ForgeTheme.light(),
        home: const Scaffold(
          body: ForgeBottomSheet(title: 'Sheet title', child: SizedBox()),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byType(ForgeBottomSheet),
        matching: find.byType(ForgeGrabber),
      ),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.byType(ForgeGrabber)).dy,
      lessThan(tester.getTopLeft(find.text('Sheet title')).dy),
    );
  });
}
