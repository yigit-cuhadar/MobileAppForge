/// How a value reads as each type, shared by the Firebase repository and the
/// fake so both read alike. Server values are strings, parsed as the
/// Firebase SDK parses them; app defaults are typed, and a number serves
/// both [readInt] (when integral) and [readDouble]. Anything else reads as
/// `''`, `false` or `0`.
library;

String readString(Object? value) => value == null ? '' : '$value';

bool readBool(Object? value) => switch (value) {
  final bool flag => flag,
  final String text => text.toLowerCase() == 'true' || text == '1',
  final num number => number == 1,
  _ => false,
};

int readInt(Object? value) => switch (value) {
  final int number => number,
  final double number when number == number.truncateToDouble() =>
    number.toInt(),
  final String text => int.tryParse(text) ?? 0,
  _ => 0,
};

double readDouble(Object? value) => switch (value) {
  final num number => number.toDouble(),
  final String text => double.tryParse(text) ?? 0,
  _ => 0,
};
