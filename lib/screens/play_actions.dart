import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/levels.dart';
import '../models/puzzle_info.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/difficulty_sheet.dart';
import '../widgets/level_mode_sheet.dart';
import 'game_screen.dart';

/// Starting a game from any tab goes through these functions,
/// so the rules (one saved game, continue instead of restart) live in one place.
class PlayActions {
  static StorageService get _storage => StorageService.instance;

  /// Level tapped: continue it if it was left unfinished, otherwise ask Easy / Medium / Hard first.
  static Future<void> openLevel(BuildContext context, int level) async {
    final puzzle = levelPuzzle(level);
    final saved = _storage.savedGame;
    if (saved != null && saved.puzzle.id == puzzle.id) {
      await continueSaved(context, saved);
      return;
    }
    final mode = await showLevelModeSheet(context, level);
    if (mode == null || !context.mounted) return;
    await _storage.setLevelDifficulty(mode); // remembered for next time
    if (!context.mounted) return;
    await _start(context, puzzle, gridFor(level, mode), rotationFor(mode));
  }

  static Future<void> openDaily(BuildContext context, DateTime day) async {
    if (!isDayOpen(day, DateTime.now())) return; // future days stay locked
    await _start(context, dailyPuzzle(day), dailyGridSize, false);
  }

  static Future<void> continueSaved(BuildContext context, SavedGame saved) {
    return Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GameScreen(
        puzzle: saved.puzzle,
        gridSize: saved.gridSize,
        rotationEnabled: saved.rotationEnabled,
        restore: saved,
      ),
    ));
  }

  /// "Create your own puzzle": pick a photo (gallery or camera), choose the size, play.
  static Future<void> createFromPhoto(BuildContext context, {ImageSource source = ImageSource.gallery}) async {
    final picked = await ImagePicker().pickImage(source: source, maxWidth: 2000);
    if (picked == null) return;
    final id = 'photo_${DateTime.now().millisecondsSinceEpoch}';
    // Phones: save a copy of the photo. Web: there are no files, so keep the bytes in memory.
    final puzzle = kIsWeb
        ? PuzzleInfo(id: id, title: 'My photo', category: 'Your photos', kind: PuzzleKind.photo, bytes: await picked.readAsBytes())
        : PuzzleInfo(id: id, title: 'My photo', category: 'Your photos', kind: PuzzleKind.photo, filePath: await _storage.keepPhoto(picked));
    if (!context.mounted) return;
    final choice = await showDifficultySheet(context, puzzle);
    if (choice == null || !context.mounted) return;
    await _start(context, puzzle, choice.gridSize, choice.rotate);
  }

  static Future<void> _start(BuildContext context, PuzzleInfo puzzle, int gridSize, bool rotate) async {
    final saved = _storage.savedGame;

    // Same puzzle already started: just continue it.
    if (saved != null && saved.puzzle.id == puzzle.id) {
      await continueSaved(context, saved);
      return;
    }
    // A different unfinished puzzle exists: only one can be saved, so ask first.
    if (saved != null) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppColors.cream,
          title: const Text('Start a new puzzle?'),
          content: Text('"${saved.puzzle.title}" is ${(saved.progress * 100).round()}% done. '
              'Starting a new puzzle replaces it.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Start new')),
          ],
        ),
      );
      if (replace != true) return;
      await _storage.clearSavedGame();
    }
    if (!context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GameScreen(puzzle: puzzle, gridSize: gridSize, rotationEnabled: rotate),
    ));
  }
}
