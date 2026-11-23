import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../data/levels.dart';
import '../data/table_backgrounds.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/home_cards.dart';
import '../widgets/table_surface.dart';
import 'play_actions.dart';

/// Tab 1: all 50 levels. Level 1 is open; finishing a level opens the next one.
class LevelsTab extends StatelessWidget {
  const LevelsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = StorageService.instance;
    return ValueListenableBuilder<int>(
      valueListenable: storage.changes,
      builder: (context, _, __) {
        final background = backgroundById(storage.backgroundId);
        final onDark = background.isDark;
        final textColor = onDark ? Colors.white : AppColors.woodText;
        final saved = storage.savedGame;
        final done = storage.levelsDone;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: TableSurface(
                background: background,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(children: [
                          Avatar(photo: storage.avatar, name: storage.playerName, size: 44),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Hi, ${storage.playerName}',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor)),
                              Text('$done of $levelCount done, ${difficultyNames[storage.levelDifficulty]} mode',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor.withAlpha(200))),
                            ]),
                          ),
                          CoinBadge(amount: storage.coins),
                        ]),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: done / levelCount,
                            minHeight: 8,
                            color: onDark ? AppColors.coin : AppColors.teal,
                            backgroundColor: onDark ? const Color(0x33FFFFFF) : const Color(0x2E6B4A2B),
                          ),
                        ),
                        if (saved != null) ...[
                          const SizedBox(height: 16),
                          ContinueCard(saved: saved, onResume: () => PlayActions.continueSaved(context, saved)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            for (var chapter = 0; chapter < chapterNames.length; chapter++) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                sliver: SliverToBoxAdapter(child: _ChapterHeader(chapter: chapter)),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _LevelTile(level: chapter * levelsPerChapter + i + 1),
                    childCount: levelsPerChapter,
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
    );
  }
}

class _ChapterHeader extends StatelessWidget {
  final int chapter;
  const _ChapterHeader({required this.chapter});

  @override
  Widget build(BuildContext context) {
    final storage = StorageService.instance;
    final first = chapter * levelsPerChapter + 1;
    final finished = [for (var l = first; l < first + levelsPerChapter; l++) l].where((l) => storage.levelStars(l) > 0).length;
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Chapter ${chapter + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.inkSoft)),
          Text(chapterNames[chapter], style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
        ]),
      ),
      Text('$finished / $levelsPerChapter', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.inkSoft)),
    ]);
  }
}

int _pieces(int level, Difficulty mode) => gridFor(level, mode) * gridFor(level, mode);

/// One level: finished (picture + stars), next to play (highlighted), or locked.
class _LevelTile extends StatelessWidget {
  final int level;
  const _LevelTile({required this.level});

  @override
  Widget build(BuildContext context) {
    final storage = StorageService.instance;
    final unlocked = storage.isLevelUnlocked(level);
    final stars = storage.levelStars(level);
    final isNext = unlocked && stars == 0;
    final puzzle = levelPuzzle(level);

    return Semantics(
      button: true,
      label: unlocked ? 'Level $level, ${puzzle.title}' : 'Level $level, locked',
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (unlocked) {
              PlayActions.openLevel(context, level);
            } else {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text('Finish level ${level - 1} to open this one.')));
            }
          },
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isNext ? AppColors.teal : AppColors.line, width: isNext ? 2.5 : 1),
            ),
            child: Column(children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Stack(fit: StackFit.expand, children: [
                    if (unlocked)
                      PuzzleImage(puzzle: puzzle, thumbnail: true)
                    else
                      // Locked: a blurred, darkened hint of the picture.
                      ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                        child: PuzzleImage(puzzle: puzzle, thumbnail: true),
                      ),
                    if (!unlocked) ...[
                      const ColoredBox(color: Color(0x80241A10)),
                      const Center(child: Icon(Icons.lock_rounded, color: Colors.white, size: 26)),
                    ],
                    if (isNext)
                      const Center(
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.teal,
                          child: Icon(Icons.play_arrow_rounded, color: Colors.white),
                        ),
                      ),
                  ]),
                ),
              ),
              const SizedBox(height: 6),
              Row(children: [
                Text('$level', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                const Spacer(),
                if (stars > 0)
                  StarRow(stars: stars, size: 15)
                else
                  Text('${_pieces(level, storage.levelDifficulty)} pcs',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
