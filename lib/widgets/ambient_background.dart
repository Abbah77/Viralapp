import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class AmbientBackground extends StatefulWidget {
  const AmbientBackground({super.key});

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _AmbientPainter(_controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _AmbientPainter extends CustomPainter {
  final double t;

  _AmbientPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Orb 1 — brand blue top right
    final orb1X = size.width * 0.75 + math.sin(t * math.pi * 2) * 30;
    final orb1Y = size.height * 0.15 + math.cos(t * math.pi * 2) * 20;

    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          ReelzColors.brand.withOpacity(0.18),
          ReelzColors.brand.withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(orb1X, orb1Y),
        radius: size.width * 0.55,
      ));

    canvas.drawCircle(Offset(orb1X, orb1Y), size.width * 0.55, paint1);

    // Orb 2 — brand2 cyan bottom left
    final orb2X = size.width * 0.2 + math.cos(t * math.pi * 2) * 25;
    final orb2Y = size.height * 0.72 + math.sin(t * math.pi * 2) * 30;

    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          ReelzColors.brand2.withOpacity(0.12),
          ReelzColors.brand2.withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(orb2X, orb2Y),
        radius: size.width * 0.45,
      ));

    canvas.drawCircle(Offset(orb2X, orb2Y), size.width * 0.45, paint2);

    // Grain texture
    final random = math.Random(42);
    final grainPaint = Paint()..color = Colors.white.withOpacity(0.018);

    for (int i = 0; i < 800; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.6, grainPaint);
    }
  }

  @override
  bool shouldRepaint(_AmbientPainter old) => old.t != t;
}
