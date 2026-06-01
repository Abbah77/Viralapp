import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/tokens.dart';
import '../widgets/dot_loader.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _signingIn = false;
  late final AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_signingIn) return;
    HapticFeedback.mediumImpact();
    setState(() => _signingIn = true);
    final auth = context.read<AuthService>();
    final user = await auth.signInWithGoogle();
    if (mounted) {
      if (user == null) {
        setState(() => _signingIn = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in cancelled',
                style: RText.body(size: 13)),
            backgroundColor: RColors.bgRaised,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      // If user != null, parent will rebuild (AuthService notified)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RColors.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Animated orb background ───────────────────────────────────
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, __) => CustomPaint(
              painter: _AuthBgPainter(_bgCtrl.value),
              size: Size.infinite,
            ),
          ),

          // ── Content ───────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Logo
                  _LogoMark()
                      .animate()
                      .fadeIn(duration: 800.ms)
                      .scale(begin: const Offset(0.8, 0.8), curve: RCurve.spring),

                  const SizedBox(height: 28),

                  Text(
                    'Cinema on demand.',
                    style: RText.body(
                      size: 26,
                      weight: FontWeight.w800,
                      color: RColors.text,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 600.ms)
                      .slideY(begin: 0.3, end: 0, curve: RCurve.spring),

                  const SizedBox(height: 10),

                  Text(
                    'Trailers, series & more — free forever.',
                    style: RText.body(size: 15, color: RColors.text3),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 320.ms, duration: 600.ms)
                      .slideY(begin: 0.3, end: 0, curve: RCurve.spring),

                  const Spacer(flex: 3),

                  // Google sign-in button
                  _GoogleButton(
                    loading: _signingIn,
                    onTap: _signIn,
                  )
                      .animate()
                      .fadeIn(delay: 480.ms, duration: 600.ms)
                      .slideY(begin: 0.4, end: 0, curve: RCurve.spring),

                  const SizedBox(height: 16),

                  Text(
                    'By continuing you agree to our Terms & Privacy Policy.',
                    style: RText.label(size: 11, color: RColors.text4),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 600.ms, duration: 600.ms),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Logo ───────────────────────────────────────────────────────────────────────

class _LogoMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [RColors.brandDeep, RColors.brand, RColors.brand2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: RColors.brand.withOpacity(0.5),
                blurRadius: 32,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'R',
              style: TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.w900,
                letterSpacing: -2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [RColors.brand, RColors.brand2],
          ).createShader(b),
          child: Text(
            'REELZ',
            style: RText.wordmark(size: 28).copyWith(
              color: Colors.white,
              letterSpacing: 6,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Google Button ──────────────────────────────────────────────────────────────

class _GoogleButton extends StatefulWidget {
  final bool loading;
  final VoidCallback onTap;
  const _GoogleButton({required this.loading, required this.onTap});
  @override
  State<_GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends State<_GoogleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: RDur.xs,
        curve: RCurve.spring,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 62,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: Colors.white.withOpacity(0.18), width: 1),
              ),
              child: widget.loading
                  ? const Center(child: SamsungLoader(size: 26))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _GoogleIcon(),
                        const SizedBox(width: 14),
                        Text(
                          'Continue with Google',
                          style: RText.body(
                            size: 16,
                            weight: FontWeight.w600,
                            color: RColors.text,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleIconPainter()),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Simple Google G
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = size.width * 0.13;

    // Blue arc
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.85),
        -0.3, math.pi * 1.4, false, paint);

    // Red
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.85),
        math.pi * 1.1, math.pi * 0.55, false, paint);

    // Yellow
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.85),
        math.pi * 1.65, math.pi * 0.45, false, paint);

    // Green
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.85),
        -0.3 - 0.15, math.pi * 0.22, false, paint);

    // Horizontal bar
    paint
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = size.width * 0.13;
    canvas.drawLine(
      Offset(c.dx, c.dy),
      Offset(c.dx + r * 0.85, c.dy),
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Animated background ───────────────────────────────────────────────────────

class _AuthBgPainter extends CustomPainter {
  final double t;
  _AuthBgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final o1x = size.width * 0.75 + math.sin(t * math.pi * 2) * 40;
    final o1y = size.height * 0.15 + math.cos(t * math.pi * 2) * 30;
    final r1 = size.width * 0.65;
    canvas.drawCircle(
      Offset(o1x, o1y),
      r1,
      Paint()
        ..shader = RadialGradient(colors: [
          RColors.brand.withOpacity(0.22),
          Colors.transparent,
        ]).createShader(Rect.fromCircle(center: Offset(o1x, o1y), radius: r1)),
    );

    final o2x = size.width * 0.20 + math.cos(t * math.pi * 2 + 1) * 30;
    final o2y = size.height * 0.65 + math.sin(t * math.pi * 2 + 1) * 40;
    final r2 = size.width * 0.5;
    canvas.drawCircle(
      Offset(o2x, o2y),
      r2,
      Paint()
        ..shader = RadialGradient(colors: [
          RColors.brand2.withOpacity(0.14),
          Colors.transparent,
        ]).createShader(Rect.fromCircle(center: Offset(o2x, o2y), radius: r2)),
    );
  }

  @override
  bool shouldRepaint(_AuthBgPainter o) => o.t != t;
}
