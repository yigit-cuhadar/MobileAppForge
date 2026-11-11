import 'dart:isolate';
import 'dart:typed_data';

import 'package:vector_math/vector_math.dart';

import 'gltf/glb_parser.dart';

/// A static 3D model made of named parts, ready to be shown by `ModelViewer`.
///
/// Geometry is flattened into model space at load time: one shared vertex
/// buffer with every vertex tagged by the part it belongs to.
class Model3D {
  Model3D({
    required this.partNames,
    required this.positions,
    required this.normals,
    required this.vertexParts,
    required this.indices,
    required this.bounds,
  });

  /// Parses a binary glTF 2.0 (`.glb`) file. Large files are parsed on a
  /// background isolate.
  ///
  /// Throws a [FormatException] when the file is malformed or uses features
  /// this package does not support.
  static Future<Model3D> fromGlb(Uint8List bytes) async {
    if (bytes.lengthInBytes < _isolateThreshold) return parseGlb(bytes);
    return Isolate.run(() => parseGlb(bytes));
  }

  static const _isolateThreshold = 256 * 1024;

  /// The names of the parts, one per named mesh node. Nodes sharing a name
  /// form one part.
  final List<String> partNames;

  /// Axis-aligned bounds of the whole model in model space.
  final Aabb3 bounds;

  // x, y, z per vertex.
  final Float32List positions;
  // Unit normal per vertex.
  final Float32List normals;
  // Index into [partNames] per vertex.
  final Uint16List vertexParts;
  // Three vertex indices per triangle, counter-clockwise when front-facing.
  final Uint16List indices;

  int get vertexCount => vertexParts.length;
  int get triangleCount => indices.length ~/ 3;
}
