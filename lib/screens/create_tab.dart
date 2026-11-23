import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/levels.dart';
import '../data/table_backgrounds.dart';
import '../game/jigsaw_shape.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/table_surface.dart';
import 'play_actions.dart';

/// Tab 3: turn the player's own photo into a puzzle.
class CreateTab extends StatelessWidget {
  const CreateTab({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = StorageService.instance;
    return ValueListenableBuilder<int>(
      valueListenable: storage.changes,
      builder: (context, _, __) {
        final background = backgroundById(storage.backgroundId);
        final textColor = background.isDark ? Colors.white : AppColors.woodText;

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            TableSurface(
              background: background,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Create', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: textColor)),
                    Text('Make a puzzle from any photo',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor)),
                  ]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  // Example picture already cut into pieces, with one piece missing.
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(fit: StackFit.expand, children: [
                            PuzzleImage(puzzle: levelPuzzle(8)),
                            CustomPaint(painter: _JigsawOverlayPainter()),
                          ]),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Your photos, as puzzles', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  const Text(
                    'Family, pets, trips, anything. Pick a picture and choose how many pieces you want.',
                    style: TextStyle(fontSize: 15, height: 1.4, color: AppColors.inkSoft),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => PlayActions.createFromPhoto(context),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Choose from gallery'),
                  ),
                  if (!kIsWeb) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => PlayActions.createFromPhoto(context, source: ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Take a photo'),
                    ),
                  ],
                ]),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
              child: Text('How it works', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                _Step(number: 1, icon: Icons.image_outlined, text: 'Pick a photo'),
                SizedBox(width: 10),
                _Step(number: 2, icon: Icons.grid_view_rounded, text: 'Choose pieces'),
                SizedBox(width: 10),
                _Step(number: 3, icon: Icons.extension, text: 'Play'),
              ]),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.lightbulb_outline_rounded, size: 18, color: AppColors.inkSoft),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Photos with clear shapes and lots of colour make the best puzzles. The centre square of the photo is used.',
                    style: TextStyle(fontSize: 13, color: AppColors.inkSoft),
                  ),
                ),
              ]),
            ),
          ],
        );
      },
    );
  }
}

class _Step extends StatelessWidget {
  final int number;
  final IconData icon;
  final String text;
  const _Step({required this.number, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          CircleAvatar(radius: 20, backgroundColor: const Color(0xFFE2EFEC), child: Icon(icon, color: AppColors.teal)),
          const SizedBox(height: 8),
          Text('$number. $text', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }
}

/// Draws jigsaw lines over the example picture, with one piece missing.
class _JigsawOverlayPainter extends CustomPainter {
  static const _grid = 4;
  static const _missing = 6; // which piece is "taken out"

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / _grid;
    final edges = JigsawShape.generateEdges(_grid, _grid, 9);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xB3FFFFFF);
    for (var r = 0; r < _grid; r++) {
      for (var c = 0; c < _grid; c++) {
        final path = JigsawShape.piecePath(edges[r][c], cell).shift(Offset(c * cell, r * cell));
        if (r * _grid + c == _missing) {
          canvas.drawPath(path, Paint()..color = const Color(0x8C241A10));
        }
        canvas.drawPath(path, line);
      }
    }
  }

  @override
  bool shouldRepaint(_JigsawOverlayPainter oldDelegate) => false;
}
