import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/tokens.dart';
import 'ad_engine.dart';

/// Medium-size native banner — floats above bottom nav.
/// NOT fixed — appears randomly based on AdEngine.
/// Replace _AdPlaceholder with real SDK banner when ready.
class AdBannerWidget extends StatelessWidget {
  final AdEngine engine;
  final bool visible;
  const AdBannerWidget({super.key, required this.engine, required this.visible});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (size.width > size.height) return const SizedBox.shrink();

    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, 1.5),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 280),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Container(
                height: 76,
                decoration: BoxDecoration(
                  color: RColors.bgCard.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: RColors.glassBorderMd, width: 0.8),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.32), blurRadius: 24, offset: const Offset(0, 6))],
                ),
                child: Stack(children: [
                  // ── Native ad content ──────────────────────────────────
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 40),
                        // TODO: Replace with real SDK banner widget
                        child: _AdPlaceholder(),
                      ),
                    ),
                  ),

                  // ── AD badge ───────────────────────────────────────────
                  Positioned(
                    top: 6, left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: RColors.gold.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: RColors.gold.withOpacity(0.35), width: 0.7),
                      ),
                      child: Text('AD', style: RText.label(size: 8, color: RColors.gold)),
                    ),
                  ),

                  // ── Close ──────────────────────────────────────────────
                  Positioned(
                    top: 0, right: 0, bottom: 0,
                    child: GestureDetector(
                      onTap: () { HapticFeedback.lightImpact(); engine.onBannerClosed(); },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 40,
                        decoration: BoxDecoration(
                          color: RColors.glass,
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(18)),
                        ),
                        child: const Center(child: Icon(Icons.close_rounded, color: RColors.text3, size: 14)),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: RColors.bgCard,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: RColors.brand.withOpacity(0.15),
            border: Border.all(color: RColors.brand.withOpacity(0.3)),
          ),
          child: const Icon(Icons.ads_click_rounded, color: RColors.brand, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Advertisement', style: RText.body(size: 12, weight: FontWeight.w600)),
            Text('Tap to learn more', style: RText.label(size: 10, color: RColors.text3)),
          ],
        )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [RColors.brand, RColors.brand2]),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('View', style: RText.body(size: 10, weight: FontWeight.w700)),
        ),
      ]),
    );
  }
}
