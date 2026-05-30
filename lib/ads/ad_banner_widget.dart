import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/tokens.dart';
import 'ad_engine.dart';
import 'ad_html_templates.dart';
import 'ad_launcher.dart';

/// ── AdBannerWidget ────────────────────────────────────────────────────────────
/// Native Banner (4:1 horizontal) that slides up above the bottom nav.
///
/// • Transparent WebView background — blends into app glassmorphic frame
/// • Completely hidden in landscape (engine signals this)
/// • Tap = Custom Tabs / SFSafariVC — never leaves app
/// • X dismisses with slide-down animation
/// • Auto-dismissed after 15s by AdEngine

class AdBannerWidget extends StatefulWidget {
  final AdEngine engine;
  final bool visible;
  const AdBannerWidget({super.key, required this.engine, required this.visible});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  late final WebViewController _ctrl;
  bool _webReady  = false;
  bool _webFailed = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _webReady = true);
        },
        onWebResourceError: (_) {
          if (mounted) setState(() => _webFailed = true);
        },
        onNavigationRequest: (req) {
          if (req.url.startsWith('data:') || req.url == 'about:blank') {
            return NavigationDecision.navigate;
          }
          AdLauncher.open(req.url);
          return NavigationDecision.prevent;
        },
      ))
      ..loadHtmlString(
        AdHtmlTemplates.nativeBanner(),
        baseUrl: 'https://pl29592548.effectivecpmnetwork.com',
      );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    // Always hidden in landscape — never block immersion
    if (isLandscape) return const SizedBox.shrink();

    return AnimatedSlide(
      offset: widget.visible ? Offset.zero : const Offset(0, 2.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: widget.visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 320),
        child: _BannerFrame(
          ctrl: _ctrl,
          webReady: _webReady,
          webFailed: _webFailed,
          onClose: () {
            HapticFeedback.lightImpact();
            widget.engine.onBannerClosed();
          },
        ),
      ),
    );
  }
}

// ── Banner Frame ───────────────────────────────────────────────────────────────

class _BannerFrame extends StatelessWidget {
  final WebViewController ctrl;
  final bool webReady;
  final bool webFailed;
  final VoidCallback onClose;

  const _BannerFrame({
    required this.ctrl,
    required this.webReady,
    required this.webFailed,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            height: 90,
            decoration: BoxDecoration(
              color: RColors.bgCard.withOpacity(0.93),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: RColors.glassBorderMd),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.38),
                  blurRadius: 28,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Stack(
              children: [

                // ── WebView ad content ─────────────────────────────────────
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 36),
                      child: webFailed
                          ? _FallbackBanner()
                          : Stack(
                              fit: StackFit.expand,
                              children: [
                                WebViewWidget(controller: ctrl),
                                if (!webReady) _BannerShimmer(),
                              ],
                            ),
                    ),
                  ),
                ),

                // ── AD badge top-left ──────────────────────────────────────
                Positioned(
                  top: 7, left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFBB38).withOpacity(0.14),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFFFFBB38).withOpacity(0.38),
                        width: 0.7,
                      ),
                    ),
                    child: Text('AD',
                        style: RText.label(
                            size: 8, color: const Color(0xFFFFBB38))),
                  ),
                ),

                // ── Close button right edge ────────────────────────────────
                Positioned(
                  top: 0, right: 0, bottom: 0,
                  child: GestureDetector(
                    onTap: onClose,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 36,
                      decoration: BoxDecoration(
                        color: RColors.glass,
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(16),
                        ),
                        border: Border(
                          left: BorderSide(
                              color: RColors.glassBorder, width: 0.5),
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.close_rounded,
                            color: RColors.text3, size: 15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shimmer placeholder while WebView loads ────────────────────────────────────

class _BannerShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(color: RColors.bgCard)
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1600.ms, color: const Color(0x0CFFFFFF));
  }
}

// ── Fallback if WebView fails ──────────────────────────────────────────────────

class _FallbackBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [RColors.brandDeep, RColors.brand],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.14),
            ),
            child: const Icon(Icons.movie_filter_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Watch More Free',
                    style: RText.body(
                        size: 13, weight: FontWeight.w700)),
                Text('Powered by Adsterra',
                    style: RText.label(
                        size: 10, color: Colors.white54)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white24),
            ),
            child: Text('View',
                style: RText.body(
                    size: 11, weight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
