import 'dart:async';
import 'dart:math';
import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';

import '../models/piece.dart';
import '../models/puzzle_info.dart';
import 'jigsaw_shape.dart';

/// What happened when the player dropped a piece on the board.
enum PlaceResult { placed, wrongSpot, needsRotation }

/// The "brain" of one game: pieces, timer, hints and the rules.
/// It has no UI code. When something changes it calls notifyListeners()
/// and the screen rebuilds itself.
class PuzzleController extends ChangeNotifier {
  final PuzzleInfo puzzle;
  final int gridSize; // 6 means a 6 x 6 puzzle = 36 pieces
  final bool rotationEnabled;
  final int seed;

  late final List<Piece> pieces;
  late final List<Piece> _trayOrder; // shuffled order shown in the tray

  int seconds = 0;
  int hintsLeft = 3;
  bool showGhost = false; // faint picture under the board
  bool edgesOnly = false; // tray shows only border pieces

  Timer? _timer;
  int _hintsUsed = 0; // counted separately, because bought hints raise hintsLeft

  static const int startingHints = 3;

  PuzzleController({
    required this.puzzle,
    required this.gridSize,
    required this.rotationEnabled,
    required this.seed,
  }) {
    final edges = JigsawShape.generateEdges(gridSize, gridSize, seed);
    final random = Random(seed);
    pieces = [
      for (var r = 0; r < gridSize; r++)
        for (var c = 0; c < gridSize; c++)
          Piece(
            id: r * gridSize + c,
            row: r,
            col: c,
            edges: edges[r][c],
            rotation: rotationEnabled ? random.nextInt(4) : 0,
          ),
    ];
    _trayOrder = List.of(pieces)..shuffle(random);
  }

  /// Puts back the state of a game the player left earlier.
  void restore(SavedGame saved) {
    for (final piece in pieces) {
      piece.isPlaced = saved.placedIds.contains(piece.id);
      if (piece.id < saved.rotations.length) piece.rotation = saved.rotations[piece.id];
    }
    seconds = saved.seconds;
    hintsLeft = saved.hintsLeft;
    _hintsUsed = saved.hintsUsed;
  }

  // ---------- read-only info for the UI ----------

  int get total => pieces.length;
  int get placedCount => pieces.where((p) => p.isPlaced).length;
  bool get isComplete => placedCount == total;
  double get progress => placedCount / total;
  int get hintsUsed => _hintsUsed;

  /// Pieces still waiting in the tray (filtered when "Edges" is on).
  List<Piece> get trayPieces {
    final waiting = _trayOrder.where((p) => !p.isPlaced).toList();
    if (!edgesOnly) return waiting;
    final edges = waiting.where((p) => p.isEdge).toList();
    return edges.isEmpty ? waiting : edges; // border finished: show the rest
  }

  /// Bigger puzzles give more coins; no hints gives a bonus.
  int get coinsEarned => total ~/ 2 + 20 + (hintsUsed == 0 ? 15 : 0);

  String get timeLabel {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  // ---------- timer ----------

  void startTimer() {
    if (isComplete) return;
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      seconds++;
      notifyListeners();
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // ---------- player actions ----------

  void rotate(Piece piece) {
    if (!rotationEnabled || piece.isPlaced) return;
    piece.rotation = (piece.rotation + 1) % 4;
    notifyListeners();
  }

  /// [droppedAt] = where the top-left of the piece's cell landed, in board coordinates.
  /// If it is close enough to the right spot, the piece snaps in.
  PlaceResult tryPlace(Piece piece, Offset droppedAt, double cellSize) {
    final correctSpot = Offset(piece.col * cellSize, piece.row * cellSize);
    final distance = (droppedAt - correctSpot).distance;
    if (distance > cellSize * 0.4) return PlaceResult.wrongSpot;
    if (piece.rotation != 0) return PlaceResult.needsRotation;

    piece.isPlaced = true;
    if (isComplete) pauseTimer();
    notifyListeners();
    return PlaceResult.placed;
  }

  /// Places one piece for the player. Border pieces first, like a real player would.
  Piece? useHint() {
    if (hintsLeft == 0) return null;
    final waiting = _trayOrder.where((p) => !p.isPlaced).toList();
    if (waiting.isEmpty) return null;
    final piece = waiting.firstWhere((p) => p.isEdge, orElse: () => waiting.first);
    piece
      ..rotation = 0
      ..isPlaced = true;
    hintsLeft--;
    _hintsUsed++;
    if (isComplete) pauseTimer();
    notifyListeners();
    return piece;
  }

  /// Called after the player buys a hint with coins.
  void addHint() {
    hintsLeft++;
    notifyListeners();
  }

  void toggleGhost() {
    showGhost = !showGhost;
    notifyListeners();
  }

  void toggleEdgesOnly() {
    edgesOnly = !edgesOnly;
    notifyListeners();
  }

  SavedGame toSavedGame() => SavedGame(
        puzzle: puzzle,
        gridSize: gridSize,
        rotationEnabled: rotationEnabled,
        seed: seed,
        placedIds: [for (final p in pieces) if (p.isPlaced) p.id],
        rotations: [for (final p in pieces) p.rotation],
        seconds: seconds,
        hintsLeft: hintsLeft,
        hintsUsed: _hintsUsed,
      );

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
