import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/levels.dart';
import '../data/table_backgrounds.dart';
import '../game/image_loader.dart';
import '../game/jigsaw_shape.dart';
import '../game/puzzle_controller.dart';
import '../models/piece.dart';
import '../models/puzzle_info.dart';
import '../services/game_feedback.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/board_view.dart';
import '../widgets/common.dart';
import '../widgets/piece_tray.dart';
import '../widgets/piece_view.dart';
import '../widgets/table_surface.dart';
import 'complete_screen.dart';

class GameScreen extends StatefulWidget {
  final PuzzleInfo puzzle;
  final int gridSize;
  final bool rotationEnabled;
  final SavedGame? restore; // not null when continuing an unfinished game

  const GameScreen({
    super.key,
    required this.puzzle,
    required this.gridSize,
    required this.rotationEnabled,
    this.restore,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

// WidgetsBindingObserver tells us when the app goes to the background.
class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  static const double fingerLift = 36;

  late final PuzzleController controller;
  final GlobalKey boardKey = GlobalKey();
  final TableBackground background = backgroundById(StorageService.instance.backgroundId);

  ui.Image? image;
  bool finished = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final saved = widget.restore;
    controller = PuzzleController(
      puzzle: widget.puzzle,
      gridSize: saved?.gridSize ?? widget.gridSize,
      rotationEnabled: saved?.rotationEnabled ?? widget.rotationEnabled,
      seed: saved?.seed ?? Random().nextInt(1 << 30),
    );
    if (saved != null) controller.restore(saved);

    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final loaded = await loadPuzzleImage(widget.puzzle);
      if (!mounted) return;
      setState(() => image = loaded);
      controller.startTimer();
    } catch (_) {
      if (!mounted) return;
      await StorageService.instance.clearSavedGame();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This picture could not be opened. Choose another puzzle.')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      controller.pauseTimer();
      _saveProgress();
    } else if (state == AppLifecycleState.resumed && image != null) {
      controller.startTimer();
    }
  }

  void _saveProgress() {
    if (finished || controller.isComplete || controller.placedCount == 0) return;
    if (!widget.puzzle.canBeSaved) return; // web photo: nothing on disk to come back to
    StorageService.instance.saveGame(controller.toSavedGame());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveProgress(); // leaving the screen (back button or gesture) saves the game
    controller.dispose();
    image?.dispose();
    super.dispose();
  }

  // ---------- dropping a piece ----------

  void _onDrop(Piece piece, Offset pointer, double cell) {
    final board = boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (board == null) return;

    // The finger is at the centre of the floating piece (a bit lower, see fingerLift).
    final box = PieceView.boxSize(cell);
    final pad = cell * JigsawShape.tabRatio;
    final pieceTopLeft = pointer - Offset(box / 2, box / 2 + fingerLift);
    final cellTopLeftOnBoard = board.globalToLocal(pieceTopLeft) + Offset(pad, pad);

    switch (controller.tryPlace(piece, cellTopLeftOnBoard, cell)) {
      case PlaceResult.placed:
        GameFeedback.snap();
        if (controller.isComplete) _finish();
      case PlaceResult.needsRotation:
        _toast('Almost. Tap the piece to turn it upright first.');
      case PlaceResult.wrongSpot:
        GameFeedback.miss();
    }
  }

  void _useHint() {
    if (controller.hintsLeft == 0) {
      _offerHintForCoins();
      return;
    }
    if (controller.useHint() != null) {
      GameFeedback.hint();
      if (controller.isComplete) _finish();
    }
  }

