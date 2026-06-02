import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ad_engine.dart';
import 'ad_interstitial_overlay.dart';
import 'ad_banner_widget.dart';

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
            child,

            // Banner — randomly appears above bottom nav
            if (!engine.interstitialPending)
              Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: AdBannerWidget(engine: engine, visible: engine.bannerVisible),
              ),

            // Interstitial — full screen
            if (engine.interstitialPending)
              Positioned.fill(child: AdInterstitialOverlay(engine: engine)),
          ],
        );
      },
    );
  }
}
