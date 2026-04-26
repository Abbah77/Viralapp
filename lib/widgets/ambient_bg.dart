import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class AmbientBg extends StatefulWidget {
  const AmbientBg({super.key});

  @override
  State<AmbientBg> createState() => _AmbientBgState();
}

class _AmbientBgState extends State<AmbientBg>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _Painter(_ctrl.value),
        size: Size.infinite,
      ),
    );
  }
}

class _Painter extends CustomPainter {
  final double t;
  _Painter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final o1x = size.width * 0.75 + math.sin(t * math.pi * 2) * 28;
    final o1y = size.height * 0.15 + math.cos(t * math.pi * 2) * 18;
    canvas.drawCircle(Offset(o1x, o1y), size.width * 0.52,
      Paint()..shader = RadialGradient(colors: [
        RColors.brand.withOpacity(0.16), RColors.brand.withOpacity(0),
      ]).createShader(Rect.fromCircle(center: Offset(o1x, o1y), radius: size.width * 0.52)));

    final o2x = size.width * 0.18 + math.cos(t * math.pi * 2) * 22;
    final o2y = size.height * 0.7 + math.sin(t * math.pi * 2) * 28;
    canvas.drawCircle(Offset(o2x, o2y), size.width * 0.42,
      Paint()..shader = RadialGradient(colors: [
        RColors.brand2.withOpacity(0.10), RColors.brand2.withOpacity(0),
      ]).createShader(Rect.fromCircle(center: Offset(o2x, o2y), radius: size.width * 0.42)));

    final rng = math.Random(42);
    final gp = Paint()..color = Colors.white.withOpacity(0.016);
    for (int i = 0; i < 600; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        0.6, gp,
      );
    }
  }

  @override
  bool shouldRepaint(_Painter o) => o.t != t;
}
