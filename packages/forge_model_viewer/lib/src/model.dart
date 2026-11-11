import 'dart:isolate';
import 'dart:typed_data';

import 'gltf/glb_parser.dart';

/// A static 3D model made of named parts, ready to be shown by `ModelViewer`.
class Model3D {
  Model3D._(this._mesh);

  /// Parses a binary glTF 2.0 (`.glb`) file. Large files are parsed on a
  /// background isolate.
  ///
  /// Throws a [FormatException] when the file is malformed or uses features
  /// this package does not support.
  static Future<Model3D> fromGlb(Uint8List bytes) async {
    if (bytes.lengthInBytes < isolateThreshold) {
      return Model3D._(parseGlb(bytes));
    }
    return Model3D._(await Isolate.run(() => parseGlb(bytes)));
  }

  final MeshData _mesh;

  /// The names of the parts, one per named mesh node. Nodes sharing a name
  /// form one part.
  List<String> get partNames => _mesh.partNames;
}

/// Files at least this big are parsed on a background isolate.
const isolateThreshold = 256 * 1024;

MeshData meshOf(Model3D model) => model._mesh;

/// Validated geometry flattened into model space: one shared vertex buffer,
/// every vertex tagged with the part it belongs to.
class MeshData {
  MeshData({
    required this.partNames,
    required this.positions,
    required this.normals,
    required this.vertexParts,
    required this.indices,
    required this.bounds,
  });

  final List<String> partNames;
  // x, y, z per vertex.
  final Float32List positions;
  // Unit (or zero) normal per vertex.
  final Float32List normals;
  // Index into [partNames] per vertex.
  final Uint16List vertexParts;
  // Three vertex indices per triangle, counter-clockwise when front-facing.
  final Uint16List indices;
  // minX, minY, minZ, maxX, maxY, maxZ.
  final Float64List bounds;

  int get vertexCount => vertexParts.length;
  int get triangleCount => indices.length ~/ 3;
}
