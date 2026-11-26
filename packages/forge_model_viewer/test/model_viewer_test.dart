import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_model_viewer/forge_model_viewer.dart';
import 'package:forge_model_viewer/src/render/model_painter.dart';

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

  testWidgets('rings an outlined part, over its neighbour too', (tester) async {
    const ring = Color(0xFFFF0000);
    await pumpViewer(
      tester,
      ModelViewer(
        model: model,
        baseColor: const Color(0xFF00FF00),
        outlinedParts: const {'left'},
        outlineColor: ring,
        outlineWidth: 4,
      ),
    );
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.descendant(
        of: find.byType(ModelViewer),
        matching: find.byType(RepaintBoundary),
      ),
    );
    final pixels = (await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData();
      image.dispose();
      return bytes;
    }))!;
    // RGBA at x on the row through the middle of both quads.
    int at(int x) => pixels.getUint32((100 * 200 + x) * 4);
    const red = 0xFF0000FF;
    // The left quad spans x 15..99, the right one 100..184.
    expect([at(11), at(14), at(100), at(103)], everyElement(red));
    expect(at(60), isNot(anyOf(red, 0)));
    expect(at(104), isNot(anyOf(red, 0)));
    expect([at(10), at(186)], everyElement(0));
  });

  group('auto turn', () {
    // One second in frames, as the ticker skips long gaps.
    Future<void> second(WidgetTester tester) async {
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 1000 ~/ 60));
      }
    }

    final perSecond = 2 * math.pi / ModelViewer.turnPeriod.inSeconds;

    Future<ModelViewerController> pumpTurning(
      WidgetTester tester, {
      bool autoTurn = true,
      bool interactive = true,
      bool disableAnimations = false,
      bool ticking = true,
      ModelViewerController? controller,
    }) async {
      if (controller == null) {
        controller = ModelViewerController();
        addTearDown(controller.dispose);
      }
      await tester.pumpWidget(
        inApp(
          MediaQuery(
            data: MediaQueryData(disableAnimations: disableAnimations),
            child: TickerMode(
              enabled: ticking,
              child: SizedBox(
                width: 200,
                height: 200,
                child: ModelViewer(
                  model: model,
                  controller: controller,
                  autoTurn: autoTurn,
                  interactive: interactive,
                ),
              ),
            ),
          ),
        ),
      );
      return controller;
    }

    testWidgets('is off by default', (tester) async {
      final controller = await pumpTurning(tester, autoTurn: false);
      await second(tester);
      expect(controller.yaw, 0);
    });

    testWidgets('turns the yaw slowly, also when not interactive', (
      tester,
    ) async {
      for (final interactive in [true, false]) {
        final controller = await pumpTurning(tester, interactive: interactive);
        await second(tester);
        expect(controller.yaw, closeTo(perSecond, perSecond * 0.05));
        expect(controller.pitch, 0);
      }
    });

    testWidgets('holds while a finger is on it, then goes on', (tester) async {
      final controller = await pumpTurning(tester);
      final gesture = await tester.startGesture(miss);
      await second(tester);
      expect(controller.yaw, 0);

      await gesture.up();
      await second(tester);
      expect(controller.yaw, closeTo(perSecond, perSecond * 0.05));
    });

    testWidgets('holds while its tickers are muted, without a jump after', (
      tester,
    ) async {
      final controller = await pumpTurning(tester, ticking: false);
      await second(tester);
      expect(controller.yaw, 0);

      await pumpTurning(tester, controller: controller);
      await tester.pump(const Duration(seconds: 5));
      await second(tester);
      expect(controller.yaw, closeTo(perSecond, perSecond * 0.05));
    });

    testWidgets('holds when the platform asks for less motion', (tester) async {
      var controller = await pumpTurning(tester, disableAnimations: true);
      await second(tester);
      expect(controller.yaw, 0);

      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(reduceMotion: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(const SizedBox());
      controller = await pumpTurning(tester);
      await second(tester);
      expect(controller.yaw, 0);
    });
  });

  group('clip', () {
    late Model3D skinned;
    late ModelClip clip;

    setUpAll(() async {
      skinned = await Model3D.fromGlb(
        skinnedQuadsGlb(
          {
            'left': quad(-1, -0.5, 0, 0.5, 0),
            'right': quad(0, -0.5, 1, 0.5, 0),
          },
          [0, 1],
        ),
      );
      // Over one second the right quad rises by 1 and drops back.
      clip = ModelClip.parse(
        clipBytes(
          jointCount: 2,
          framesPerSecond: 2,
          bounds: [-1, -0.5, 0, 1, 1.5, 0],
          frames: [
            [...translation(0, 0, 0), ...translation(0, 0, 0)],
            [...translation(0, 0, 0), ...translation(0, 1, 0)],
          ],
        ),
      );
    });

    Future<void> pumpPlaying(
      WidgetTester tester, {
      bool disableAnimations = false,
    }) => tester.pumpWidget(
      inApp(
        MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: SizedBox(
            width: 200,
            height: 200,
            child: ModelViewer(model: skinned, motion: clip),
          ),
        ),
      ),
    );

    // Screen y of the right quad's first vertex, as last painted.
    double rightY(WidgetTester tester) {
      final paint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(ModelViewer),
          matching: find.byType(CustomPaint),
        ),
      );
      return (paint.painter! as ModelPainter).renderer.screen[9];
    }

    Future<void> play(WidgetTester tester, Duration duration) async {
      const frame = Duration(milliseconds: 1000 ~/ 60);
      for (var t = Duration.zero; t < duration; t += frame) {
        await tester.pump(frame);
      }
    }

    testWidgets('plays in a loop', (tester) async {
      await pumpPlaying(tester);
      final rest = rightY(tester);
      await play(tester, const Duration(milliseconds: 500));
      final raised = rightY(tester);
      expect(raised, lessThan(rest - 20));
      await play(tester, const Duration(milliseconds: 500));
      expect(rightY(tester), closeTo(rest, 5));
      expect(rightY(tester), isNot(raised));
    });

    testWidgets('holds the first frame when asked for less motion', (
      tester,
    ) async {
      await pumpPlaying(tester, disableAnimations: true);
      final rest = rightY(tester);
      await play(tester, const Duration(milliseconds: 500));
      expect(rightY(tester), rest);
    });
  });

  group('motion', () {
    late Model3D skinned;
    final error = ThemeData().colorScheme.error;
    const frame = Duration(milliseconds: 1000 ~/ 60);

    setUpAll(() async {
      skinned = await Model3D.fromGlb(
        skinnedQuadsGlb(
          {
            'left': quad(-1, -0.5, 0, 0.5, 0),
            'right': quad(0, -0.5, 1, 0.5, 0),
          },
          [0, 1],
        ),
      );
    });

    Future<void> pumpMotion(
      WidgetTester tester,
      ModelMotion motion, {
      bool playing = true,
      bool disableAnimations = false,
      ModelViewerController? controller,
    }) => tester.pumpWidget(
      inApp(
        MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: SizedBox(
            width: 200,
            height: 200,
            child: ModelViewer(
              model: skinned,
              motion: motion,
              playing: playing,
              controller: controller,
            ),
          ),
        ),
      ),
    );

    Finder painted() => find.descendant(
      of: find.byType(ModelViewer),
      matching: find.byType(CustomPaint),
    );

    // Screen x, y of the right quad's first vertex, as last painted.
    Offset rightCorner(WidgetTester tester) {
      final screen =
          (tester.widget<CustomPaint>(painted()).painter! as ModelPainter)
              .renderer
              .screen;
      return Offset(screen[8], screen[9]);
    }

    // The circles drawn in one paint of the viewer.
    List<(Offset, double, Paint)> circles() {
      final drawn = <(Offset, double, Paint)>[];
      expect(
        painted(),
        paints..everything((method, arguments) {
          if (method == #drawCircle) {
            drawn.add((
              arguments[0] as Offset,
              arguments[1] as double,
              arguments[2] as Paint,
            ));
          }
          return true;
        }),
      );
      return drawn;
    }

    Future<void> play(WidgetTester tester, Duration duration) async {
      for (var t = Duration.zero; t < duration; t += frame) {
        await tester.pump(frame);
      }
    }

    testWidgets('repaints as it plays', (tester) async {
      final motion = _Lift();
      await pumpMotion(tester, motion);
      final rest = rightCorner(tester);
      await play(tester, const Duration(milliseconds: 250));
      expect(rightCorner(tester).dy, lessThan(rest.dy - 20));
      expect(rightCorner(tester).dx, closeTo(rest.dx, 1e-3));
    });

    testWidgets('holds the first frame when asked for less motion', (
      tester,
    ) async {
      final motion = _Lift();
      await pumpMotion(tester, motion, disableAnimations: true);
      final rest = rightCorner(tester);
      await play(tester, const Duration(milliseconds: 250));
      expect(rightCorner(tester), rest);
      expect(motion.samples, 1);
    });

    testWidgets('holds its frame while not playing, then goes on', (
      tester,
    ) async {
      final motion = _Lift();
      final controller = ModelViewerController();
      addTearDown(controller.dispose);
      await pumpMotion(tester, motion, controller: controller);
      final rest = rightCorner(tester);
      await play(tester, const Duration(milliseconds: 250));
      final held = rightCorner(tester);

      await pumpMotion(tester, motion, playing: false, controller: controller);
      final samples = motion.samples;
      await play(tester, const Duration(milliseconds: 500));
      expect(rightCorner(tester), held);
      // Turning the camera repaints without skinning again.
      controller.pitch = 0.5;
      await tester.pump();
      expect(rightCorner(tester), isNot(held));
      controller.pitch = 0;
      await tester.pump();
      expect(motion.samples, samples);

      await pumpMotion(tester, motion, controller: controller);
      await play(tester, frame * 2);
      expect(rightCorner(tester).dy, closeTo(held.dy, 5));
      expect(rightCorner(tester).dy, lessThan(rest.dy - 20));
      await play(tester, const Duration(milliseconds: 150));
      expect(rightCorner(tester).dy, lessThan(held.dy - 5));
    });

    testWidgets('rings its markers where they are on the model', (
      tester,
    ) async {
      await pumpMotion(tester, _Lift(markerCount: 2));
      for (final _ in [0, 1]) {
        final corner = rightCorner(tester);
        final drawn = circles();
        expect(drawn, hasLength(2));
        for (final (centre, radius, paint) in drawn) {
          expect(centre.dx, closeTo(corner.dx, 1e-3));
          expect(centre.dy, closeTo(corner.dy, 1e-3));
          expect(radius, 14);
          expect(paint.style, PaintingStyle.stroke);
          expect(paint.strokeWidth, 2);
          expect(paint.color.toARGB32(), error.toARGB32());
        }
        await play(tester, const Duration(milliseconds: 250));
      }
    });

    testWidgets('rings markers on the held first frame', (tester) async {
      await pumpMotion(tester, _Lift(), disableAnimations: true);
      final corner = rightCorner(tester);
      await play(tester, const Duration(milliseconds: 250));
      final (centre, _, _) = circles().single;
      expect(centre.dx, closeTo(corner.dx, 1e-3));
      expect(centre.dy, closeTo(corner.dy, 1e-3));
    });

    testWidgets('draws no circle without markers', (tester) async {
      await pumpMotion(tester, _Lift(markerCount: 0));
      await play(tester, const Duration(milliseconds: 100));
      expect(circles(), isEmpty);
    });
  });
}

/// Over one second the right quad rises by 1 and drops back; every marker
/// sits on its first vertex.
class _Lift implements ModelMotion {
  _Lift({this.markerCount = 1});

  @override
  final int markerCount;

  int samples = 0;

  @override
  int get jointCount => 2;

  @override
  Duration get duration => const Duration(seconds: 1);

  @override
  final bounds = Float64List.fromList([-1, -0.5, 0, 1, 1.5, 0]);

  double _lift(Duration time) {
    final t = time.inMicroseconds % 1000000 / 1000000;
    return t < 0.5 ? 2 * t : 2 - 2 * t;
  }

  @override
  void sample(Duration time, Float32List out) {
    samples++;
    out.setAll(0, [...translation(0, 0, 0), ...translation(0, _lift(time), 0)]);
  }

  @override
  void sampleMarkers(Duration time, Float32List out) {
    for (var i = 0; i < markerCount; i++) {
      out.setAll(i * 3, [0, -0.5 + _lift(time), 0]);
    }
  }
}
