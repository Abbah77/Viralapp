import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Samsung-style loading animation — three small dots that pulse
/// in sequence with a smooth scale + opacity wave.
class SamsungLoader extends StatefulWidget {
  final double size;
  final Color? color;

  const SamsungLoader({super.key, this.size = 32, this.color});

  @override
  State<SamsungLoader> createState() => _SamsungLoaderState();
}

class _SamsungLoaderState extends State<SamsungLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
    final dotR = widget.size * 0.13;
    return SizedBox(
      width: widget.size,
      height: widget.size * 0.38,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(3, (i) {
            // Each dot peaks at t = i/3, falls off smoothly
            final phase = ((_ctrl.value - i / 3.0) % 1.0 + 1.0) % 1.0;
            final pulse = _samsung(phase);
            return _Dot(radius: dotR, color: color, pulse: pulse);
          }),
        ),
      ),
    );
  }

  /// Samsung ease: quick rise, slow fall — like a heartbeat
  static double _samsung(double phase) {
    if (phase < 0.2) {
      return Curves.easeOut.transform(phase / 0.2);
    } else if (phase < 0.5) {
      return 1.0 - Curves.easeIn.transform((phase - 0.2) / 0.3) * 0.5;
    } else {
      return 0.5 - Curves.easeIn.transform((phase - 0.5) / 0.5) * 0.4;
    }
  }
}

class _Dot extends StatelessWidget {
  final double radius;
  final Color color;
  final double pulse; // 0.0 – 1.0

  const _Dot({required this.radius, required this.color, required this.pulse});

  @override
  Widget build(BuildContext context) {
    final scale = 0.6 + pulse * 0.4;
    final opacity = 0.35 + pulse * 0.65;
    return Transform.scale(
      scale: scale,
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(opacity),
        ),
      ),
    );
  }
}

/// Legacy alias — keep old references working
typedef DotLoader = SamsungLoader;

/// Full-screen loading overlay
class LoadingOverlay extends StatelessWidget {
  final String? message;
  const LoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SamsungLoader(size: 44),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: RText.body(size: 13, color: RColors.text3)),
          ],
        ],
      ),
    );
  }
}
