import 'package:flutter/material.dart';

import '../models/puzzle_info.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// Shown when there is an unfinished puzzle.
class ContinueCard extends StatelessWidget {
  final SavedGame saved;
  final VoidCallback onResume;
  const ContinueCard({super.key, required this.saved, required this.onResume});

  String get _label => switch (saved.puzzle.kind) {
        PuzzleKind.level => 'Continue level ${saved.puzzle.level}',
        PuzzleKind.daily => 'Continue daily puzzle',
        PuzzleKind.photo => 'Continue your photo puzzle',
      };

  @override
  Widget build(BuildContext context) {
    final percent = (saved.progress * 100).round();
    return _Panel(
      onTap: onResume,
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(width: 72, height: 72, child: PuzzleImage(puzzle: saved.puzzle, thumbnail: true)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.inkSoft)),
            Text(saved.puzzle.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: saved.progress,
                    minHeight: 6,
                    color: AppColors.teal,
                    backgroundColor: AppColors.line,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('$percent%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
            ]),
          ]),
        ),
        const SizedBox(width: 12),
        IconButton.filled(
          onPressed: onResume,
          tooltip: 'Resume ${saved.puzzle.title}',
          style: IconButton.styleFrom(backgroundColor: AppColors.teal, minimumSize: const Size(48, 48)),
          icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
        ),
      ]),
    );
  }
}

/// "Create your own puzzle from a photo".
class PhotoPuzzleCard extends StatelessWidget {
  final VoidCallback onTap;
  const PhotoPuzzleCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Row(children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Color(0xFFE2EFEC),
              child: Icon(Icons.add_photo_alternate_outlined, color: AppColors.teal),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Create your own puzzle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                Text('Pick any photo from your gallery',
                    style: TextStyle(fontSize: 13, color: AppColors.inkSoft)),
              ]),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.inkSoft),
          ]),
        ),
      ),
    );
  }
}

/// Cream rounded panel used on top of the wood header.
class _Panel extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _Panel({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      elevation: 1,
      shadowColor: const Color(0x666E461E),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(12), child: child),
      ),
    );
  }
}