  /// Free hints are used up: the player can buy one with coins.
  void _offerHintForCoins() {
    final storage = StorageService.instance;
    const price = StorageService.hintPrice;
    if (storage.coins < price) {
      _toast('No hints left. You need $price coins to buy one.');
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('No free hints left. Buy one for $price coins? You have ${storage.coins}.'),
        action: SnackBarAction(
          label: 'Buy',
          onPressed: () async {
            if (await storage.spendCoins(price)) {
              controller.addHint();
              _useHint();
            }
          },
        ),
      ));
  }

  Future<void> _finish() async {
    if (finished) return;
    finished = true;

    final record = await StorageService.instance.recordWin(
      puzzle: widget.puzzle,
      pieceCount: controller.total,
      seconds: controller.seconds,
      hintsUsed: controller.hintsUsed,
      coinsEarned: controller.coinsEarned,
    );

    final result = GameResult(
      puzzle: widget.puzzle,
      gridSize: controller.gridSize,
      rotationEnabled: controller.rotationEnabled,
      seconds: controller.seconds,
      bestSeconds: record.bestSeconds,
      isNewBest: record.isNewBest,
      coinsEarned: controller.coinsEarned,
      hintsUsed: controller.hintsUsed,
      stars: starsFor(controller.hintsUsed),
      perfectWeek: record.perfectWeek,
      newAchievements: [for (final a in record.newAchievements) a.title],
    );

    // Let the player see the finished picture for a moment.
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => CompleteScreen(result: result)),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final appWidth = min(screen.width, kMaxAppWidth); // the app is centred on wide screens
    final boardSide = min(appWidth - 40, screen.height * 0.5);
    final cell = boardSide / controller.gridSize;
    final onDark = background.isDark;
    final textColor = onDark ? Colors.white : AppColors.ink;

    return Scaffold(
      body: TableSurface(
        background: background,
        child: SafeArea(
          bottom: false,
          child: image == null
              ? Center(child: CircularProgressIndicator(color: textColor))
              : AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) {
                    return Column(
                      children: [
                        _topBar(textColor, onDark),
                        Expanded(
                          child: Center(
                            child: BoardView(
                              controller: controller,
                              image: image!,
                              side: boardSide,
                              boardKey: boardKey,
                              onDrop: (piece, pointer) => _onDrop(piece, pointer, cell),
                            ),
                          ),
                        ),
                        _toolbar(onDark),
                        const SizedBox(height: 12),
                        PieceTray(
                          controller: controller,
                          image: image!,
                          cellSize: cell,
                          fingerLift: fingerLift,
                          onDark: onDark,
                        ),
                        SizedBox(height: MediaQuery.paddingOf(context).bottom),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _topBar(Color textColor, bool onDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          RoundIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Back to puzzles',
            onDark: onDark,
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.puzzle.title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor),
                      ),
                    ),
                    Text(
                      '${controller.placedCount} / ${controller.total}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: controller.progress,
                    minHeight: 6,
                    color: onDark ? AppColors.coin : AppColors.teal,
                    backgroundColor: onDark ? const Color(0x33FFFFFF) : const Color(0x2E6B4A2B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          RoundIconButton(
            icon: Icons.visibility_outlined,
            tooltip: 'Show picture under the board',
            onDark: onDark,
            active: controller.showGhost,
            onTap: controller.toggleGhost,
          ),
        ],
      ),
    );
  }

  Widget _toolbar(bool onDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ToolChip(
          icon: Icons.crop_square_rounded,
          label: 'Edges',
          selected: controller.edgesOnly,
          onDark: onDark,
          onTap: controller.toggleEdgesOnly,
        ),
        const SizedBox(width: 8),
        _ToolChip(icon: Icons.timer_outlined, label: controller.timeLabel, onDark: onDark),
        const SizedBox(width: 8),
        _ToolChip(
          icon: Icons.lightbulb_outline_rounded,
          label: 'Hint ${controller.hintsLeft}',
          onDark: onDark,
          onTap: _useHint,
        ),
      ],
    );
  }
}

class _ToolChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final bool onDark;

  const _ToolChip({
    required this.icon,
    required this.label,
    required this.onDark,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : (onDark ? Colors.white : AppColors.ink);
    final bg = selected ? AppColors.teal : (onDark ? const Color(0x24FFFFFF) : const Color(0xD9FFFAF0));
    return Material(
      color: bg,
      shape: StadiumBorder(side: BorderSide(color: onDark ? const Color(0x38FFFFFF) : const Color(0x4D6B4A2B))),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: fg)),
          ]),
        ),
      ),
    );
  }
}
