import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../game/puzzle_controller.dart';
import '../models/piece.dart';
import '../services/game_feedback.dart';
import 'piece_view.dart';

/// The strip at the bottom holding pieces that are not on the board yet.
///
/// - Swipe left/right to scroll the tray.
/// - Drag a piece UP to pick it (Draggable with affinity: vertical,
///   so sideways swipes still scroll the list).
/// - Tap a piece to rotate it (when rotation is on).
class PieceTray extends StatelessWidget {
  final PuzzleController controller;
  final ui.Image image;
  final double cellSize;
  final double fingerLift; // the lifted piece floats a bit above the finger so it stays visible
  final bool onDark;

  const PieceTray({
    super.key,
    required this.controller,
    required this.image,
    required this.cellSize,
    required this.fingerLift,
    required this.onDark,
  });

  @override
  Widget build(BuildContext context) {
    final pieces = controller.trayPieces;
    final box = PieceView.boxSize(cellSize);
    final scale = min(1.0, 76 / box); // big pieces are shown smaller in the tray
    final itemSize = box * scale;

    return Container(
      height: itemSize + 40,
      decoration: BoxDecoration(
        color: onDark ? const Color(0x33000000) : const Color(0x216E461E),
        border: Border(top: BorderSide(color: onDark ? const Color(0x33FFFFFF) : const Color(0x406E461E))),
      ),
      child: pieces.isEmpty
          ? const SizedBox()
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: pieces.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final piece = pieces[index];
                return GestureDetector(
                  key: ValueKey(piece.id),
                  onTap: () => controller.rotate(piece),
                  child: Draggable<Piece>(
                    data: piece,
                    affinity: Axis.vertical,
                    // The drop position we get back is exactly where the finger is.
                    dragAnchorStrategy: pointerDragAnchorStrategy,
                    onDragStarted: GameFeedback.pick,
                    // While dragging: full-size piece, centred above the finger.
                    feedback: Transform.translate(
                      offset: Offset(-box / 2, -box / 2 - fingerLift),
                      child: PieceView(
                        image: image,
                        piece: piece,
                        gridSize: controller.gridSize,
                        cellSize: cellSize,
                        elevation: 8,
                      ),
                    ),
                    childWhenDragging: SizedBox(width: itemSize, height: itemSize),
                    child: SizedBox(
                      width: itemSize,
                      height: itemSize,
                      child: FittedBox(
                        child: PieceView(
                          image: image,
                          piece: piece,
                          gridSize: controller.gridSize,
                          cellSize: cellSize,
                          elevation: 2,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
