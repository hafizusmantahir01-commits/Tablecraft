import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _steps = <(IconData, String, String)>[
    (Icons.grid_view_rounded, 'Pick a level', 'Start with level 1. Finish a level to open the next one. Every level is a new picture, and the puzzles grow slowly.'),
    (Icons.tune_rounded, 'Easy, Medium or Hard', 'Choose before each level. Easy has fewer, bigger pieces. Hard has the most pieces, and they start turned.'),
    (Icons.pan_tool_alt_outlined, 'Drag pieces up', 'Pieces wait in the tray at the bottom. Swipe sideways to look through them, drag one up onto the board.'),
    (Icons.check_circle_outline_rounded, 'Let it snap', 'Drop a piece close to its spot and it clicks into place. In the wrong spot it goes back to the tray.'),
    (Icons.crop_square_rounded, 'Edges first', 'Tap Edges to see only border pieces. Building the frame first makes the rest easier.'),
    (Icons.visibility_outlined, 'Peek at the picture', 'The eye button shows a faint copy of the picture under the board.'),
    (Icons.lightbulb_outline_rounded, 'Hints', 'Each puzzle has 3 free hints. A hint places one piece for you. After that, a hint costs 20 coins.'),
    (Icons.star_rounded, 'Stars', 'No hints gives 3 stars, one hint gives 2, more hints give 1. Play a level again to improve.'),
    (Icons.today_rounded, 'Daily puzzle', 'A new picture every day. Your week 1 starts on the day you installed the app. Coming days open on their date, missed days can still be played. Solve all 7 for 100 bonus coins.'),
    (Icons.add_photo_alternate_outlined, 'Your own photos', 'Open the Create tab, pick a photo from your gallery or take a new one, and choose how many pieces.'),
    (Icons.save_outlined, 'Stop any time', 'Leave a puzzle and it is saved. Continue it later from the Levels tab.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How to play', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: AppColors.cream,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        itemCount: _steps.length,
        separatorBuilder: (context, i) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final (icon, title, text) = _steps[i];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(radius: 20, backgroundColor: const Color(0xFFE2EFEC), child: Icon(icon, color: AppColors.teal, size: 22)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(text, style: const TextStyle(fontSize: 14, height: 1.4)),
                ]),
              ),
            ]),
          );
        },
      ),
    );
  }
}
