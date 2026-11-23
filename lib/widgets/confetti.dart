import 'dart:math';

import 'package:flutter/material.dart';

/// Colourful paper pieces falling from the top of the screen, drawn with code.
///
/// Each piece has its own start position, delay, speed, sway and spin.
/// One AnimationController runs from 0 to 1, and every frame the painter works out
/// where each piece is at that moment.
class ConfettiOverlay extends StatefulWidget {
  final int count;
  const ConfettiOverlay({super.key, this.count = 110});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3800),
  )..forward();

  late final List<_Bit> _bits = List.generate(widget.count, (i) => _Bit(Random(i * 31 + 7)));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // IgnorePointer: taps go through the confetti to the buttons underneath.
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(_bits, _controller.value),
          ),
        ),
      ),
    );
  }
}

class _Bit {
  static const _colors = [
    Color(0xFF1E6E68), Color(0xFFF2A93B), Color(0xFFE76F51), Color(0xFFE8669A),
    Color(0xFF4F9DD9), Color(0xFF5FB36B), Color(0xFFFFFDF8),
  ];

  final double x; // 0..1 across the screen
  final double delay; // 0..0.35 of the animation
  final double speed;
  final double sway; // how far it drifts left and right
  final double phase;
  final double spin;
  final double width;
  final double height;
  final bool round;
  final Color color;

  _Bit(Random r)
      : x = r.nextDouble(),
        delay = r.nextDouble() * 0.35,
        speed = 0.75 + r.nextDouble() * 0.5,
        sway = 0.02 + r.nextDouble() * 0.04,
        phase = r.nextDouble() * pi * 2,
        spin = (r.nextDouble() - 0.5) * 8,
        width = 6 + r.nextDouble() * 6,
        height = 9 + r.nextDouble() * 8,
        round = r.nextDouble() < 0.25,
        color = _colors[r.nextInt(_colors.length)];
}

class _ConfettiPainter extends CustomPainter {
  final List<_Bit> bits;
  final double progress; // 0 -> 1

  _ConfettiPainter(this.bits, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final bit in bits) {
      final t = ((progress - bit.delay) / (1 - bit.delay)).clamp(0.0, 1.0); // this piece's own time
      if (t == 0) continue;
      final dx = (bit.x + sin(t * 7 + bit.phase) * bit.sway) * size.width;
      final dy = (-0.05 + t * bit.speed * 1.15) * size.height;
      final fade = t > 0.8 ? (1 - t) / 0.2 : 1.0; // fade out at the end
      final paint = Paint()..color = bit.color.withAlpha((255 * fade).round());

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(bit.spin * t * 3);
      // Squash up and down like paper turning in the air.
      canvas.scale(1, cos(t * 12 + bit.phase).abs() * 0.8 + 0.2);
      if (bit.round) {
        canvas.drawCircle(Offset.zero, bit.width / 2, paint);
      } else {
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: bit.width, height: bit.height), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
