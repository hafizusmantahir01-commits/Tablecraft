import 'dart:math';

import 'package:flutter/material.dart';

import '../data/table_backgrounds.dart';

/// Draws a table texture (wood, felt, linen...) with code instead of images,
/// so the app stays small and the texture fits any screen size.
class TableSurfacePainter extends CustomPainter {
  final TableBackground background;

  TableSurfacePainter(this.background);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background.base);

    final line = Paint()
      ..color = background.grain
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final random = Random(7); // fixed seed: the grain looks the same every time

    switch (background.pattern) {
      case TexturePattern.wood:
        // Long vertical lines of random thickness, slightly bent, like wood grain.
        var x = 0.0;
        while (x < size.width) {
          line.strokeWidth = 0.6 + random.nextDouble() * 1.8;
          final bend = random.nextDouble() * 8 - 4;
          final grain = Path()
            ..moveTo(x, 0)
            ..quadraticBezierTo(x + bend, size.height / 2, x, size.height);
          canvas.drawPath(grain, line);
          x += 3 + random.nextDouble() * 9;
        }
      case TexturePattern.crosshatch:
        // Fine diagonal lines, like felt or denim.
        for (var d = -size.height; d < size.width; d += 4) {
          canvas.drawLine(Offset(d, 0), Offset(d + size.height, size.height), line);
        }
      case TexturePattern.weave:
        // A tiny grid, like linen cloth.
        for (var y = 0.0; y < size.height; y += 3) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
        }
        for (var x = 0.0; x < size.width; x += 3) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
        }
    }
  }

  @override
  bool shouldRepaint(TableSurfacePainter oldDelegate) => oldDelegate.background.id != background.id;
}

/// A widget that puts [child] on top of a table texture.
class TableSurface extends StatelessWidget {
  final TableBackground background;
  final Widget child;

  const TableSurface({super.key, required this.background, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      // RepaintBoundary: the texture is drawn once and reused while pieces move.
      painter: TableSurfacePainter(background),
      child: RepaintBoundary(child: child),
    );
  }
}
