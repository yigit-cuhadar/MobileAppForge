import 'dart:isolate';
import 'dart:typed_data';

import 'gltf/glb_parser.dart';

/// A 3D model made of named parts, ready to be shown by `ModelViewer`. A
/// skinned model can be posed by a `ModelClip`.
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

  /// One model holding all of [models]; parts with the same name become one
  /// part. Skinned models share their joints.
  ///
  /// Throws an [ArgumentError] when [models] is empty, mixes skinned and
  /// unskinned models, or holds more than 65,536 vertices in all.
  static Model3D joined(List<Model3D> models) {
    if (models.isEmpty) throw ArgumentError.value(models, 'models', 'empty');
    final meshes = [for (final model in models) model._mesh];
    final skinned = meshes.first.joints != null;
    if (meshes.any((mesh) => (mesh.joints != null) != skinned)) {
      throw ArgumentError.value(
        models,
        'models',
        'mixes skinned and unskinned models',
      );
    }
    final vertexCount = meshes.fold(0, (sum, mesh) => sum + mesh.vertexCount);
    if (vertexCount > maxVertices) {
      throw ArgumentError.value(
        models,
        'models',
        'more than $maxVertices vertices',
      );
    }
    final indexCount = meshes.fold(0, (sum, mesh) => sum + mesh.indices.length);
    final partIndex = <String, int>{};
    final positions = Float32List(vertexCount * 3);
    final normals = Float32List(vertexCount * 3);
    final vertexParts = Uint16List(vertexCount);
    final indices = Uint16List(indexCount);
    final joints = skinned ? Uint8List(vertexCount * 4) : null;
    final weights = skinned ? Float32List(vertexCount * 4) : null;
    final bounds = Float64List.fromList([
      ...List.filled(3, double.infinity),
      ...List.filled(3, double.negativeInfinity),
    ]);
    var vertexOffset = 0;
    var indexOffset = 0;
    for (final mesh in meshes) {
      final parts = [
        for (final name in mesh.partNames)
          partIndex.putIfAbsent(name, () => partIndex.length),
      ];
      positions.setAll(vertexOffset * 3, mesh.positions);
      normals.setAll(vertexOffset * 3, mesh.normals);
      joints?.setAll(vertexOffset * 4, mesh.joints!);
      weights?.setAll(vertexOffset * 4, mesh.weights!);
      for (var v = 0; v < mesh.vertexCount; v++) {
        vertexParts[vertexOffset + v] = parts[mesh.vertexParts[v]];
      }
      for (var i = 0; i < mesh.indices.length; i++) {
        indices[indexOffset + i] = mesh.indices[i] + vertexOffset;
      }
      for (var axis = 0; axis < 3; axis++) {
        if (mesh.bounds[axis] < bounds[axis]) bounds[axis] = mesh.bounds[axis];
        if (mesh.bounds[axis + 3] > bounds[axis + 3]) {
          bounds[axis + 3] = mesh.bounds[axis + 3];
        }
      }
      vertexOffset += mesh.vertexCount;
      indexOffset += mesh.indices.length;
    }
    return Model3D._(
      MeshData(
        partNames: List.unmodifiable(partIndex.keys),
        positions: positions,
        normals: normals,
        vertexParts: vertexParts,
        indices: indices,
        bounds: bounds,
        joints: joints,
        weights: weights,
      ),
    );
  }

  final MeshData _mesh;

  /// The names of the parts, one per named mesh node. Nodes sharing a name
  /// form one part.
  List<String> get partNames => _mesh.partNames;

  /// How many joint matrices a `ModelClip` must supply; 0 when the model is
  /// not skinned.
  int get jointCount => _mesh.jointCount;
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
    this.joints,
    this.weights,
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
  // Four joint indices per vertex of a skinned model.
  final Uint8List? joints;
  // Four weights per vertex of a skinned model, summing to 1.
  final Float32List? weights;

  int get vertexCount => vertexParts.length;
  int get triangleCount => indices.length ~/ 3;

  /// The highest joint with any weight, plus one.
  late final int jointCount = () {
    final joints = this.joints, weights = this.weights;
    if (joints == null || weights == null) return 0;
    var highest = -1;
    for (var i = 0; i < joints.length; i++) {
      if (weights[i] != 0 && joints[i] > highest) highest = joints[i];
    }
    return highest + 1;
  }();
}
