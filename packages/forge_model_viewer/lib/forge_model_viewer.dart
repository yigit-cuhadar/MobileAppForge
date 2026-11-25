/// Interactive viewer for glTF models made of named parts, rendered on the
/// CPU with `Canvas.drawVertices`. Skinned models play looped clips of joint
/// matrices.
library;

export 'src/clip.dart' show ModelClip;
export 'src/model.dart' show Model3D;
export 'src/widget/model_viewer.dart';
export 'src/widget/model_viewer_controller.dart';
