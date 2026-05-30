import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Four dots that swap corners diagonally along curved arc paths.
///
///   1 ──╮  ╭── 2
///       ╲╱
///       ╱╲
///   3 ──╯  ╰── 4
///
/// Dot 1 trades place with Dot 4 (top-left ↔ bottom-right)
/// Dot 2 trades place with Dot 3 (top-right ↔ bottom-left)
/// They travel on opposing curved arcs so they never collide.
class DotLoader extends StatefulWidget {
  final double size;
  final Color? color;

  const DotLoader({super.key, this.size = 48, this.color});

  @override
  State<DotLoader> createState() => _DotLoaderState();
}

class _DotLoaderState extends State<DotLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? RColors.brand;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          painter: _DotPainter(_ctrl.value, color),
        ),
      ),
    );
  }
}

class _DotPainter extends CustomPainter {
  final double t;
  final Color color;
  _DotPainter(this.t, this.color);

  // Smooth ease-in-out curve on [0,1]
  double _ease(double x) =>
      x < 0.5 ? 4 * x * x * x : 1 - math.pow(-2 * x + 2, 3) / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final r  = size.width / 2;       // half the widget
    final dr = r * 0.32;             // dot radius
    final gap = r * 0.50;            // corner offset from centre

    // Phase: 0→0.5 = first swap, 0.5→1 = second swap
    // We use a seamless single-phase loop — both pairs swap simultaneously.
    final e = _ease(t < 0.5 ? t * 2 : (t - 0.5) * 2);
    final phase2 = t >= 0.5; // second half reverses direction

    // Corner positions (relative to centre)
    final tl = Offset(-gap, -gap); // top-left    (dot 1)
    final tr = Offset( gap, -gap); // top-right   (dot 2)
    final bl = Offset(-gap,  gap); // bottom-left (dot 3)
    final br = Offset( gap,  gap); // bottom-right(dot 4)

    Offset _arc(Offset from, Offset to, double progress, bool clockwise) {
      // Interpolate angle around a circular arc whose centre sits between
      // the two points, biased inward so the dots swing past the centre.
      final mid = (from + to) / 2;
      final dx = to.dx - from.dx;
      final dy = to.dy - from.dy;
      final chord = math.sqrt(dx * dx + dy * dy);
      // Arc radius = 80% of chord → tight but clearly curved
      final arcR = chord * 0.80;
      // Normal pointing inward toward the centre of the widget
      final nx = -(to.dy - from.dy) / chord;
      final ny =  (to.dx - from.dx) / chord;
      final sign = clockwise ? -1.0 : 1.0;
      final cx = mid.dx + nx * arcR * 0.35 * sign;
      final cy = mid.dy + ny * arcR * 0.35 * sign;
      final aStart = math.atan2(from.dy - cy, from.dx - cx);
      final aEnd   = math.atan2(to.dy   - cy, to.dx   - cx);
      double sweep = aEnd - aStart;
      if (clockwise  && sweep < 0) sweep += 2 * math.pi;
      if (!clockwise && sweep > 0) sweep -= 2 * math.pi;
      final angle = aStart + sweep * progress;
      final dist = math.sqrt(math.pow(from.dx - cx, 2) + math.pow(from.dy - cy, 2));
      return Offset(cx + dist * math.cos(angle), cy + dist * math.sin(angle));
    }

    // Pair A: dot1 (tl) ↔ dot4 (br), pair B: dot2 (tr) ↔ dot3 (bl)
    // On first half: 1→br, 4→tl, 2→bl, 3→tr
    // On second half: reverse (they come back to home)
    final Offset p1, p2, p3, p4;

    if (!phase2) {
      p1 = _arc(tl, br, e, true);
      p4 = _arc(br, tl, e, true);
      p2 = _arc(tr, bl, e, false);
      p3 = _arc(bl, tr, e, false);
    } else {
      p1 = _arc(br, tl, e, true);
      p4 = _arc(tl, br, e, true);
      p2 = _arc(bl, tr, e, false);
      p3 = _arc(tr, bl, e, false);
    }

    final centre = Offset(r, r);

    void drawDot(Offset rel, double opacity) {
      final pos = centre + rel;
      // Glow
      canvas.drawCircle(pos, dr * 1.9,
          Paint()..color = color.withOpacity(0.12 * opacity)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      // Core
      canvas.drawCircle(pos, dr, Paint()..color = color.withOpacity(opacity));
    }

    // Trailing fade on the travelling dots for motion feel
    drawDot(p1, 1.0);
    drawDot(p4, 1.0);
    drawDot(p2, 0.9);
    drawDot(p3, 0.9);
  }

  @override
  bool shouldRepaint(_DotPainter old) => old.t != t;
}

/// Convenience full-screen loading overlay using DotLoader
class LoadingOverlay extends StatelessWidget {
  final String? message;
  const LoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DotLoader(size: 52),
          if (message != null) ...[
            const SizedBox(height: 18),
            Text(message!, style: RText.body(size: 13, color: RColors.text3)),
          ],
        ],
      ),
    );
  }
}
