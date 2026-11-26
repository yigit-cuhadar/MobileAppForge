import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

/// The longest side of a cell in metres: the viewer sorts whole triangles by
/// depth, so faces are cut this fine.
const cell = 0.09;

enum PieceShape { box, cylinder, ball }

/// Collects the gear mesh in file space (y up, facing +z, the file's unit).
class MeshBuilder {
  MeshBuilder(this.metres);

  final double metres;
  final positions = <double>[];
  final normals = <double>[];
  final parts = <int>[];
  final joints = <int>[];
  final indices = <int>[];

  int get vertexCount => parts.length;

  /// A unit cube, unit cylinder or unit ball placed by [linear] and [offset] (rig space,
  /// metres), as export.py's `shape` cuts it.
  void addPiece({
    required PieceShape shape,
    required Matrix3 linear,
    required Vector3 offset,
    required int part,
    required int joint,
  }) {
    final size = [
      for (var c = 0; c < 3; c++)
        math.sqrt(
          linear.entry(0, c) * linear.entry(0, c) +
              linear.entry(1, c) * linear.entry(1, c) +
              linear.entry(2, c) * linear.entry(2, c),
        ),
    ];
    final cells = [for (final s in size) math.max(1, (s / cell).ceil())];
    final normalMatrix = Matrix3.copy(linear)
      ..invert()
      ..transpose();
    void vertex(double x, double y, double z, double nx, double ny, double nz) {
      final p = linear.transformed(Vector3(x, y, z))..add(offset);
      final n = normalMatrix.transformed(Vector3(nx, ny, nz))..normalize();
      _add(p.x / metres, p.z / metres, -p.y / metres, n.x, n.z, -n.y);
      parts.add(part);
      joints.add(joint);
    }

    if (shape == PieceShape.ball) {
      const around = 24, rings = 12;
      final start = vertexCount;
      for (var j = 0; j <= rings; j++) {
        for (var i = 0; i <= around; i++) {
          final turn = i * 2 * math.pi / around, tilt = j * math.pi / rings;
          final x = math.sin(tilt) * math.cos(turn);
          final y = math.sin(tilt) * math.sin(turn);
          final z = -math.cos(tilt);
          vertex(x, y, z, x, y, z);
        }
      }
      _quads(start, around, rings);
      return;
    }
    if (shape == PieceShape.box) {
      for (var axis = 0; axis < 3; axis++) {
        for (final sign in const [-1, 1]) {
          final (a, b) = sign > 0
              ? ((axis + 1) % 3, (axis + 2) % 3)
              : ((axis + 2) % 3, (axis + 1) % 3);
          final columns = cells[a], rows = cells[b];
          final start = vertexCount;
          for (var j = 0; j <= rows; j++) {
            for (var i = 0; i <= columns; i++) {
              final p = [0.0, 0.0, 0.0], n = [0.0, 0.0, 0.0];
              n[axis] = sign.toDouble();
              p[axis] = sign / 2;
              p[a] = i / columns - 0.5;
              p[b] = j / rows - 0.5;
              vertex(p[0], p[1], p[2], n[0], n[1], n[2]);
            }
          }
          _quads(start, columns, rows);
        }
      }
      return;
    }

    final around = size[0] < 0.02 ? 10 : 24;
    final rings = math.max(1, (size[0] / cell).ceil());
    final length = cells[2];
    final start = vertexCount;
    for (var j = 0; j <= length; j++) {
      for (var i = 0; i <= around; i++) {
        final angle = i * 2 * math.pi / around;
        final x = math.cos(angle), y = math.sin(angle);
        vertex(x, y, j / length - 0.5, x, y, 0);
      }
    }
    _quads(start, around, length);
    for (final end in const [-1.0, 1.0]) {
      final start = vertexCount;
      for (var j = 0; j <= rings; j++) {
        for (var i = 0; i <= around; i++) {
          final angle = i * 2 * math.pi / around;
          final radius = j / rings;
          vertex(
            radius * math.cos(angle),
            radius * math.sin(angle),
            end / 2,
            0,
            0,
            end,
          );
        }
      }
      _cap(start, around, rings, flip: end < 0);
    }
  }

  /// A flat disc facing up at height [y] (file space) round ([x], [z]), cut
  /// like a cylinder cap with enough sides that no cell passes [cell].
  void addDisc({
    required double x,
    required double y,
    required double z,
    required double radius,
    required int part,
    required int joint,
  }) {
    final metresRadius = radius * metres;
    final rings = math.max(1, (metresRadius / cell).ceil());
    final around = math.max(24, (2 * math.pi * metresRadius / cell).ceil());
    final start = vertexCount;
    for (var j = 0; j <= rings; j++) {
      for (var i = 0; i <= around; i++) {
        final angle = i * 2 * math.pi / around;
        final r = radius * j / rings;
        // Rig (cos, sin) on the ground is file (cos, -sin).
        _add(x + r * math.cos(angle), y, z - r * math.sin(angle), 0, 1, 0);
        parts.add(part);
        joints.add(joint);
      }
    }
    _cap(start, around, rings, flip: false);
  }

  void _add(double x, double y, double z, double nx, double ny, double nz) {
    positions.addAll([x, y, z]);
    normals.addAll([nx, ny, nz]);
  }

  /// Two triangles per cell of a grid [columns] + 1 vertices wide.
  void _quads(int start, int columns, int rows) {
    for (var j = 0; j < rows; j++) {
      for (var i = 0; i < columns; i++) {
        final a = start + j * (columns + 1) + i;
        indices.addAll([
          a,
          a + 1,
          a + columns + 2,
          a,
          a + columns + 2,
          a + columns + 1,
        ]);
      }
    }
  }

  /// Rings of a cap from the centre out; the innermost is a fan.
  void _cap(int start, int around, int rings, {required bool flip}) {
    for (var j = 0; j < rings; j++) {
      for (var i = 0; i < around; i++) {
        final a = start + j * (around + 1) + i;
        final triangles = [
          a,
          a + around + 1,
          a + around + 2,
          a,
          a + around + 2,
          a + 1,
        ];
        indices.addAll(flip ? triangles.reversed : triangles);
      }
    }
  }
}
