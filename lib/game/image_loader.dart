import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../models/puzzle_info.dart';
import '../services/storage_service.dart';

/// Loads the puzzle picture into memory so we can cut it into pieces.
Future<ui.Image> loadPuzzleImage(PuzzleInfo puzzle) async {
  final Uint8List bytes;
  if (puzzle.bytes != null) {
    bytes = puzzle.bytes!; // photo picked on the web, already in memory
  } else if (puzzle.filePath != null) {
    bytes = await File(StorageService.instance.photoPath(puzzle.filePath!)).readAsBytes(); // phone photo
  } else {
    bytes = (await rootBundle.load(puzzle.assetPath!)).buffer.asUint8List(); // built-in picture
  }

  // Limit the size so big phone photos do not use too much memory.
  final codec = await ui.instantiateImageCodec(bytes, targetWidth: 1400);
  final frame = await codec.getNextFrame();
  return frame.image;
}

/// The puzzle board is square, so we use the centre square of the picture.
ui.Rect squareCrop(ui.Image image) {
  final side = min(image.width, image.height).toDouble();
  return ui.Rect.fromLTWH((image.width - side) / 2, (image.height - side) / 2, side, side);
}
