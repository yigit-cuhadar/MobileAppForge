import 'package:flutter/semantics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_model_viewer/forge_model_viewer.dart';

import 'glb_builder.dart';

void main() {
  late Model3D model;
  // In a 200 x 200 view the quads fill about x 15..185, y 58..142.
  const left = Offset(60, 100), right = Offset(140, 100);
  const miss = Offset(100, 20);
  const holdLong = Duration(milliseconds: 600);

  setUpAll(() async {
    model = await Model3D.fromGlb(
      quadsGlb({
        'left': quad(-1, -0.5, 0, 0.5, 0),
        'right': quad(0, -0.5, 1, 0.5, 0),
      }),
    );
  });

  Widget inApp(Widget child) => MaterialApp(
    home: Align(alignment: Alignment.topLeft, child: child),
  );

  Future<void> pumpViewer(WidgetTester tester, ModelViewer viewer) => tester
      .pumpWidget(inApp(SizedBox(width: 200, height: 200, child: viewer)));

  testWidgets('reports a tap at once on release', (tester) async {
    final taps = <String>[];
    await pumpViewer(tester, ModelViewer(model: model, onPartTap: taps.add));
    for (final point in [left, right, miss]) {
      final gesture = await tester.startGesture(point);
      await gesture.up();
    }
    expect(taps, ['left', 'right']);
  });

  testWidgets('no tap after a drag or a scrub', (tester) async {
    final taps = <String>[];
    await pumpViewer(
      tester,
      ModelViewer(model: model, onPartTap: taps.add, onScrub: (_) {}),
    );
    await tester.dragFrom(left, const Offset(60, 0));
    final gesture = await tester.startGesture(left);
    await tester.pump(holdLong);
    await gesture.up();
    expect(taps, isEmpty);
  });

  testWidgets('scrubs across parts without rotating', (tester) async {
    final controller = ModelViewerController();
    final scrubs = <String?>[];
    final ends = <String?>[];
    await pumpViewer(
      tester,
      ModelViewer(
        model: model,
        controller: controller,
        selectable: (part) => part != 'right',
        onScrub: scrubs.add,
        onScrubEnd: ends.add,
      ),
    );
    final gesture = await tester.startGesture(left);
    await tester.pump(holdLong);
    await gesture.moveTo(left + const Offset(5, 0));
    await gesture.moveTo(right);
    await gesture.moveTo(left);
    await gesture.up();
    expect(scrubs, ['left', null, 'left']);
    expect(ends, ['left']);
    expect(controller.yaw, 0);
    controller.dispose();
  });

  group('an interrupted scrub ends exactly once, reporting no part, when', () {
    late List<String?> ends;
    setUp(() => ends = []);

    ModelViewer viewer({bool interactive = true, bool scrubs = true}) =>
        ModelViewer(
          model: model,
          interactive: interactive,
          onScrub: scrubs ? (_) {} : null,
          onScrubEnd: scrubs ? ends.add : null,
        );

    testWidgets('the pointer is cancelled', (tester) async {
      await pumpViewer(tester, viewer());
      final gesture = await tester.startGesture(left);
      await tester.pump(holdLong);
      await gesture.cancel();
      await tester.pump();
      expect(ends, [null]);
    });

    testWidgets('the viewer turns non-interactive', (tester) async {
      await pumpViewer(tester, viewer());
      final gesture = await tester.startGesture(left);
      await tester.pump(holdLong);
      await pumpViewer(tester, viewer(interactive: false));
      await gesture.up();
      await tester.pump();
      expect(ends, [null]);
    });

    testWidgets('the scrub callbacks are removed', (tester) async {
      await pumpViewer(tester, viewer());
      final gesture = await tester.startGesture(left);
      await tester.pump(holdLong);
      await pumpViewer(tester, viewer(scrubs: false));
      await gesture.moveTo(right);
      await gesture.up();
      await tester.pump();
      expect(ends, [null]);
    });

    testWidgets('the viewer is disposed', (tester) async {
      await pumpViewer(tester, viewer());
      final gesture = await tester.startGesture(left);
      await tester.pump(holdLong);
      await tester.pumpWidget(const SizedBox());
      await gesture.up();
      await tester.pump();
      expect(ends, [null]);
    });
  });

  testWidgets('a pinch zooms', (tester) async {
    final controller = ModelViewerController();
    await pumpViewer(tester, ModelViewer(model: model, controller: controller));
    final a = await tester.startGesture(const Offset(80, 100));
    final b = await tester.startGesture(const Offset(120, 100));
    await a.moveTo(const Offset(60, 100));
    await b.moveTo(const Offset(140, 100));
    await a.up();
    await b.up();
    expect(controller.zoom, closeTo(2, 1e-9));
    expect(controller.yaw, 0);
    controller.dispose();
  });

  group('drags rotate the model inside', () {
    testWidgets('a horizontal PageView', (tester) async {
      final controller = ModelViewerController();
      final pages = PageController();
      await tester.pumpWidget(
        inApp(
          SizedBox(
            width: 200,
            height: 200,
            child: PageView(
              controller: pages,
              children: [
                ModelViewer(model: model, controller: controller),
                const SizedBox(),
              ],
            ),
          ),
        ),
      );
      await tester.dragFrom(left, const Offset(-120, 0));
      await tester.pumpAndSettle();
      expect(controller.yaw, lessThan(0));
      expect(pages.page, 0);
      controller.dispose();
      pages.dispose();
    });

    testWidgets('a vertical ListView', (tester) async {
      final controller = ModelViewerController();
      final scroll = ScrollController();
      await tester.pumpWidget(
        inApp(
          SizedBox(
            width: 200,
            height: 200,
            child: ListView(
              controller: scroll,
              children: [
                SizedBox(
                  height: 200,
                  child: ModelViewer(model: model, controller: controller),
                ),
                const SizedBox(height: 400),
              ],
            ),
          ),
        ),
      );
      await tester.dragFrom(left, const Offset(0, -100));
      await tester.pumpAndSettle();
      expect(controller.pitch, lessThan(0));
      expect(scroll.offset, 0);
      controller.dispose();
      scroll.dispose();
    });
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
        matching: find.byType(RawGestureDetector),
      ),
      findsNothing,
    );
    await tester.tapAt(left);
    expect(taps, isEmpty);
    expect(find.bySemanticsLabel('Model'), findsOneWidget);
  });

  testWidgets('exposes the label but no gesture actions', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpViewer(
      tester,
      ModelViewer(
        model: model,
        onPartTap: (_) {},
        onScrub: (_) {},
        semanticLabel: 'Model',
      ),
    );
    final node = tester.getSemantics(find.bySemanticsLabel('Model'));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
    expect(
      node.getSemanticsData().hasAction(SemanticsAction.longPress),
      isFalse,
    );
    handle.dispose();
  });
}
