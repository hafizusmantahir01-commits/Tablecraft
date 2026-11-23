/// The four sides of a jigsaw piece.
/// Each side is one of:  0 = flat (outer border),  1 = tab (sticks out),  -1 = blank (hole).
class PieceEdges {
  final int top;
  final int right;
  final int bottom;
  final int left;

  const PieceEdges({
    required this.top,
    required this.right,
    required this.bottom,
    required this.left,
  });

  /// A piece with at least one flat side belongs to the border of the picture.
  bool get isBorder => top == 0 || right == 0 || bottom == 0 || left == 0;
}

/// One piece of the puzzle.
class Piece {
  final int id;
  final int row; // where the piece belongs in the picture
  final int col;
  final PieceEdges edges;

  bool isPlaced = false; // true once it sits in its correct spot on the board
  int rotation; // quarter turns: 0, 1, 2 or 3 (0 = upright)

  Piece({
    required this.id,
    required this.row,
    required this.col,
    required this.edges,
    this.rotation = 0,
  });

  bool get isEdge => edges.isBorder;
}
