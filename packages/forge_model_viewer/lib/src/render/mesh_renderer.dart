import 'dart:math' as math;
import 'dart:typed_data';

import '../model.dart';

const _fieldOfView = 35 * math.pi / 180;
const _ambient = 0.4;
const _diffuse = 0.6;
// Light direction in view space: from the camera, slightly up and left.
const _lightX = -0.35, _lightY = 0.45, _lightZ = 0.82;
final _lightLength = math.sqrt(
  _lightX * _lightX + _lightY * _lightY + _lightZ * _lightZ,
);

/// Projects, culls, depth-sorts and shades [MeshData] on the CPU into
/// buffers ready for `Canvas.drawVertices`. All buffers are allocated once,
/// the posed mesh on the first [pose]; [update] and [shade] allocate nothing.
///
/// The model is centred on its bounds (or the given ones) and scaled to a
/// unit bounding sphere.
/// The camera looks down -z; yaw turns the model around y, then pitch tilts it
/// around x. The camera stays outside the sphere; zoom scales the projection,
/// and at zoom 1 the whole sphere fits the shorter side of the view.
///
/// A skinned model can be [pose]d; [update], [shade] and [pick] then use the
/// posed mesh.
class MeshRenderer {
  MeshRenderer(MeshData model, {Float64List? bounds})
    : this._(model, bounds ?? model.bounds);

  MeshRenderer._(this.model, Float64List bounds)
    : screen = Float32List(model.vertexCount * 2),
      colors = Int32List(model.vertexCount),
      partColors = Int32List(model.partNames.length),
      groundParts = Uint8List(model.partNames.length),
      drawIndices = Uint16List(model.indices.length),
      _depth = Float32List(model.vertexCount),
      _order = Int32List(model.triangleCount),
      _orderTmp = Int32List(model.triangleCount),
      _keys = Uint16List(model.triangleCount),
      _keysTmp = Uint16List(model.triangleCount),
      _positions = model.positions,
      _normals = model.normals,
      _cx = (bounds[0] + bounds[3]) / 2,
      _cy = (bounds[1] + bounds[4]) / 2,
      _cz = (bounds[2] + bounds[5]) / 2,
      _scale = _unitScale(bounds);

  static double _unitScale(Float64List b) {
    final dx = b[3] - b[0], dy = b[4] - b[1], dz = b[5] - b[2];
    final diagonal = math.sqrt(dx * dx + dy * dy + dz * dz);
    return diagonal > 0 ? 2 / diagonal : 1;
  }

  // Camera distance at which the unit sphere fits the field of view.
  static final _distance = 1 / math.sin(_fieldOfView / 2);

  final MeshData model;

  /// Screen x, y per vertex, from the last [update].
  final Float32List screen;

  /// ARGB per vertex, from the last [shade].
  final Int32List colors;

  /// ARGB per part; the caller fills it before [shade] (opaque) or [fill].
  final Int32List partColors;

  /// Non-zero per part that lies on the ground: its triangles are drawn
  /// under every other part's, in the model's order, and [shade] leaves
  /// them unlit. The caller fills it before [update].
  final Uint8List groundParts;

  /// Visible triangles, back to front; the first [drawIndexCount] are valid.
  final Uint16List drawIndices;
  int drawIndexCount = 0;

  final Float32List _depth;
  final Int32List _order, _orderTmp;
  final Uint16List _keys, _keysTmp;
  final _counts = Int32List(256);
  final double _cx, _cy, _cz, _scale;
  // The model's rest mesh until the first pose.
  Float32List _positions, _normals;
  late final _posedPositions = Float32List(model.positions.length);
  late final _posedNormals = Float32List(model.normals.length);

