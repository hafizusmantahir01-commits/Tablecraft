import 'dart:math';
import 'dart:ui';

import '../models/piece.dart';

/// Creates the classic jigsaw shapes (tabs and blanks).
class JigsawShape {
  /// How far a tab sticks out, as a fraction of one cell.
  static const double tabRatio = 0.28;

  /// Decides the edge type of every piece.
  /// Two neighbours share one edge: if one has a tab there, the other gets a blank,
  /// so they always fit together. The [seed] makes the result repeatable.
  static List<List<PieceEdges>> generateEdges(int rows, int cols, int seed) {
    final random = Random(seed);

    // horizontal[r][c]: the line above row r, in column c. 1 = bump points down, -1 = up, 0 = border.
    final horizontal = List.generate(
      rows + 1,
      (r) => List.generate(cols, (c) => (r == 0 || r == rows) ? 0 : (random.nextBool() ? 1 : -1)),
    );
    // vertical[r][c]: the line left of column c, in row r. 1 = bump points right, -1 = left.
    final vertical = List.generate(
      rows,
      (r) => List.generate(cols + 1, (c) => (c == 0 || c == cols) ? 0 : (random.nextBool() ? 1 : -1)),
    );

    return List.generate(rows, (r) {
      return List.generate(cols, (c) {
        return PieceEdges(
          top: -horizontal[r][c], // bump pointing up = tab for this piece
          right: vertical[r][c + 1],
          bottom: horizontal[r + 1][c],
          left: -vertical[r][c],
        );
      });
    });
  }

  /// Control points of one tab, walking along an edge of length 1.
  /// First number = distance along the edge, second = how far it bulges out.
  static const _tab = <List<double>>[
    [0.36, 0], // straight part ends
    [0.40, 0], [0.42, 0.04], [0.39, 0.10], // neck goes in a little
    [0.34, 0.20], [0.40, 0.28], [0.50, 0.28], // left half of the round head
    [0.60, 0.28], [0.66, 0.20], [0.61, 0.10], // right half of the head
    [0.58, 0.04], [0.60, 0], [0.64, 0], // back down to the edge
  ];

  /// The outline of a piece. (0,0) is the top-left corner of its cell;
  /// tabs can go outside the cell (negative values or more than [size]).
  static Path piecePath(PieceEdges edges, double size) {
    final path = Path()..moveTo(0, 0);
    // Walk around clockwise: top, right, bottom, left.
    _addEdge(path, Offset.zero, const Offset(1, 0), const Offset(0, -1), size, edges.top);
    _addEdge(path, Offset(size, 0), const Offset(0, 1), const Offset(1, 0), size, edges.right);
    _addEdge(path, Offset(size, size), const Offset(-1, 0), const Offset(0, 1), size, edges.bottom);
    _addEdge(path, Offset(0, size), const Offset(0, -1), const Offset(-1, 0), size, edges.left);
    return path..close();
  }

  /// [direction] = which way we walk, [outside] = which way is "out" of the piece.
  static void _addEdge(Path path, Offset start, Offset direction, Offset outside, double length, int type) {
    // Converts (along, bulge) into a real point on the screen.
    Offset point(double along, double bulge) =>
        start + direction * (along * length) + outside * (bulge * length * type);

    if (type == 0) {
      final end = point(1, 0);
      path.lineTo(end.dx, end.dy);
      return;
    }

    final first = point(_tab[0][0], _tab[0][1]);
    path.lineTo(first.dx, first.dy);
    for (var i = 1; i < _tab.length; i += 3) {
      final a = point(_tab[i][0], _tab[i][1]);
      final b = point(_tab[i + 1][0], _tab[i + 1][1]);
      final c = point(_tab[i + 2][0], _tab[i + 2][1]);
      path.cubicTo(a.dx, a.dy, b.dx, b.dy, c.dx, c.dy);
    }
    final end = point(1, 0);
    path.lineTo(end.dx, end.dy);
  }
}
