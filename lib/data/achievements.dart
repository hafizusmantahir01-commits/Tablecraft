import 'package:flutter/material.dart';

/// Numbers about the player, read from storage. Achievements are checked against these.
class PlayerStats {
  final int solved; // all finished puzzles
  final int levelsDone;
  final int noHintSolves;
  final int maxPieces; // biggest puzzle finished
  final int photoSolves;
  final int bestStreak; // daily puzzles in a row
  final int coinsEarnedTotal;
  final bool fastSolve; // 25+ pieces in under 3 minutes
  final int perfectWeeks; // weeks with all 7 daily puzzles solved

  const PlayerStats({
    required this.solved,
    required this.levelsDone,
    required this.noHintSolves,
    required this.maxPieces,
    required this.photoSolves,
    required this.bestStreak,
    required this.coinsEarnedTotal,
    required this.fastSolve,
    required this.perfectWeeks,
  });
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int target;
  final int Function(PlayerStats stats) progressOf; // how far the player is

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.target,
    required this.progressOf,
  });

  int progress(PlayerStats s) => progressOf(s).clamp(0, target);
  bool isDone(PlayerStats s) => progressOf(s) >= target;
}

// Small named functions, because a const list cannot hold anonymous functions.
int _solved(PlayerStats s) => s.solved;
int _levels(PlayerStats s) => s.levelsDone;
int _noHint(PlayerStats s) => s.noHintSolves;
int _maxPieces(PlayerStats s) => s.maxPieces;
int _photo(PlayerStats s) => s.photoSolves;
int _streak(PlayerStats s) => s.bestStreak;
int _coins(PlayerStats s) => s.coinsEarnedTotal;
int _fast(PlayerStats s) => s.fastSolve ? 1 : 0;
int _perfectWeeks(PlayerStats s) => s.perfectWeeks;

const achievements = <Achievement>[
  Achievement(id: 'first', title: 'First puzzle', description: 'Finish your first puzzle', icon: Icons.extension, target: 1, progressOf: _solved),
  Achievement(id: 'ten', title: 'Getting good', description: 'Finish 10 puzzles', icon: Icons.emoji_events_outlined, target: 10, progressOf: _solved),
  Achievement(id: 'fifty', title: 'Puzzle lover', description: 'Finish 50 puzzles', icon: Icons.favorite_outline, target: 50, progressOf: _solved),
  Achievement(id: 'chapter', title: 'First chapter', description: 'Complete levels 1 to 10', icon: Icons.menu_book_outlined, target: 10, progressOf: _levels),
  Achievement(id: 'all_levels', title: 'Master of the table', description: 'Complete all 50 levels', icon: Icons.workspace_premium_outlined, target: 50, progressOf: _levels),
  Achievement(id: 'no_hint', title: 'No help needed', description: 'Finish a puzzle without hints', icon: Icons.lightbulb_outline, target: 1, progressOf: _noHint),
  Achievement(id: 'hundred', title: 'Hundred pieces', description: 'Finish a 100-piece puzzle', icon: Icons.grid_on_rounded, target: 100, progressOf: _maxPieces),
  Achievement(id: 'fast', title: 'Quick hands', description: '25 or more pieces in under 3 minutes', icon: Icons.bolt_rounded, target: 1, progressOf: _fast),
  Achievement(id: 'streak3', title: 'Three in a row', description: 'Solve the daily puzzle 3 days in a row', icon: Icons.local_fire_department_outlined, target: 3, progressOf: _streak),
  Achievement(id: 'streak7', title: 'Weekly habit', description: 'Solve the daily puzzle 7 days in a row', icon: Icons.calendar_month_outlined, target: 7, progressOf: _streak),
  Achievement(id: 'perfect_week', title: 'Perfect week', description: 'Solve all 7 daily puzzles of one week', icon: Icons.event_available_outlined, target: 1, progressOf: _perfectWeeks),
  Achievement(id: 'photo', title: 'My own picture', description: 'Finish a puzzle made from your photo', icon: Icons.photo_outlined, target: 1, progressOf: _photo),
  Achievement(id: 'coins', title: 'Coin collector', description: 'Earn 1000 coins in total', icon: Icons.savings_outlined, target: 1000, progressOf: _coins),
];
