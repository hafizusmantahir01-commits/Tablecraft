import 'package:flutter/material.dart';

import '../data/levels.dart';
import '../data/table_backgrounds.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/table_surface.dart';

class BackgroundsScreen extends StatefulWidget {
  const BackgroundsScreen({super.key});

  @override
  State<BackgroundsScreen> createState() => _BackgroundsScreenState();
}

class _BackgroundsScreenState extends State<BackgroundsScreen> {
  late String selectedId = StorageService.instance.backgroundId;

  @override
  Widget build(BuildContext context) {
    final background = backgroundById(selectedId);

    return Scaffold(
      body: Column(
        children: [
          // Live preview: the whole top half shows the chosen table.
          Expanded(
            child: TableSurface(
              background: background,
              child: SafeArea(
                bottom: false,
                child: Stack(children: [
                  Positioned(
                    top: 12,
                    left: 20,
                    child: RoundIconButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: 'Back',
                      onDark: background.isDark,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Center(
                    child: Transform.rotate(
                      angle: -0.04,
                      child: Container(
                        width: 190,
                        height: 190,
                        decoration: const BoxDecoration(
                          boxShadow: [BoxShadow(color: Color(0x59000000), blurRadius: 12, offset: Offset(0, 6))],
                        ),
                        child: PuzzleImage(puzzle: levelPuzzle(12)),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Table background', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 14),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.95,
                      children: [
                        for (final b in tableBackgrounds)
                          _Swatch(
                            background: b,
                            selected: b.id == selectedId,
                            onTap: () => setState(() => selectedId = b.id),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () async {
                        await StorageService.instance.setBackground(selectedId);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      child: const Text('Use this background'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final TableBackground background;
  final bool selected;
  final VoidCallback onTap;
  const _Swatch({required this.background, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: background.name,
      child: GestureDetector(
        onTap: onTap,
        child: Column(children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: EdgeInsets.all(selected ? 3 : 1),
              decoration: BoxDecoration(
                color: selected ? AppColors.teal : AppColors.line,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(selected ? 11 : 13),
                child: CustomPaint(painter: TableSurfacePainter(background), child: const SizedBox.expand()),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(background.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }
}
