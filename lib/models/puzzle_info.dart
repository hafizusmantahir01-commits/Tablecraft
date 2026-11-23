import 'dart:typed_data';

/// Where a puzzle comes from. Decides what happens when it is finished.
enum PuzzleKind { level, daily, photo }

/// Describes one picture that can be played as a puzzle.
class PuzzleInfo {
  final String id;
  final String title;
  final String category;
  final PuzzleKind kind;
  final String? assetPath; // built-in picture shipped with the app
  final String? filePath; // gallery photo saved in the app's folder (file name only)
  final Uint8List? bytes; // gallery photo kept in memory (web cannot save files)
  final int? level; // 1..50 for level puzzles
  final String? dailyKey; // "2026-11-22" for daily puzzles

  const PuzzleInfo({
    required this.id,
    required this.title,
    required this.category,
    required this.kind,
    this.assetPath,
    this.filePath,
    this.bytes,
    this.level,
    this.dailyKey,
  });

  bool get isCustom => filePath != null || bytes != null;

  /// A photo that only lives in memory cannot be continued after the app closes.
  bool get canBeSaved => bytes == null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'kind': kind.name,
        'assetPath': assetPath,
        'filePath': filePath,
        'level': level,
        'dailyKey': dailyKey,
      };

  factory PuzzleInfo.fromJson(Map<String, dynamic> json) => PuzzleInfo(
        id: json['id'] as String,
        title: json['title'] as String,
        category: json['category'] as String,
        kind: PuzzleKind.values.byName(json['kind'] as String),
        assetPath: json['assetPath'] as String?,
        filePath: json['filePath'] as String?,
        level: json['level'] as int?,
        dailyKey: json['dailyKey'] as String?,
      );
}

/// Everything needed to continue an unfinished puzzle later.
class SavedGame {
  final PuzzleInfo puzzle;
  final int gridSize;
  final bool rotationEnabled;
  final int seed; // same seed = same piece shapes when we rebuild the puzzle
  final List<int> placedIds;
  final List<int> rotations;
  final int seconds;
  final int hintsLeft;
  final int hintsUsed;

  const SavedGame({
    required this.puzzle,
    required this.gridSize,
    required this.rotationEnabled,
    required this.seed,
    required this.placedIds,
    required this.rotations,
    required this.seconds,
    required this.hintsLeft,
    required this.hintsUsed,
  });

  double get progress => placedIds.length / (gridSize * gridSize);

  Map<String, dynamic> toJson() => {
        'puzzle': puzzle.toJson(),
        'gridSize': gridSize,
        'rotationEnabled': rotationEnabled,
        'seed': seed,
        'placedIds': placedIds,
        'rotations': rotations,
        'seconds': seconds,
        'hintsLeft': hintsLeft,
        'hintsUsed': hintsUsed,
      };

  factory SavedGame.fromJson(Map<String, dynamic> json) => SavedGame(
        puzzle: PuzzleInfo.fromJson(json['puzzle'] as Map<String, dynamic>),
        gridSize: json['gridSize'] as int,
        rotationEnabled: json['rotationEnabled'] as bool,
        seed: json['seed'] as int,
        placedIds: (json['placedIds'] as List).cast<int>(),
        rotations: (json['rotations'] as List).cast<int>(),
        seconds: json['seconds'] as int,
        hintsLeft: json['hintsLeft'] as int,
        hintsUsed: (json['hintsUsed'] as int?) ?? 0,
      );
}

/// What the "Puzzle complete" screen shows.
class GameResult {
  final PuzzleInfo puzzle;
  final int gridSize;
  final bool rotationEnabled;
  final int seconds;
  final int? bestSeconds;
  final bool isNewBest;
  final int coinsEarned;
  final int hintsUsed;
  final int stars; // 1 to 3, based on hints used
  final bool perfectWeek; // daily puzzle that finished the whole week
  final List<String> newAchievements; // titles unlocked by this game

  const GameResult({
    required this.puzzle,
    required this.gridSize,
    required this.rotationEnabled,
    required this.seconds,
    required this.bestSeconds,
    required this.isNewBest,
    required this.coinsEarned,
    required this.hintsUsed,
    required this.stars,
    required this.perfectWeek,
    required this.newAchievements,
  });

  int get pieceCount => gridSize * gridSize;
}
