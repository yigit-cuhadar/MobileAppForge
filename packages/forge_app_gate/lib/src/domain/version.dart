import 'package:forge_core/forge_core.dart';

/// A release's version as the stores show it: dot-separated numbers
/// (`1.4.2`). Missing parts count as 0, so `1.4` is `1.4.0`; a build number
/// or pre-release suffix (`+7`, `-beta`) is ignored.
final class Version extends Equatable implements Comparable<Version> {
  const Version(this.parts);

  final List<int> parts;

  /// Null for text that is not a version, such as `''` or `v1.2`.
  static Version? tryParse(String text) {
    final core = text.trim().split(RegExp('[+-]')).first;
    if (core.isEmpty) return null;
    final parts = <int>[];
    for (final part in core.split('.')) {
      final number = int.tryParse(part);
      if (number == null || number < 0) return null;
      parts.add(number);
    }
    return Version(parts);
  }

  bool operator <(Version other) => compareTo(other) < 0;

  @override
  int compareTo(Version other) {
    final length = parts.length > other.parts.length
        ? parts.length
        : other.parts.length;
    for (var i = 0; i < length; i++) {
      final difference = _at(i) - other._at(i);
      if (difference != 0) return difference.sign;
    }
    return 0;
  }

  int _at(int i) => i < parts.length ? parts[i] : 0;

  /// The parts without trailing zeros, so `1.4` equals `1.4.0`.
  @override
  List<Object?> get props {
    var end = parts.length;
    while (end > 0 && parts[end - 1] == 0) {
      end--;
    }
    return parts.sublist(0, end);
  }

  @override
  String toString() => parts.join('.');
}
