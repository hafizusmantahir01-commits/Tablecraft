import 'package:flutter/material.dart';

import '../models/puzzle_info.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// What the player chose in the sheet.
class DifficultyChoice {
  final int gridSize;
  final bool rotate;
  const DifficultyChoice(this.gridSize, this.rotate);
}

/// Opens the "How many pieces?" sheet. Returns null if the player closes it.
Future<DifficultyChoice?> showDifficultySheet(BuildContext context, PuzzleInfo puzzle) {
  return showModalBottomSheet<DifficultyChoice>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cream,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => DifficultySheet(puzzle: puzzle),
  );
}

class DifficultySheet extends StatefulWidget {
  final PuzzleInfo puzzle;
  const DifficultySheet({super.key, required this.puzzle});

  @override
  State<DifficultySheet> createState() => _DifficultySheetState();
}

class _DifficultySheetState extends State<DifficultySheet> {
  // Grid sizes offered: 3x3 = 9 pieces ... 10x10 = 100 pieces.
  static const options = [3, 4, 6, 8, 10];
  static const estimates = {3: 'About 2 min', 4: 'About 4 min', 6: 'About 10 min', 8: 'About 18 min', 10: 'About 30 min'};

  int selected = 6;
  bool rotate = false;

  @override
  Widget build(BuildContext context) {
    final storage = StorageService.instance;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.puzzle.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.inkSoft)),
            const Text('How many pieces?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.05,
              children: [
                for (final n in options)
                  _OptionCard(
                    gridSize: n,
                    subtitle: storage.bestTime(widget.puzzle.id, n * n) != null
                        ? 'Best ${formatTime(storage.bestTime(widget.puzzle.id, n * n)!)}'
                        : estimates[n]!,
                    selected: n == selected,
                    onTap: () => setState(() => selected = n),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
              ),
              child: SwitchListTile(
                value: rotate,
                onChanged: (value) => setState(() => rotate = value),
                title: const Text('Rotate pieces', style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: const Text('Pieces start turned. Tap one to turn it.'),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(DifficultyChoice(selected, rotate)),
              child: Text('Start with ${selected * selected} pieces'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final int gridSize;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _OptionCard({required this.gridSize, required this.subtitle, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.teal : const Color(0xFF9C7C5A);
    return Material(
      color: selected ? const Color(0xFFE2EFEC) : AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? AppColors.teal : AppColors.line, width: selected ? 2.5 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 26, height: 26, child: CustomPaint(painter: _GridIconPainter(gridSize, color))),
            const SizedBox(height: 4),
            Text('${gridSize * gridSize}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            Text(subtitle, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
          ],
        ),
      ),
    );
  }
}

/// A little square divided into n x n cells, so the size is easy to see at a glance.
class _GridIconPainter extends CustomPainter {
  final int n;
  final Color color;
  _GridIconPainter(this.n, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(3)), paint);
    final step = size.width / n;
    for (var i = 1; i < n; i++) {
      canvas.drawLine(Offset(i * step, 0), Offset(i * step, size.height), paint..strokeWidth = 0.7);
      canvas.drawLine(Offset(0, i * step), Offset(size.width, i * step), paint);
    }
  }

  @override
  bool shouldRepaint(_GridIconPainter old) => old.n != n || old.color != color;
}
