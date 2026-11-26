import 'dart:convert';
import 'dart:io';

import 'package:forge_motion/forge_motion.dart';

Map<String, Object?> _json(String path) =>
    jsonDecode(File('test/fixtures/$path').readAsStringSync())
        as Map<String, Object?>;

final rigJson = _json('rig.json');
final rig = MotionRig.fromJson(rigJson);
final kits = _json('kits.json');

Map<String, Object?> recipe(String name) => _json('recipes/$name.json');

const recipes = ['hang_and_pull', 'lie_and_press', 'stand_and_sit'];

Duration seconds(num value) => Duration(microseconds: (value * 1e6).round());
