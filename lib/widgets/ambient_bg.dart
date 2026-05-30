import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Cinematic ambient background — slow-drifting orbs with a subtle film-grain overlay.
/// Pure visual; zero logic changes.
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
      duration: const Duration(seconds: 14),
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
        painter: _AmbientPainter(_ctrl.value),
        size: Size.infinite,
      ),
    );
  }
}

class _AmbientPainter extends CustomPainter {
  final double t;
  _AmbientPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // ── Orb 1 — violet, top-right, slow drift ────────────────────────────────
    final o1x = size.width * 0.80 + math.sin(t * math.pi * 2) * 32;
    final o1y = size.height * 0.12 + math.cos(t * math.pi * 2) * 20;
    final r1 = size.width * 0.55;
    canvas.drawCircle(
      Offset(o1x, o1y), r1,
      Paint()
        ..shader = RadialGradient(
          colors: [
            RColors.brand.withOpacity(0.18),
            RColors.brand.withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(o1x, o1y), radius: r1)),
    );

    // ── Orb 2 — lavender, bottom-left ────────────────────────────────────────
    final o2x = size.width * 0.14 + math.cos(t * math.pi * 2 + 1.0) * 26;
    final o2y = size.height * 0.72 + math.sin(t * math.pi * 2 + 1.0) * 32;
    final r2 = size.width * 0.46;
    canvas.drawCircle(
      Offset(o2x, o2y), r2,
      Paint()
        ..shader = RadialGradient(
          colors: [
            RColors.brand2.withOpacity(0.10),
            RColors.brand2.withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(o2x, o2y), radius: r2)),
    );

    // ── Orb 3 — teal accent, center-bottom, subtle ───────────────────────────
    final o3x = size.width * 0.50 + math.sin(t * math.pi * 2 + 2.5) * 18;
    final o3y = size.height * 0.88 + math.cos(t * math.pi * 2 + 2.5) * 14;
    final r3 = size.width * 0.30;
    canvas.drawCircle(
      Offset(o3x, o3y), r3,
      Paint()
        ..shader = RadialGradient(
          colors: [
            RColors.teal.withOpacity(0.07),
            RColors.teal.withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(o3x, o3y), radius: r3)),
    );

    // ── Film-grain noise overlay ─────────────────────────────────────────────
    final rng = math.Random(42);
    final gp = Paint()..color = Colors.white.withOpacity(0.013);
    for (int i = 0; i < 700; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        0.55, gp,
      );
    }
  }

  @override
  bool shouldRepaint(_AmbientPainter o) => o.t != t;
}