  // The model-space light direction of the last update.
  double _lmx = 0, _lmy = 0, _lmz = 1;
  // The model-space to screen map of the last update: view x, y and depth as
  // affine maps of model x, y, z, then the perspective divide.
  double _x0 = 0, _x2 = 0, _xt = 0;
  double _y0 = 0, _y1 = 0, _y2 = 0, _yt = 0;
  double _z0 = 0, _z1 = 0, _z2 = 0, _zt = 0;
  double _focal = 0, _halfW = 0, _halfH = 0;
  double? _lastWidth, _lastHeight, _lastYaw, _lastPitch, _lastZoom;

  /// Blends every vertex of a skinned model by its joints' [matrices]: per
  /// joint, a 3x4 model-space affine matrix in row-major order. Normals take
  /// the 3x3 part only and are not renormalised. Does nothing for an
  /// unskinned model.
  void pose(Float32List matrices) {
    final joints = model.joints, weights = model.weights;
    if (joints == null || weights == null) return;
    assert(matrices.length >= model.jointCount * 12);
    final rest = model.positions, restNormals = model.normals;
    final positions = _posedPositions, normals = _posedNormals;
    final m = matrices;
    for (var p = 0, i = 0; p < rest.length; p += 3) {
      final x = rest[p], y = rest[p + 1], z = rest[p + 2];
      final nx = restNormals[p], ny = restNormals[p + 1];
      final nz = restNormals[p + 2];
      var px = 0.0, py = 0.0, pz = 0.0, qx = 0.0, qy = 0.0, qz = 0.0;
      for (final end = i + 4; i < end; i++) {
        final w = weights[i];
        if (w == 0) continue;
        final j = joints[i] * 12;
        final m00 = m[j], m01 = m[j + 1], m02 = m[j + 2];
        final m10 = m[j + 4], m11 = m[j + 5], m12 = m[j + 6];
        final m20 = m[j + 8], m21 = m[j + 9], m22 = m[j + 10];
        px += w * (m00 * x + m01 * y + m02 * z + m[j + 3]);
        py += w * (m10 * x + m11 * y + m12 * z + m[j + 7]);
        pz += w * (m20 * x + m21 * y + m22 * z + m[j + 11]);
        qx += w * (m00 * nx + m01 * ny + m02 * nz);
        qy += w * (m10 * nx + m11 * ny + m12 * nz);
        qz += w * (m20 * nx + m21 * ny + m22 * nz);
      }
      positions
        ..[p] = px
        ..[p + 1] = py
        ..[p + 2] = pz;
      normals
        ..[p] = qx
        ..[p + 1] = qy
        ..[p + 2] = qz;
    }
    _positions = positions;
    _normals = normals;
    _lastWidth = null;
  }

