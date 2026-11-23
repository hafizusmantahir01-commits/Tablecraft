import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../game/jigsaw_shape.dart';
import '../game/puzzle_controller.dart';
import '../models/piece.dart';
import '../theme/app_theme.dart';
import 'piece_view.dart';

/// The square board. It accepts dropped pieces (DragTarget) and draws the placed ones.
class BoardView extends StatelessWidget {
  final PuzzleController controller;
  final ui.Image image;
  final double side;
  final GlobalKey boardKey; // lets the game screen find the board's position on screen
  final void Function(Piece piece, Offset pointer) onDrop;

  const BoardView({
    super.key,
    required this.controller,
    required this.image,
    required this.side,
    required this.boardKey,
    required this.onDrop,
  });

  @override
  Widget build(BuildContext context) {
    final cell = side / controller.gridSize;
    final pad = cell * JigsawShape.tabRatio;

    return DragTarget<Piece>(
      onAcceptWithDetails: (details) => onDrop(details.data, details.offset),
      builder: (context, candidates, rejected) {
        final hovering = candidates.isNotEmpty;
        return RepaintBoundary(
          child: SizedBox(
            key: boardKey,
            width: side,
            height: side,
            child: Stack(
              clipBehavior: Clip.none, // tabs on the border may stick out a little
              children: [
                // The empty "well" where pieces go.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0x26000000),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                if (controller.showGhost)
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.25,
                      child: RawImage(image: image, fit: BoxFit.cover),
                    ),
                  ),
                for (final piece in controller.pieces)
                  if (piece.isPlaced)
                    Positioned(
                      key: ValueKey(piece.id), // keeps each piece's animation tied to that piece
                      left: piece.col * cell - pad,
                      top: piece.row * cell - pad,
                      child: IgnorePointer(
                        child: _SnapIn(
                          child: PieceView(image: image, piece: piece, gridSize: controller.gridSize, cellSize: cell),
                        ),
                      ),
                    ),
                // Outline that lights up while a piece is dragged over the board.
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: hovering ? AppColors.teal : const Color(0x33000000),
                          width: hovering ? 2.5 : 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Small "pop" when a piece clicks into place.
class _SnapIn extends StatelessWidget {
  final Widget child;
  const _SnapIn({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.12, end: 1.0),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: child,
    );
  }
}
