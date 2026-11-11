import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:vector_math/vector_math.dart';

import '../model.dart';

const _glbMagic = 0x46546C67; // "glTF"
const _chunkJson = 0x4E4F534A; // "JSON"
const _chunkBin = 0x004E4942; // "BIN\0"
const _modeTriangles = 4;
const _float = 5126;
const _indexSizes = {5121: 1, 5123: 2, 5125: 4};
const _maxStride = 252;

/// Ceiling set by the 16-bit index buffer of `Canvas.drawVertices`.
const maxVertices = 65536;

/// Parses a GLB file into validated mesh data. Throws [FormatException] on
/// malformed or unsupported input.
MeshData parseGlb(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  if (bytes.length < 20 || data.getUint32(0, Endian.little) != _glbMagic) {
    throw const FormatException('Not a GLB file');
  }
  final version = data.getUint32(4, Endian.little);
  if (version != 2) {
    throw FormatException('Unsupported glTF version $version, expected 2');
  }
  final length = data.getUint32(8, Endian.little);
  if (length > bytes.length) throw const FormatException('GLB is truncated');

  Map<String, Object?>? json;
  ByteData? bin;
  var offset = 12;
  while (offset + 8 <= length) {
    final chunkLength = data.getUint32(offset, Endian.little);
    final chunkType = data.getUint32(offset + 4, Endian.little);
    final start = offset + 8;
    if (start + chunkLength > length) {
      throw const FormatException('GLB chunk runs past the end of the file');
    }
    if (chunkType == _chunkJson && json == null) {
      final text = utf8.decode(
        Uint8List.sublistView(bytes, start, start + chunkLength),
      );
      final decoded = jsonDecode(text);
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('glTF JSON is not an object');
      }
      json = decoded;
    } else if (chunkType == _chunkBin && bin == null) {
      bin = ByteData.sublistView(bytes, start, start + chunkLength);
    }
    offset = start + chunkLength;
  }
  if (json == null) throw const FormatException('GLB has no JSON chunk');
  try {
    return _Reader(json, bin).read();
  } on TypeError catch (e) {
    throw FormatException('Malformed glTF JSON: $e');
  } on RangeError catch (e) {
    throw FormatException('Malformed glTF JSON: $e');
  }
}

class _Reader {
  _Reader(this.json, this.bin);

  final Map<String, Object?> json;
  final ByteData? bin;

  final _partIndex = <String, int>{};
  final _visited = <int>{};
  final _positions = <Float32List>[];
  final _normals = <Float32List>[];
  final _parts = <int>[];
  final _indices = <Uint32List>[];
  var _vertexCount = 0;

  MeshData read() {
    final required = _list(json['extensionsRequired']);
    if (required.isNotEmpty) {
      throw FormatException(
        'Unsupported glTF extensions: ${required.join(', ')}',
      );
    }
    final nodes = _list(json['nodes']);
    for (final root in _rootNodes(nodes)) {
      _visit(nodes, root, Matrix4.identity());
    }
    if (_vertexCount == 0) {
      throw const FormatException('Model has no triangles');
    }
    return _build();
  }

  Iterable<int> _rootNodes(List<Object?> nodes) {
    final scenes = _list(json['scenes']);
    if (scenes.isNotEmpty) {
      final scene = _map(scenes[_int(json['scene'] ?? 0)]);
      return _list(scene['nodes']).map(_int);
    }
    final children = {
      for (final node in nodes) ..._list(_map(node)['children']).map(_int),
    };
    return [
      for (var i = 0; i < nodes.length; i++)
        if (!children.contains(i)) i,
    ];
  }

  void _visit(List<Object?> nodes, int index, Matrix4 parent) {
    // Also catches cycles, which would otherwise recurse forever.
    if (!_visited.add(index)) {
      throw FormatException('Node $index is reachable more than once');
    }
    final node = _map(nodes[index]);
    final world = parent.multiplied(_localMatrix(node));
    final meshIndex = node['mesh'];
    if (meshIndex != null) {
      final mesh = _map(_list(json['meshes'])[_int(meshIndex)]);
      final name = (node['name'] ?? mesh['name'] ?? 'node$index') as String;
      final part = _partIndex.putIfAbsent(name, () => _partIndex.length);
      for (final primitive in _list(mesh['primitives'])) {
        _addPrimitive(_map(primitive), world, part);
      }
    }
    for (final child in _list(node['children'])) {
      _visit(nodes, _int(child), world);
    }
  }

  Matrix4 _localMatrix(Map<String, Object?> node) {
    final matrix = node['matrix'];
    if (matrix != null) return Matrix4.fromList(_doubles(matrix));
    final t = _doubles(node['translation'] ?? [0, 0, 0]);
    final r = _doubles(node['rotation'] ?? [0, 0, 0, 1]);
    final s = _doubles(node['scale'] ?? [1, 1, 1]);
    return Matrix4.compose(
      Vector3(t[0], t[1], t[2]),
      Quaternion(r[0], r[1], r[2], r[3]),
      Vector3(s[0], s[1], s[2]),
    );
  }

