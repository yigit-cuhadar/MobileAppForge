import 'dart:convert';
import 'dart:typed_data';

/// Builds small GLB files for tests.
class GlbBuilder {
  final _bin = BytesBuilder();
  final accessors = <Map<String, Object?>>[];
  final bufferViews = <Map<String, Object?>>[];

  int addVec3(List<double> values) {
    final data = Float32List.fromList(values);
    return _add(data.buffer.asUint8List(), {
      'componentType': 5126,
      'type': 'VEC3',
      'count': values.length ~/ 3,
    });
  }

  /// [componentType]: 5121 (u8), 5123 (u16) or 5125 (u32).
  int addIndices(List<int> values, {int componentType = 5123}) {
    final TypedData data = switch (componentType) {
      5121 => Uint8List.fromList(values),
      5123 => Uint16List.fromList(values),
      _ => Uint32List.fromList(values),
    };
    return _add(data.buffer.asUint8List(), {
      'componentType': componentType,
      'type': 'SCALAR',
      'count': values.length,
    });
  }

  int _add(Uint8List bytes, Map<String, Object?> accessor) {
    while (_bin.length % 4 != 0) {
      _bin.addByte(0);
    }
    bufferViews.add({
      'buffer': 0,
      'byteOffset': _bin.length,
      'byteLength': bytes.length,
    });
    _bin.add(bytes);
    accessors.add({...accessor, 'bufferView': bufferViews.length - 1});
    return accessors.length - 1;
  }

  /// Assembles the GLB; [extra] adds or overrides top-level JSON keys.
  Uint8List build({
    required List<Map<String, Object?>> nodes,
    required List<Map<String, Object?>> meshes,
    List<int>? sceneNodes,
    Map<String, Object?> extra = const {},
  }) {
    while (_bin.length % 4 != 0) {
      _bin.addByte(0);
    }
    final bin = _bin.toBytes();
    final json = {
      'asset': {'version': '2.0'},
      'scene': 0,
      'scenes': [
        {
          'nodes': sceneNodes ?? [for (var i = 0; i < nodes.length; i++) i],
        },
      ],
      'nodes': nodes,
      'meshes': meshes,
      'accessors': accessors,
      'bufferViews': bufferViews,
      'buffers': [
        {'byteLength': bin.length},
      ],
      ...extra,
    };
    return glb(utf8.encode(jsonEncode(json)), bin);
  }
}

/// Wraps a JSON and a BIN chunk in a GLB container.
Uint8List glb(List<int> json, Uint8List bin, {int version = 2}) {
  final jsonPadded = [...json, for (var i = json.length; i % 4 != 0; i++) 0x20];
  final length = 12 + 8 + jsonPadded.length + 8 + bin.length;
  final out = ByteData(length);
  out
    ..setUint32(0, 0x46546C67, Endian.little)
    ..setUint32(4, version, Endian.little)
    ..setUint32(8, length, Endian.little)
    ..setUint32(12, jsonPadded.length, Endian.little)
    ..setUint32(16, 0x4E4F534A, Endian.little);
  final bytes = out.buffer.asUint8List();
  bytes.setAll(20, jsonPadded);
  final binStart = 20 + jsonPadded.length;
  out
    ..setUint32(binStart, bin.length, Endian.little)
    ..setUint32(binStart + 4, 0x004E4942, Endian.little);
  bytes.setAll(binStart + 8, bin);
  return bytes;
}

/// Positions of an axis-aligned quad facing +z at depth [z].
List<double> quad(double x0, double y0, double x1, double y1, double z) => [
  x0, y0, z, //
  x1, y0, z,
  x1, y1, z,
  x0, y1, z,
];

const quadIndices = [0, 1, 2, 0, 2, 3];

/// A model of front-facing quads, one named part each.
Uint8List quadsGlb(Map<String, List<double>> parts) {
  final builder = GlbBuilder();
  final meshes = <Map<String, Object?>>[];
  for (final positions in parts.values) {
    meshes.add({
      'primitives': [
        {
          'attributes': {'POSITION': builder.addVec3(positions)},
          'indices': builder.addIndices(quadIndices),
        },
      ],
    });
  }
  return builder.build(
    nodes: [
      for (final (i, name) in parts.keys.indexed) {'name': name, 'mesh': i},
    ],
    meshes: meshes,
  );
}
