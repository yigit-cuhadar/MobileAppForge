import 'dart:typed_data';

/// What a `ModelViewer` plays on a skinned `Model3D`: per moment, one affine
/// matrix per joint, and points to mark on the model. Its counts, length and
/// bounds stay fixed.
abstract interface class ModelMotion {
  int get jointCount;

  /// One loop.
  Duration get duration;

  /// minX, minY, minZ, maxX, maxY, maxZ of everything it moves, over its
  /// whole length.
  Float64List get bounds;

  /// Writes 12 values per joint at [time] into [out]: a row-major 3x4
  /// matrix in model space. Loops.
  void sample(Duration time, Float32List out);

  /// How many points to mark on the model.
  int get markerCount;

  /// Writes x, y, z in model space per marker at [time] into [out].
  void sampleMarkers(Duration time, Float32List out);
}
