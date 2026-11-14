import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Generated placeholder photos: a light and a dark 1×1 grey PNG.
final placeholderLight = MemoryImage(
  Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
    0x0C, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x98, 0xB5, 0x78, 0x1D,
    0x00, 0x03, 0xC6, 0x01, 0xEC, 0x39, 0x83, 0xA0, 0x07, 0x00, 0x00, 0x00,
    0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]),
);

final placeholderDark = MemoryImage(
  Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
    0x0C, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x88, 0x4E, 0x2D, 0x06,
    0x00, 0x02, 0x52, 0x01, 0x34, 0xE5, 0x10, 0xF3, 0x8D, 0x00, 0x00, 0x00,
    0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]),
);

Widget _grid(List<Widget> tiles) => ListView(
  padding: const EdgeInsets.all(Gap.md),
  children: [
    GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: Gap.sm,
      crossAxisSpacing: Gap.sm,
      childAspectRatio: PhotoTile.aspectRatio,
      children: tiles,
    ),
  ],
);

@widgetbook.UseCase(name: 'Photo', type: PhotoTile)
Widget photoTile(BuildContext context) => _grid([
  for (final (view, image) in [
    ('View A', placeholderLight),
    ('View B', placeholderDark),
    ('View C', placeholderLight),
  ])
    PhotoTile(image: image, label: view, onTap: () {}),
  PhotoTile.empty(message: 'Add photo', onTap: () {}),
]);

@widgetbook.UseCase(name: 'Empty slot with a view', type: PhotoTile)
Widget photoTileEmptyWithView(BuildContext context) => _grid([
  PhotoTile.empty(
    message: 'Add photo',
    label: context.knobs.string(label: 'View', initialValue: 'View D'),
    onTap: () {},
  ),
]);

@widgetbook.UseCase(name: 'Uploading', type: PhotoTile)
Widget photoTileUploading(BuildContext context) => _grid([
  PhotoTile.uploading(
    progress: context.knobs.double.slider(label: 'Progress', initialValue: 0.6),
  ),
]);

@widgetbook.UseCase(name: 'Failed', type: PhotoTile)
Widget photoTileFailed(BuildContext context) =>
    _grid([PhotoTile.failed(message: 'Upload failed', onRetry: () {})]);

@widgetbook.UseCase(name: 'Offline', type: PhotoTile)
Widget photoTileOffline(BuildContext context) =>
    _grid([const PhotoTile.offline(message: 'Waiting for connection')]);
