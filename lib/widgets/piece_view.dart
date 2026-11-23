import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../game/image_loader.dart';
import '../game/jigsaw_shape.dart';
import '../models/piece.dart';

/// Draws one piece: cuts the piece shape out of the full picture.
///
/// How it works:
/// 1. build the jigsaw outline (a Path),
/// 2. clipPath = "only paint inside this outline",
/// 3. draw the WHOLE picture, moved so that this piece's part lands under the outline.
class PiecePainter extends CustomPainter {
  final ui.Image image;
  final PieceEdges edges;
  final int row;
  final int col;
  final int rotation;
  final int gridSize;
  final double cellSize;
  final double elevation; // shadow size, bigger while the piece is lifted

  PiecePainter({
    required this.image,
    required this.edges,
    required this.row,
    required this.col,
    required this.rotation,
    required this.gridSize,
    required this.cellSize,
    required this.elevation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pad = cellSize * JigsawShape.tabRatio; // room for tabs around the cell

    canvas.save();

    // Turn the piece around its centre (90 degrees per rotation step).
    final centre = Offset(size.width / 2, size.height / 2);
    canvas.translate(centre.dx, centre.dy);
    canvas.rotate(rotation * pi / 2);
    canvas.translate(-centre.dx, -centre.dy);

    canvas.translate(pad, pad); // now (0,0) is the top-left corner of the cell
    final outline = JigsawShape.piecePath(edges, cellSize);

    if (elevation > 0) {
      canvas.drawShadow(outline, Colors.black, elevation, false);
    }

    canvas.save();
    canvas.clipPath(outline);
    final boardSide = cellSize * gridSize;
    final whereThePictureGoes = Rect.fromLTWH(-col * cellSize, -row * cellSize, boardSide, boardSide);
    canvas.drawImageRect(
      image,
      squareCrop(image),
      whereThePictureGoes,
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();

    // Thin light line so pieces look slightly raised, like cardboard.
    canvas.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x80FFFFFF),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(PiecePainter old) =>
      old.image != image ||
      old.rotation != rotation ||
      old.cellSize != cellSize ||
      old.elevation != elevation ||
      old.row != row ||
      old.col != col;
}

/// A widget showing one piece at full size (cell plus room for tabs).
class PieceView extends StatelessWidget {
  final ui.Image image;
  final Piece piece;
  final int gridSize;
  final double cellSize;
  final double elevation;

  const PieceView({
    super.key,
    required this.image,
    required this.piece,
    required this.gridSize,
    required this.cellSize,
    this.elevation = 0,
  });

  static double boxSize(double cellSize) => cellSize * (1 + 2 * JigsawShape.tabRatio);

  @override
  Widget build(BuildContext context) {
    final box = boxSize(cellSize);
    return SizedBox(
      width: box,
      height: box,
      child: CustomPaint(
        painter: PiecePainter(
          image: image,
          edges: piece.edges,
          row: piece.row,
          col: piece.col,
          rotation: piece.rotation,
          gridSize: gridSize,
          cellSize: cellSize,
          elevation: elevation,
        ),
      ),
    );
  }
}