  /// Projects every vertex and rebuilds [drawIndices] for the given view.
  /// Does nothing when the view and the pose are unchanged since the last
  /// call.
  void update(
    double width,
    double height,
    double yaw,
    double pitch,
    double zoom,
  ) {
    if (width == _lastWidth &&
        height == _lastHeight &&
        yaw == _lastYaw &&
        pitch == _lastPitch &&
        zoom == _lastZoom) {
      return;
    }
    _lastWidth = width;
    _lastHeight = height;
    _lastYaw = yaw;
    _lastPitch = pitch;
    _lastZoom = zoom;

    final cy = math.cos(yaw), sy = math.sin(yaw);
    final cp = math.cos(pitch), sp = math.sin(pitch);
    // Rows of Rx(pitch) * Ry(yaw); r01 is always 0.
    final r00 = cy, r02 = sy;
    final r10 = sy * sp, r11 = cp, r12 = -cy * sp;
    final r20 = -sy * cp, r21 = sp, r22 = cy * cp;
    final lx = _lightX / _lightLength;
    final ly = _lightY / _lightLength;
    final lz = _lightZ / _lightLength;
    _lmx = r00 * lx + r10 * ly + r20 * lz;
    _lmy = r11 * ly + r21 * lz;
    _lmz = r02 * lx + r12 * ly + r22 * lz;

    final distance = _distance;
    final focal = _focal =
        zoom * math.min(width, height) / 2 / math.tan(_fieldOfView / 2);
    final halfW = _halfW = width / 2, halfH = _halfH = height / 2;
    // Centring, scaling and rotation folded into one affine map per axis.
    final k = _scale, cx = _cx, cy0 = _cy, cz = _cz;
    final x0 = _x0 = k * r00, x2 = _x2 = k * r02;
    final xt = _xt = -(x0 * cx + x2 * cz);
    final y0 = _y0 = k * r10, y1 = _y1 = k * r11, y2 = _y2 = k * r12;
    final yt = _yt = -(y0 * cx + y1 * cy0 + y2 * cz);
    final z0 = _z0 = k * r20, z1 = _z1 = k * r21, z2 = _z2 = k * r22;
    final zt = _zt = distance + z0 * cx + z1 * cy0 + z2 * cz;
    final positions = _positions;
    final screen = this.screen;
    final depth = _depth;
    final vertexCount = depth.length;
    for (var v = 0, p = 0; v < vertexCount; v++, p += 3) {
      final px = positions[p], py = positions[p + 1], pz = positions[p + 2];
      final d = zt - z0 * px - z1 * py - z2 * pz;
      depth[v] = d;
      final f = focal / d;
      screen[v * 2] = halfW + (x0 * px + x2 * pz + xt) * f;
      screen[v * 2 + 1] = halfH - (y0 * px + y1 * py + y2 * pz + yt) * f;
    }

    // Cull back faces; key the rest by centroid depth, quantised over the
    // model's depth range, far first.
    final indices = model.indices;
    final indexCount = indices.length;
    final order = _order, keys = _keys;
    final parts = model.vertexParts, ground = groundParts;
    final nearest = distance - 1;
    var visible = 0;
    for (var t = 0, i = 0; i < indexCount; t++, i += 3) {
      final a = indices[i], b = indices[i + 1], c = indices[i + 2];
      final da = depth[a], db = depth[b], dc = depth[c];
      final ax = screen[a * 2], ay = screen[a * 2 + 1];
      final area =
          (screen[b * 2] - ax) * (screen[c * 2 + 1] - ay) -
          (screen[c * 2] - ax) * (screen[b * 2 + 1] - ay);
      // Counter-clockwise in a y-up world is clockwise on a y-down screen.
      if (area >= 0) continue;
      final q = ((da + db + dc) / 3 - nearest) * 32767.5;
      order[visible] = t;
      keys[visible] = ground[parts[a]] != 0
          ? 0
          : q <= 0
          ? 65535
          : (q >= 65534 ? 1 : 65535 - q.toInt());
      visible++;
    }
    _radixSort(visible);

    final out = drawIndices;
    for (var k = 0, o = 0; k < visible; k++, o += 3) {
      final i = order[k] * 3;
      out[o] = indices[i];
      out[o + 1] = indices[i + 1];
      out[o + 2] = indices[i + 2];
    }
    drawIndexCount = visible * 3;
  }

  /// Writes screen x, y into [out] for every model-space x, y, z in [points],
  /// as seen in the last [update].
  void project(Float32List points, Float32List out) {
    assert(out.length * 3 >= points.length * 2);
    final x0 = _x0, x2 = _x2, xt = _xt;
    final y0 = _y0, y1 = _y1, y2 = _y2, yt = _yt;
    final z0 = _z0, z1 = _z1, z2 = _z2, zt = _zt;
    final focal = _focal, halfW = _halfW, halfH = _halfH;
    for (var p = 0, o = 0; p < points.length; p += 3, o += 2) {
      final px = points[p], py = points[p + 1], pz = points[p + 2];
      final f = focal / (zt - z0 * px - z1 * py - z2 * pz);
      out[o] = halfW + (x0 * px + x2 * pz + xt) * f;
      out[o + 1] = halfH - (y0 * px + y1 * py + y2 * pz + yt) * f;
    }
  }

