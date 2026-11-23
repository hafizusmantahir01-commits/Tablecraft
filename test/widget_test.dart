import 'package:flutter_test/flutter_test.dart';
import 'package:tablecraft/data/levels.dart';
import 'package:tablecraft/game/jigsaw_shape.dart';
import 'package:tablecraft/game/puzzle_controller.dart';
import 'package:tablecraft/models/puzzle_info.dart';

void main() {
  test('neighbouring pieces always fit together', () {
    final edges = JigsawShape.generateEdges(6, 6, 42);
    for (var r = 0; r < 6; r++) {
      for (var c = 0; c < 6; c++) {
        if (c < 5) expect(edges[r][c].right, -edges[r][c + 1].left);
        if (r < 5) expect(edges[r][c].bottom, -edges[r + 1][c].top);
      }
    }
  });

  test('outer border pieces have flat sides', () {
    final edges = JigsawShape.generateEdges(4, 4, 1);
    expect(edges[0][2].top, 0);
    expect(edges[3][1].bottom, 0);
    expect(edges[2][0].left, 0);
    expect(edges[1][3].right, 0);
  });

  test('a piece snaps only when dropped near its spot', () {
    const puzzle = PuzzleInfo(id: 't', title: 'Test', category: 'Test', kind: PuzzleKind.photo, assetPath: 'x');
    final game = PuzzleController(puzzle: puzzle, gridSize: 3, rotationEnabled: false, seed: 5);
    final piece = game.pieces[4]; // middle piece, row 1 col 1
    expect(game.tryPlace(piece, const Offset(300, 300), 100), PlaceResult.wrongSpot);
    expect(game.tryPlace(piece, const Offset(110, 95), 100), PlaceResult.placed);
    expect(game.placedCount, 1);
    game.dispose();
  });

  test('levels grow slowly in every mode and stay in range', () {
    expect(gridFor(1, Difficulty.easy), 2);
    expect(gridFor(levelCount, Difficulty.easy), 6);
    expect(gridFor(1, Difficulty.medium), 3);
    expect(gridFor(levelCount, Difficulty.medium), 8);
    expect(gridFor(1, Difficulty.hard), 4);
    expect(gridFor(levelCount, Difficulty.hard), 10);
    for (final mode in Difficulty.values) {
      for (var l = 2; l <= levelCount; l++) {
        final step = gridFor(l, mode) - gridFor(l - 1, mode);
        expect(step == 0 || step == 1, isTrue); // never shrinks, never jumps by 2
      }
    }
  });

  test('every level has its own picture name', () {
    final names = {for (var l = 1; l <= levelCount; l++) levelTitle(l)};
    expect(names.length, levelCount);
    for (var l = 2; l <= levelCount; l++) {
      expect(levelTitle(l).split(' ').last == levelTitle(l - 1).split(' ').last, isFalse); // next scene is different
    }
  });

  test('daily puzzle is the same all day and changes the next day', () {
    final a = dailyPuzzle(DateTime(2026, 11, 22, 8));
    final b = dailyPuzzle(DateTime(2026, 11, 22, 23));
    final c = dailyPuzzle(DateTime(2026, 11, 23));
    expect(a.assetPath, b.assetPath);
    expect(a.assetPath == c.assetPath, isFalse);
    expect(a.dailyKey, '2026-11-22');
  });

  test('streak counts days in a row, also across a month end', () {
    final done = {'2026-11-29', '2026-11-30', '2026-12-01'};
    expect(currentStreak(done, DateTime(2026, 12, 1)), 3);
    expect(currentStreak(done, DateTime(2026, 12, 2)), 3); // today not played yet: still counts
    expect(currentStreak(done, DateTime(2026, 12, 3)), 0); // a day was missed
  });

  test('stars depend on hints used', () {
    expect(starsFor(0), 3);
    expect(starsFor(1), 2);
    expect(starsFor(4), 1);
  });

  test('daily week 1 starts on the install day, also across a month end', () {
    final installed = DateTime(2026, 11, 22);
    final week1 = weekOf(DateTime(2026, 11, 25), installed);
    expect(dayKey(week1.first), '2026-11-22');
    expect(dayKey(week1.last), '2026-11-28');
    expect(weekNumber(DateTime(2026, 11, 28), installed), 1);
    expect(weekNumber(DateTime(2026, 11, 29), installed), 2);
    final week2 = weekOf(DateTime(2026, 12, 1), installed);
    expect(dayKey(week2.first), '2026-11-29');
    expect(dayKey(week2.last), '2026-12-05');
  });

  test('future daily puzzles are locked', () {
    final now = DateTime(2026, 11, 25, 9);
    expect(isDayOpen(DateTime(2026, 11, 24), now), isTrue);
    expect(isDayOpen(DateTime(2026, 11, 25, 23), now), isTrue);
    expect(isDayOpen(DateTime(2026, 11, 26), now), isFalse);
  });
}
