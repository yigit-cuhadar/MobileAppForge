/// Interactive viewer for 3D models made of named parts, from glTF files or
/// raw geometry, rendered on the CPU with `Canvas.drawVertices`. Skinned
/// models play any looped source of joint matrices, such as a baked clip,
/// and can mark points on the model as it moves.
library;

export 'src/clip.dart' show ModelClip;
export 'src/model.dart' show Model3D;
export 'src/motion.dart';
export 'src/widget/model_viewer.dart';
export 'src/widget/model_viewer_controller.dart';