  // Stable two-pass LSD radix sort of _order by the 16-bit _keys.
  void _radixSort(int n) {
    _radixPass(n, 0, _order, _keys, _orderTmp, _keysTmp);
    _radixPass(n, 8, _orderTmp, _keysTmp, _order, _keys);
  }

  void _radixPass(
    int n,
    int shift,
    Int32List order,
    Uint16List keys,
    Int32List orderOut,
    Uint16List keysOut,
  ) {
    final counts = _counts..fillRange(0, 256, 0);
    for (var i = 0; i < n; i++) {
      counts[(keys[i] >> shift) & 0xFF]++;
    }
    for (var b = 0, sum = 0; b < 256; b++) {
      final c = counts[b];
      counts[b] = sum;
      sum += c;
    }
    for (var i = 0; i < n; i++) {
      final key = keys[i];
      final slot = counts[(key >> shift) & 0xFF]++;
      orderOut[slot] = order[i];
      keysOut[slot] = key;
    }
  }

  /// Lights every vertex of the last [update] with its part's colour from
  /// [partColors]: ambient plus lambert from a light fixed to the camera.
  void shade() {
    final normals = _normals;
    final parts = model.vertexParts;
    final colors = this.colors, partColors = this.partColors;
    final ground = groundParts;
    final lmx = _lmx, lmy = _lmy, lmz = _lmz;
    final vertexCount = colors.length;
    for (var v = 0, p = 0; v < vertexCount; v++, p += 3) {
      final lambert =
          normals[p] * lmx + normals[p + 1] * lmy + normals[p + 2] * lmz;
      final part = parts[v];
      final light = ground[part] != 0
          ? 1.0
          : lambert > 0
          ? _ambient + _diffuse * lambert
          : _ambient;
      final argb = partColors[part];
      final r = (((argb >> 16) & 0xFF) * light).toInt();
      final g = (((argb >> 8) & 0xFF) * light).toInt();
      final b = ((argb & 0xFF) * light).toInt();
      colors[v] = 0xFF000000 | r << 16 | g << 8 | b;
    }
  }

  /// Gives every vertex its part's colour from [partColors] unlit, alpha
  /// included.
  void fill() {
    final parts = model.vertexParts;
    final colors = this.colors, partColors = this.partColors;
    for (var v = 0; v < colors.length; v++) {
      colors[v] = partColors[parts[v]];
    }
  }

  /// The name of the front-most part drawn at screen point ([x], [y]) in the
  /// last [update]. Null when the point misses the model or that part is not
  /// [selectable]: unselectable parts still hide what is behind them.
  String? pick(double x, double y, bool Function(String part) selectable) {
    final screen = this.screen;
    final depth = _depth;
    final out = drawIndices;
    var best = -1;
    var bestInverseDepth = 0.0;
    for (var o = 0; o < drawIndexCount; o += 3) {
      final a = out[o], b = out[o + 1], c = out[o + 2];
      final x0 = screen[a * 2], y0 = screen[a * 2 + 1];
      final x1 = screen[b * 2], y1 = screen[b * 2 + 1];
      final x2 = screen[c * 2], y2 = screen[c * 2 + 1];
      final area = (x1 - x0) * (y2 - y0) - (x2 - x0) * (y1 - y0);
      final w0 = ((x1 - x) * (y2 - y) - (x2 - x) * (y1 - y)) / area;
      final w1 = ((x2 - x) * (y0 - y) - (x0 - x) * (y2 - y)) / area;
      final w2 = 1 - w0 - w1;
      if (w0 < 0 || w1 < 0 || w2 < 0) continue;
      // 1/depth is linear in screen space, so this interpolation is exact.
      final inverseDepth = w0 / depth[a] + w1 / depth[b] + w2 / depth[c];
      if (inverseDepth > bestInverseDepth) {
        bestInverseDepth = inverseDepth;
        best = a;
      }
    }
    if (best < 0) return null;
    final part = model.partNames[model.vertexParts[best]];
    return selectable(part) ? part : null;
  }
}
