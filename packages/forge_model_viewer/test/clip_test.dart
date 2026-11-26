import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:forge_model_viewer/src/clip.dart';

import 'glb_builder.dart';

Matcher _closeList(List<double> expected) => pairwiseCompare<double, double>(
  expected,
  (a, b) => (a - b).abs() < 1e-5,
  'close to',
);

void main() {
  // Two joints, four frames at 4 fps: joint 0 moves x by 0, 1, 2, 3; joint 1
  // stays put.
  final clip = ModelClip.parse(
    clipBytes(
      jointCount: 2,
      framesPerSecond: 4,
      bounds: [-1, -2, -3, 1, 2, 3],
      frames: [
        for (var f = 0; f < 4; f++)
          [...translation(f.toDouble(), 0, 0), ...translation(0, 0, 0)],
      ],
    ),
  );
  final out = Float32List(24);

  test('reads the header', () {
    expect(clip.jointCount, 2);
    expect(clip.duration, const Duration(seconds: 1));
    expect(clip.bounds, [-1, -2, -3, 1, 2, 3]);
  });

  test('samples a frame', () {
    clip.sample(const Duration(milliseconds: 500), out);
    expect(out, _closeList([...translation(2, 0, 0), ...translation(0, 0, 0)]));
  });

  test('blends neighbouring frames', () {
    clip.sample(const Duration(milliseconds: 375), out);
    expect(out.sublist(0, 12), _closeList(translation(1.5, 0, 0)));
  });

  test('loops, blending the last frame into the first', () {
    clip.sample(const Duration(milliseconds: 875), out);
    expect(out.sublist(0, 12), _closeList(translation(1.5, 0, 0)));
    clip.sample(const Duration(milliseconds: 2250), out);
    expect(out.sublist(0, 12), _closeList(translation(1, 0, 0)));
  });

  group('parse rejects', () {
    Matcher fails(String message) => throwsA(
      isA<FormatException>().having(
        (e) => e.message,
        'message',
        contains(message),
      ),
    );
    Uint8List valid() => clipBytes(
      jointCount: 1,
      framesPerSecond: 30,
      bounds: [0, 0, 0, 1, 1, 1],
      frames: [translation(0, 0, 0)],
    );

    test('a wrong magic', () {
      final bytes = valid()..[0] = 0;
      expect(() => ModelClip.parse(bytes), fails('Not a clip'));
      expect(() => ModelClip.parse(Uint8List(8)), fails('Not a clip'));
    });

    test('a length that does not match the header', () {
      final bytes = valid();
      expect(
        () =>
            ModelClip.parse(Uint8List.sublistView(bytes, 0, bytes.length - 4)),
        fails('length'),
      );
      expect(
        () => ModelClip.parse(Uint8List.fromList([...bytes, 0, 0, 0, 0])),
        fails('length'),
      );
    });

    test('no frames or no frame rate', () {
      expect(
        () => ModelClip.parse(
          clipBytes(
            jointCount: 1,
            framesPerSecond: 30,
            bounds: [0, 0, 0, 1, 1, 1],
            frames: [],
          ),
        ),
        fails('no frames'),
      );
      expect(
        () => ModelClip.parse(
          clipBytes(
            jointCount: 1,
            framesPerSecond: 0,
            bounds: [0, 0, 0, 1, 1, 1],
            frames: [translation(0, 0, 0)],
          ),
        ),
        fails('no frame rate'),
      );
    });
  });
}
