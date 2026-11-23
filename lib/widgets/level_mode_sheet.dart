import 'package:flutter/material.dart';

import '../data/levels.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

/// Asks Easy / Medium / Hard before a level. Returns null if the player closes the sheet.
Future<Difficulty?> showLevelModeSheet(BuildContext context, int level) {
  return showModalBottomSheet<Difficulty>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cream,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => _LevelModeSheet(level: level),
  );
}

class _LevelModeSheet extends StatefulWidget {
  final int level;
  const _LevelModeSheet({required this.level});

  @override
  State<_LevelModeSheet> createState() => _LevelModeSheetState();
}

class _LevelModeSheetState extends State<_LevelModeSheet> {
  late Difficulty selected = StorageService.instance.levelDifficulty; // last choice

  static const _icons = {
    Difficulty.easy: Icons.spa_outlined,
    Difficulty.medium: Icons.balance_rounded,
    Difficulty.hard: Icons.local_fire_department_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final level = widget.level;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Level $level, ${levelTitle(level)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.inkSoft)),
            const Text('How hard?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            for (final d in Difficulty.values) ...[
              _ModeCard(
                icon: _icons[d]!,
                name: difficultyNames[d]!,
                hint: difficultyHints[d]!,
                pieces: gridFor(level, d) * gridFor(level, d),
                selected: d == selected,
                onTap: () => setState(() => selected = d),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 6),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(selected),
              child: Text('Play level $level'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final String hint;
  final int pieces;
  final bool selected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.name,
    required this.hint,
    required this.pieces,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFE2EFEC) : AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? AppColors.teal : AppColors.line, width: selected ? 2.5 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: selected ? AppColors.teal : AppColors.line,
              child: Icon(icon, color: selected ? Colors.white : AppColors.inkSoft),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                Text(hint, style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
              ]),
            ),
            Text('$pieces pieces', style: const TextStyle(fontWeight: FontWeight.w900)),
          ]),
        ),
      ),
    );
  }
}
