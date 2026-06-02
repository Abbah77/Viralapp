import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../ads/ad_engine.dart';
import '../theme/tokens.dart';

/// NativeGridAdCard — looks exactly like a content card in the explore grid.
/// Muted by default, small unmute icon, perfectly aligned with real content.
/// Replace the placeholder container with real native ad SDK widget when ready.
class NativeGridAdCard extends StatefulWidget {
  final NativeGridAd ad;
  const NativeGridAdCard({super.key, required this.ad});

  @override
  State<NativeGridAdCard> createState() => _NativeGridAdCardState();
}

class _NativeGridAdCardState extends State<NativeGridAdCard> {
  bool _isMuted = true;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); _onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: RDur.xs,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(fit: StackFit.expand, children: [

            // ── Ad content area ─────────────────────────────────────────────
            // TODO: Replace with real native ad SDK widget
            // e.g. AdWidget(ad: _nativeAd) for AdMob
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    RColors.bgCard,
                    RColors.bgRaised,
                    RColors.bgSurface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: RColors.brand.withOpacity(0.15),
                      border: Border.all(color: RColors.brand.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.ads_click_rounded, color: RColors.brand, size: 20),
                  ),
                  const SizedBox(height: 6),
                  Text('Ad', style: RText.label(size: 9, color: RColors.text3)),
                ]),
              ),
            ),

            // ── Bottom gradient same as content cards ────────────────────
            const Positioned(
              bottom: 0, left: 0, right: 0, height: 60,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xCC07070B), Colors.transparent],
                  ),
                ),
              ),
            ),

            // ── AD badge — small, top-left ───────────────────────────────
            Positioned(
              top: 6, left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: RColors.gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: RColors.gold.withOpacity(0.4), width: 0.7),
                ),
                child: Text('AD', style: RText.label(size: 7, color: RColors.gold)),
              ),
            ),

            // ── Mute/unmute icon — top-right ─────────────────────────────
            Positioned(
              top: 6, right: 6,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isMuted = !_isMuted);
                },
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.5),
                        border: Border.all(color: Colors.white.withOpacity(0.15), width: 0.5),
                      ),
                      child: Icon(
                        _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                        color: Colors.white, size: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Sponsored label — bottom ────────────────────────────────
            Positioned(
              bottom: 5, left: 6, right: 6,
              child: Text(
                widget.ad.title.isEmpty ? 'Sponsored' : widget.ad.title,
                style: RText.label(size: 9, color: RColors.text2),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    // TODO: Handle ad click — open destination URL or native ad action
  }
}
