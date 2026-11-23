import 'package:flutter/material.dart';

import '../data/levels.dart';
import '../data/table_backgrounds.dart';
import '../models/puzzle_info.dart';
import '../services/game_feedback.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/confetti.dart';
import '../widgets/table_surface.dart';
import 'game_screen.dart';

class CompleteScreen extends StatelessWidget {
  final GameResult result;
  const CompleteScreen({super.key, required this.result});

  int? get _nextLevel {
    final level = result.puzzle.level;
    if (result.puzzle.kind != PuzzleKind.level || level == null || level >= levelCount) return null;
    return level + 1;
  }

  /// Next level in the same mode (Easy / Medium / Hard) the player chose last.
  void _openNextLevel(BuildContext context, int level) {
    final mode = StorageService.instance.levelDifficulty;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => GameScreen(puzzle: levelPuzzle(level), gridSize: gridFor(level, mode), rotationEnabled: rotationFor(mode)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final background = backgroundById(StorageService.instance.backgroundId);
    final textColor = background.isDark ? Colors.white : AppColors.woodText;
    final next = _nextLevel;
    final title = switch (result.puzzle.kind) {
      PuzzleKind.level => 'Level ${result.puzzle.level} complete!',
      PuzzleKind.daily => 'Daily puzzle done!',
      PuzzleKind.photo => 'Puzzle complete!',
    };

    return Scaffold(
      body: Stack(children: [
        TableSurface(
        background: background,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // "Congratulations!" pops in with a little bounce.
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.4, end: 1),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                  child: Text('Congratulations!',
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: textColor)),
                ),
                Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textColor)),
                Text(
                  '${result.puzzle.title}, ${result.pieceCount} pieces',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
                ),
                const SizedBox(height: 8),
                StarRow(stars: result.stars, size: 34),
                if (result.isNewBest) ...[
                  const SizedBox(height: 8),
                  const Center(child: _Chip(text: 'New best time', color: AppColors.coin)),
                ],
                const SizedBox(height: 12),
                // The finished picture in a white mat, slightly tilted like a real photo.
                Expanded(
                  child: Center(
                    child: Transform.rotate(
                      angle: -0.025,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppColors.card,
                          boxShadow: [BoxShadow(color: Color(0x47502D0A), blurRadius: 14, offset: Offset(0, 6))],
                        ),
                        child: AspectRatio(aspectRatio: 1, child: PuzzleImage(puzzle: result.puzzle)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  _Stat(label: 'Time', value: formatTime(result.seconds)),
                  const SizedBox(width: 10),
                  _Stat(label: 'Your best', value: result.bestSeconds == null ? '-' : formatTime(result.bestSeconds!)),
                  const SizedBox(width: 10),
                  _Stat(label: 'Coins', value: '+${result.coinsEarned}'),
                ]),
                if (result.perfectWeek) ...[
                  const SizedBox(height: 8),
                  _Banner(icon: Icons.event_available_rounded, text: 'Perfect week! +$perfectWeekBonus bonus coins'),
                ],
                // New achievements, shown once.
                for (final name in result.newAchievements) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [
                      const Icon(Icons.emoji_events_rounded, color: AppColors.coin),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('Achievement unlocked: $name',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                      ),
                    ]),
                  ),
                ],
                const SizedBox(height: 14),
                if (next != null) ...[
                  FilledButton(onPressed: () => _openNextLevel(context, next), child: Text('Next: level $next')),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(backgroundColor: const Color(0x99FFFAF0)),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back to levels'),
                  ),
                ] else
                  FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done')),
              ],
            ),
          ),
        ),
      ),
        // Confetti and the winning sound on top of everything.
        const Positioned.fill(child: _Celebration()),
      ]),
    );
  }
}

/// Plays the win sound once and shows falling confetti.
class _Celebration extends StatefulWidget {
  const _Celebration();

  @override
  State<_Celebration> createState() => _CelebrationState();
}

class _CelebrationState extends State<_Celebration> {
  @override
  void initState() {
    super.initState();
    GameFeedback.win();
  }

  @override
  Widget build(BuildContext context) => const ConfettiOverlay();
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Banner({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: AppColors.coin, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Icon(icon, color: AppColors.ink),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900))),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color color;
  const _Chip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.inkSoft)),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        ]),
      ),
    );
  }
}
