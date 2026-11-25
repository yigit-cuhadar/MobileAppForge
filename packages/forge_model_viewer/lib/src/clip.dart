import 'dart:typed_data';

const _magic = 0x43564D46; // "FMVC"
const _headerLength = 40;

/// A looping animation of a skinned `Model3D`: per frame, one affine matrix
/// per joint in model space.
class ModelClip {
  ModelClip._(
    this.jointCount,
    this._frameCount,
    this.duration,
    this._bounds,
    this._frames,
  );

  /// Parses a clip file, little-endian:
  ///
  /// - uint32 magic, the bytes "FMVC"
  /// - uint32 joint count, uint32 frame count, float32 frames per second
  /// - float32 × 6 bounds (min x, y, z, max x, y, z) of everything the clip
  ///   moves, over all frames
  /// - float32 × 12 per joint per frame: a 3x4 affine matrix, row-major
  ///
  /// Throws a [FormatException] when the file is malformed.
  static ModelClip parse(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    if (bytes.length < _headerLength ||
        data.getUint32(0, Endian.little) != _magic) {
      throw const FormatException('Not a clip file');
    }
    final jointCount = data.getUint32(4, Endian.little);
    final frameCount = data.getUint32(8, Endian.little);
    final framesPerSecond = data.getFloat32(12, Endian.little);
    final valueCount = frameCount * jointCount * 12;
    if (bytes.length != _headerLength + valueCount * 4) {
      throw const FormatException('Clip length does not match its header');
    }
    if (frameCount == 0 ||
        !(framesPerSecond > 0) ||
        framesPerSecond.isInfinite) {
      throw const FormatException('Clip has no frames or no frame rate');
    }
    final microseconds = (frameCount * 1e6 / framesPerSecond).round();
    if (microseconds == 0) {
      throw const FormatException('Clip is shorter than a microsecond');
    }
    final bounds = Float64List(6);
    for (var i = 0; i < 6; i++) {
      bounds[i] = data.getFloat32(16 + i * 4, Endian.little);
    }
    final frames = Float32List(valueCount);
    for (var i = 0; i < valueCount; i++) {
      frames[i] = data.getFloat32(_headerLength + i * 4, Endian.little);
    }
    return ModelClip._(
      jointCount,
      frameCount,
      Duration(microseconds: microseconds),
      bounds,
      frames,
    );
  }

  final int jointCount;
  final int _frameCount;

  /// One loop.
  final Duration duration;

  final Float64List _bounds;
  final Float32List _frames;

  /// Writes the `jointCount * 12` matrix values at [time] into [out],
  /// blending the neighbouring frames. The clip loops: the last frame blends
  /// into the first.
  void sample(Duration time, Float32List out) {
    final length = jointCount * 12;
    assert(out.length >= length);
    final period = duration.inMicroseconds;
    final position = time.inMicroseconds % period * _frameCount / period;
    final frame = position.floor();
    final t = position - frame;
    final a = frame % _frameCount * length;
    final b = (frame + 1) % _frameCount * length;
    final frames = _frames;
    for (var i = 0; i < length; i++) {
      final from = frames[a + i];
      out[i] = from + (frames[b + i] - from) * t;
    }
  }
}

/// minX, minY, minZ, maxX, maxY, maxZ of everything [clip] moves.
Float64List boundsOf(ModelClip clip) => clip._bounds;
