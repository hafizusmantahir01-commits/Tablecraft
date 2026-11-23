import 'dart:math';

import 'package:flutter/material.dart';

import '../data/table_backgrounds.dart';
import '../theme/app_theme.dart';
import '../widgets/logo_3d.dart';
import '../widgets/table_surface.dart';
import 'main_shell.dart';

/// First screen: the 3D logo spins in, the name slides up, then the main screen fades in.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 2400), _goToMain);
  }

  void _goToMain() {
    if (!mounted) return;
    // pushReplacement: the splash is removed, so Back on the main screen closes the app.
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondary) => const MainShell(),
      transitionsBuilder: (context, animation, secondary, child) => FadeTransition(opacity: animation, child: child),
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Logo uses the first 70% of the animation, the text the last half.
    final logoPart = CurvedAnimation(parent: _controller, curve: const Interval(0, 0.7));
    final textPart = CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1, curve: Curves.easeOut));

    return Scaffold(
      body: TableSurface(
        background: backgroundById('oak'),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: logoPart,
                builder: (context, child) {
                  final t = logoPart.value; // 0 -> 1
                  final turn = 1 - Curves.easeOutCubic.transform(t); // 1 -> 0: spinning slows down
                  final grow = Curves.easeOutBack.transform(t); // overshoots a little, then settles
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0012) // perspective: far side looks smaller
                      ..rotateY(turn * pi)
                      ..rotateX(turn * 0.4),
                    child: Transform.scale(scale: 0.5 + 0.5 * grow, child: child),
                  );
                },
                child: const Logo3D(size: 150),
              ),
              const SizedBox(height: 28),
              FadeTransition(
                opacity: textPart,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(textPart),
                  child: const Column(children: [
                    Text('Tablecraft', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: AppColors.woodText)),
                    Text('Relaxing jigsaw puzzles', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
