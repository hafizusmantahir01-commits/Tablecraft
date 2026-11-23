import 'package:flutter/material.dart';

import '../game/jigsaw_shape.dart';
import '../models/piece.dart';

/// The Tablecraft piece drawn with depth, so it looks like a real 3D game piece.
///
/// Tricks used (all plain 2D drawing):
/// - the same shape drawn many times, 1 pixel lower each time, in a darker color = the thick side
/// - a gradient on the top face = light falling from the top-left
/// - a light band on the top-left edges and a dark band on the bottom-right edges = bevelled edges
/// - a soft white oval = shine
class Logo3D extends StatelessWidget {
  final double size;
  const Logo3D({super.key, this.size = 150});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size, child: CustomPaint(painter: _Logo3DPainter()));
  }
}

class _Logo3DPainter extends CustomPainter {
  static const _edges = PieceEdges(top: 1, right: 1, bottom: -1, left: -1);

  @override
  void paint(Canvas canvas, Size size) {
    final depth = size.width * 0.07;
    final cell = (size.width - depth) / (1 + 2 * JigsawShape.tabRatio);
    final pad = cell * JigsawShape.tabRatio;
    final face = JigsawShape.piecePath(_edges, cell).shift(Offset(pad, pad));

    // Shadow on the table.
    canvas.drawShadow(face.shift(Offset(0, depth)), Colors.black, depth * 1.2, false);

    // Thick side: stack of darker copies.
    final side = Paint()..color = const Color(0xFF0E4743);
    for (var i = depth; i > 0; i -= 1) {
      canvas.drawPath(face.shift(Offset(0, i)), side);
    }

    // Top face with light from the top-left.
    final bounds = face.getBounds();
    canvas.drawPath(
      face,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF47AFA5), Color(0xFF1E6E68), Color(0xFF165955)],
          stops: [0, 0.55, 1],
        ).createShader(bounds),
    );

    // Bevel: only paint inside the piece.
    canvas.save();
    canvas.clipPath(face);
    final bevel = depth * 0.7;
    canvas.drawPath(
      face.shift(Offset(bevel * 0.5, bevel * 0.5)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = bevel
        ..color = const Color(0x40FFFFFF),
    );
    canvas.drawPath(
      face.shift(Offset(-bevel * 0.5, -bevel * 0.5)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = bevel
        ..color = const Color(0x33000000),
    );
    // Shine.
    canvas.drawOval(
      Rect.fromLTWH(bounds.left + bounds.width * 0.18, bounds.top + bounds.height * 0.2, bounds.width * 0.38, bounds.height * 0.2),
      Paint()
        ..color = const Color(0x2EFFFFFF)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, depth * 0.6),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Logo3DPainter oldDelegate) => false;
}
