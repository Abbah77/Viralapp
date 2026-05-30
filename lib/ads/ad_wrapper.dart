import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ad_engine.dart';
import 'ad_interstitial_overlay.dart';
import 'ad_banner_widget.dart';

/// ── AdWrapper ──────────────────────────────────────────────────────────────────
/// Wraps any screen and injects ads on top based on AdEngine signals.
/// Use this at the ROOT of FeedScreen so it covers everything.
///
/// Usage:
///   AdWrapper(child: FeedScreen())

class AdWrapper extends StatelessWidget {
  final Widget child;
  const AdWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdEngine>(
      builder: (_, engine, __) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // ── App content ─────────────────────────────────────────────────
            child,

            // ── Banner — bottom safe zone ────────────────────────────────────
            if (!engine.interstitialPending)
              Positioned(
                bottom: 80, // above bottom nav
                left: 0,
                right: 0,
                child: AdBannerWidget(
                  engine: engine,
                  visible: engine.bannerVisible,
                ),
              ),

            // ── Interstitial — full screen overlay ───────────────────────────
            if (engine.interstitialPending)
              Positioned.fill(
                child: AdInterstitialOverlay(engine: engine),
              ),
          ],
        );
      },
    );
  }
}