  void _addPrimitive(Map<String, Object?> primitive, Matrix4 world, int part) {
    final mode = _int(primitive['mode'] ?? _modeTriangles);
    if (mode != _modeTriangles) {
      throw FormatException(
        'Unsupported primitive mode $mode, only triangles are supported',
      );
    }
    final attributes = _map(primitive['attributes']);
    if (attributes['POSITION'] == null) {
      throw const FormatException('Primitive has no POSITION attribute');
    }
    final positionAccessor = _accessor(_int(attributes['POSITION']));
    final count = _count(positionAccessor);
    if (_vertexCount + count > maxVertices) {
      throw const FormatException('Model has more than $maxVertices vertices');
    }
    final positions = _readVec3(positionAccessor);
    final normalIndex = attributes['NORMAL'];
    final normals = normalIndex == null
        ? null
        : _readVec3(_accessor(_int(normalIndex)));
    if (normals != null && normals.length != positions.length) {
      throw const FormatException('NORMAL and POSITION counts differ');
    }
    final indices = primitive['indices'] == null
        ? Uint32List.fromList([for (var i = 0; i < count; i++) i])
        : _readIndices(_accessor(_int(primitive['indices'])));
    if (indices.length % 3 != 0) {
      throw const FormatException(
        'Triangle index count is not a multiple of 3',
      );
    }
    for (final i in indices) {
      if (i >= count) throw const FormatException('Index out of range');
    }

    final v = Vector3.zero();
    for (var i = 0; i < positions.length; i += 3) {
      v.setValues(positions[i], positions[i + 1], positions[i + 2]);
      world.transform3(v);
      if (!v.x.isFinite || !v.y.isFinite || !v.z.isFinite) {
        throw const FormatException('Positions must be finite');
      }
      positions
        ..[i] = v.x
        ..[i + 1] = v.y
        ..[i + 2] = v.z;
    }
    // A mirroring transform turns counter-clockwise triangles clockwise.
    if (world.determinant() < 0) {
      for (var i = 0; i < indices.length; i += 3) {
        final a = indices[i + 1];
        indices[i + 1] = indices[i + 2];
        indices[i + 2] = a;
      }
    }
    if (normals == null) {
      _normals.add(_computeNormals(positions, indices));
    } else {
      final normalMatrix = world.getNormalMatrix();
      for (var i = 0; i < normals.length; i += 3) {
        v.setValues(normals[i], normals[i + 1], normals[i + 2]);
        normalMatrix.transform(v);
        v.normalize();
        if (!v.x.isFinite || !v.y.isFinite || !v.z.isFinite) {
          throw const FormatException('Normals must be finite');
        }
        normals
          ..[i] = v.x
          ..[i + 1] = v.y
          ..[i + 2] = v.z;
      }
      _normals.add(normals);
    }

    for (var i = 0; i < indices.length; i++) {
      indices[i] += _vertexCount;
    }
    _positions.add(positions);
    _indices.add(indices);
    _parts.add(part);
    _vertexCount += count;
  }

  Float32List _readVec3(Map<String, Object?> accessor) {
    if (accessor['componentType'] != _float || accessor['type'] != 'VEC3') {
      throw const FormatException('Vertex attributes must be float VEC3');
    }
    final count = _count(accessor);
    final (view, stride) = _view(accessor, 12, count);
    final out = Float32List(count * 3);
    for (var i = 0; i < count; i++) {
      final o = i * stride;
      out[i * 3] = view.getFloat32(o, Endian.little);
      out[i * 3 + 1] = view.getFloat32(o + 4, Endian.little);
      out[i * 3 + 2] = view.getFloat32(o + 8, Endian.little);
    }
    return out;
  }

  Uint32List _readIndices(Map<String, Object?> accessor) {
    final size = _indexSizes[accessor['componentType']];
    if (size == null || accessor['type'] != 'SCALAR') {
      throw const FormatException(
        'Indices must be unsigned byte, short or int scalars',
      );
    }
    final count = _count(accessor);
    final (view, stride) = _view(accessor, size, count);
    final out = Uint32List(count);
    for (var i = 0; i < count; i++) {
      final o = i * stride;
      out[i] = switch (size) {
        1 => view.getUint8(o),
        2 => view.getUint16(o, Endian.little),
        _ => view.getUint32(o, Endian.little),
      };
    }
    return out;
  }

  Map<String, Object?> _accessor(int index) {
    final accessor = _map(_list(json['accessors'])[index]);
    if (accessor['sparse'] != null) {
      throw const FormatException('Sparse accessors are not supported');
    }
    if (accessor['bufferView'] == null) {
      throw const FormatException(
        'Accessors without a bufferView are not supported',
      );
    }
    return accessor;
  }

  int _count(Map<String, Object?> accessor) {
    final count = _int(accessor['count']);
    if (count < 1) throw const FormatException('Accessor count must be >= 1');
    return count;
  }

