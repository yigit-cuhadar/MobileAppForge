import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_model_viewer/forge_model_viewer.dart';

import 'glb_builder.dart';

void main() {
  late Model3D model;
  // In a 200 x 200 view the quads fill about x 15..185, y 58..142.
  const left = Offset(60, 100), right = Offset(140, 100);
  const miss = Offset(100, 20);

  setUpAll(() async {
    model = await Model3D.fromGlb(
      quadsGlb({
        'left': quad(-1, -0.5, 0, 0.5, 0),
        'right': quad(0, -0.5, 1, 0.5, 0),
      }),
    );
  });

  Future<void> pumpViewer(WidgetTester tester, ModelViewer viewer) =>
      tester.pumpWidget(
        MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 200, height: 200, child: viewer),
          ),
        ),
      );

  testWidgets('reports tapped parts', (tester) async {
    final taps = <String>[];
    await pumpViewer(tester, ModelViewer(model: model, onPartTap: taps.add));
    for (final point in [left, right, miss]) {
      await tester.tapAt(point);
      await tester.pump(kDoubleTapTimeout);
    }
    expect(taps, ['left', 'right']);
  });

  testWidgets('scrubs across parts after a long press', (tester) async {
    final scrubs = <String?>[];
    final ends = <String?>[];
    await pumpViewer(
      tester,
      ModelViewer(
        model: model,
        selectable: (part) => part != 'right',
        onScrub: scrubs.add,
        onScrubEnd: ends.add,
      ),
    );
    final gesture = await tester.startGesture(left);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveTo(left + const Offset(5, 0));
    await gesture.moveTo(right);
    await gesture.moveTo(left);
    await gesture.up();
    await tester.pump();
    expect(scrubs, ['left', null, 'left']);
    expect(ends, ['left']);
  });

  testWidgets('drag rotates and double tap resets', (tester) async {
    final controller = ModelViewerController();
    await pumpViewer(tester, ModelViewer(model: model, controller: controller));
    await tester.dragFrom(left, const Offset(100, 0));
    await tester.pump();
    expect(controller.yaw, greaterThan(0));
    await tester.tapAt(left);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(left);
    await tester.pumpAndSettle();
    expect(controller.yaw, 0);
    controller.dispose();
  });

  testWidgets('takes no gestures when not interactive', (tester) async {
    final taps = <String>[];
    await pumpViewer(
      tester,
      ModelViewer(
        model: model,
        interactive: false,
        onPartTap: taps.add,
        semanticLabel: 'Model',
      ),
    );
    expect(
      find.descendant(
        of: find.byType(ModelViewer),
        matching: find.byType(GestureDetector),
      ),
      findsNothing,
    );
    await tester.tapAt(left);
    await tester.pump(kDoubleTapTimeout);
    expect(taps, isEmpty);
    expect(find.bySemanticsLabel('Model'), findsOneWidget);
  });
}
