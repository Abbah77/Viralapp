import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/tokens.dart';
import '../widgets/dot_loader.dart';
import 'ad_engine.dart';

/// Full-screen interstitial — no Adsterra, clean native placeholder.
/// Replace _AdContent with real SDK interstitial when ready.
class AdInterstitialOverlay extends StatefulWidget {
  final AdEngine engine;
  const AdInterstitialOverlay({super.key, required this.engine});

  @override
  State<AdInterstitialOverlay> createState() => _AdInterstitialOverlayState();
}

class _AdInterstitialOverlayState extends State<AdInterstitialOverlay>
    with TickerProviderStateMixin {

  static const int _skipDelay   = 5;
  static const int _autoDismiss = 20;

  int  _elapsed  = 0;
  bool _canSkip  = false;
  late final AnimationController _ringCtrl;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(vsync: this, duration: const Duration(seconds: _skipDelay))..forward();
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _elapsed++;
        if (_elapsed >= _skipDelay)   _canSkip = true;
        if (_elapsed >= _autoDismiss) _dismiss();
      });
    });
  }

  void _dismiss() {
    _ticker?.cancel();
    widget.engine.onInterstitialDismissed();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ringCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    return Material(
      color: RColors.bg,
      child: Stack(fit: StackFit.expand, children: [

        // ── Ad content area ──────────────────────────────────────────────────
        // TODO: Replace with real SDK interstitial widget
        _AdContent(),

        // ── Progress bar ────────────────────────────────────────────────────
        Positioned(
          top: 0, left: 0, right: 0,
          child: LinearProgressIndicator(
            value: _elapsed / _autoDismiss,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(RColors.brand.withOpacity(0.55)),
            minHeight: 2,
          ),
        ),

        // ── Top bar ──────────────────────────────────────────────────────────
        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(
            bottom: false,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: isLandscape ? 8 : 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.black.withOpacity(0.82), Colors.transparent],
                    ),
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: RColors.gold.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: RColors.gold.withOpacity(0.45), width: 0.8),
                      ),
                      child: Text('AD', style: RText.label(size: 10, color: RColors.gold)),
                    ),
                    const SizedBox(width: 10),
                    Text('Advertisement', style: RText.body(size: 12, color: RColors.text3)),
                    const Spacer(),
                    Text('Closes in ${_autoDismiss - _elapsed}s', style: RText.label(size: 11, color: RColors.text3)),
                  ]),
                ),
              ),
            ),
          ),
        ),

        // ── Skip / countdown ────────────────────────────────────────────────
        Positioned(
          bottom: isLandscape ? 14 : 44, right: 16,
          child: SafeArea(
            top: false,
            child: _canSkip
              ? _SkipButton(onSkip: _dismiss)
              : _CountdownRing(ctrl: _ringCtrl, countdown: _skipDelay - _elapsed),
          ),
        ),
      ]),
    );
  }
}

class _AdContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: RColors.bg,
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [RColors.brand, RColors.brand2], begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: RColors.brand.withOpacity(0.4), blurRadius: 36, spreadRadius: 4)],
            ),
            child: const Icon(Icons.ads_click_rounded, color: Colors.white, size: 44),
          ),
          const SizedBox(height: 20),
          Text('Advertisement', style: RText.body(size: 18, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Your ad will appear here', style: RText.body(size: 13, color: RColors.text3)),
          const SizedBox(height: 6),
          Text('This keeps Reelz free', style: RText.label(color: RColors.text4)),
        ]),
      ),
    );
  }
}

class _CountdownRing extends StatelessWidget {
  final AnimationController ctrl;
  final int countdown;
  const _CountdownRing({required this.ctrl, required this.countdown});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) => SizedBox(
        width: 52, height: 52,
        child: Stack(fit: StackFit.expand, children: [
          CircularProgressIndicator(
            value: ctrl.value,
            backgroundColor: RColors.glassMd,
            color: RColors.brand,
            strokeWidth: 2.5,
            strokeCap: StrokeCap.round,
          ),
          Center(child: Text('$countdown', style: RText.body(size: 17, weight: FontWeight.w800))),
        ]),
      ),
    );
  }
}

class _SkipButton extends StatefulWidget {
  final VoidCallback onSkip;
  const _SkipButton({required this.onSkip});
  @override
  State<_SkipButton> createState() => _SkipButtonState();
}

class _SkipButtonState extends State<_SkipButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); HapticFeedback.lightImpact(); widget.onSkip(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.91 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              decoration: BoxDecoration(
                color: RColors.glassMd,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: RColors.glassBorderMd),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Skip Ad', style: RText.body(size: 14, weight: FontWeight.w700)),
                const SizedBox(width: 7),
                const Icon(Icons.arrow_forward_rounded, color: RColors.text, size: 16),
              ]),
            ),
          ),
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
     .shimmer(duration: 1400.ms, color: const Color(0x14FFFFFF));
  }
}