  /// The bytes of [accessor] from its first element on, and the element
  /// stride, after checking that every element lies inside its buffer view
  /// and the view inside the binary chunk.
  (ByteData, int) _view(
    Map<String, Object?> accessor,
    int elementSize,
    int count,
  ) {
    final bufferView = _map(
      _list(json['bufferViews'])[_int(accessor['bufferView'])],
    );
    final buffer = _map(_list(json['buffers'])[_int(bufferView['buffer'])]);
    final bin = this.bin;
    if (buffer['uri'] != null || bin == null) {
      throw const FormatException(
        'Only the embedded GLB binary buffer is supported',
      );
    }
    final declaredStride = _int(bufferView['byteStride'] ?? 0);
    if (declaredStride != 0 &&
        (declaredStride < elementSize ||
            declaredStride > _maxStride ||
            declaredStride % 4 != 0)) {
      throw FormatException('Invalid byteStride $declaredStride');
    }
    final stride = declaredStride == 0 ? elementSize : declaredStride;
    final viewOffset = _int(bufferView['byteOffset'] ?? 0);
    final viewLength = _int(bufferView['byteLength']);
    final accessorOffset = _int(accessor['byteOffset'] ?? 0);
    if (viewOffset < 0 ||
        viewLength < 0 ||
        accessorOffset < 0 ||
        viewOffset + viewLength > bin.lengthInBytes ||
        count > viewLength ||
        accessorOffset + stride * (count - 1) + elementSize > viewLength) {
      throw const FormatException('Accessor runs past its buffer');
    }
    return (
      ByteData.sublistView(
        bin,
        viewOffset + accessorOffset,
        viewOffset + viewLength,
      ),
      stride,
    );
  }

  MeshData _build() {
    final positions = Float32List(_vertexCount * 3);
    final normals = Float32List(_vertexCount * 3);
    final vertexParts = Uint16List(_vertexCount);
    final indexCount = _indices.fold(0, (sum, list) => sum + list.length);
    final indices = Uint16List(indexCount);
    var vertexOffset = 0;
    var indexOffset = 0;
    for (var p = 0; p < _positions.length; p++) {
      positions.setAll(vertexOffset * 3, _positions[p]);
      normals.setAll(vertexOffset * 3, _normals[p]);
      final count = _positions[p].length ~/ 3;
      vertexParts.fillRange(vertexOffset, vertexOffset + count, _parts[p]);
      indices.setAll(indexOffset, _indices[p]);
      vertexOffset += count;
      indexOffset += _indices[p].length;
    }
    final bounds = Float64List.fromList([
      ...List.filled(3, double.infinity),
      ...List.filled(3, double.negativeInfinity),
    ]);
    for (var i = 0; i < positions.length; i += 3) {
      for (var axis = 0; axis < 3; axis++) {
        final value = positions[i + axis];
        if (value < bounds[axis]) bounds[axis] = value;
        if (value > bounds[axis + 3]) bounds[axis + 3] = value;
      }
    }
    return MeshData(
      partNames: List.unmodifiable(_partIndex.keys),
      positions: positions,
      normals: normals,
      vertexParts: vertexParts,
      indices: indices,
      bounds: bounds,
    );
  }
}

/// Smooth normals: area-weighted sum of the face normals around each vertex.
Float32List _computeNormals(Float32List positions, Uint32List indices) {
  final normals = Float32List(positions.length);
  for (var t = 0; t < indices.length; t += 3) {
    final a = indices[t] * 3, b = indices[t + 1] * 3, c = indices[t + 2] * 3;
    final ux = positions[b] - positions[a];
    final uy = positions[b + 1] - positions[a + 1];
    final uz = positions[b + 2] - positions[a + 2];
    final vx = positions[c] - positions[a];
    final vy = positions[c + 1] - positions[a + 1];
    final vz = positions[c + 2] - positions[a + 2];
    final nx = uy * vz - uz * vy,
        ny = uz * vx - ux * vz,
        nz = ux * vy - uy * vx;
    for (final i in [a, b, c]) {
      normals[i] += nx;
      normals[i + 1] += ny;
      normals[i + 2] += nz;
    }
  }
  for (var i = 0; i < normals.length; i += 3) {
    final length = math.sqrt(
      normals[i] * normals[i] +
          normals[i + 1] * normals[i + 1] +
          normals[i + 2] * normals[i + 2],
    );
    if (length > 0) {
      normals[i] /= length;
      normals[i + 1] /= length;
      normals[i + 2] /= length;
    }
  }
  return normals;
}

List<Object?> _list(Object? value) =>
    value == null ? const [] : value as List<Object?>;

Map<String, Object?> _map(Object? value) => value as Map<String, Object?>;

int _int(Object? value) => (value as num).toInt();

List<double> _doubles(Object? value) => [
  for (final n in value as List<Object?>) (n as num).toDouble(),
];
