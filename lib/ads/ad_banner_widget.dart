import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/tokens.dart';
import 'ad_engine.dart';
import 'ad_html_templates.dart';
import 'ad_launcher.dart';

/// Modern pill-style banner — floats above the bottom nav.
/// Minimal, non-intrusive, with soft glassmorphic card.
class AdBannerWidget extends StatefulWidget {
  final AdEngine engine;
  final bool visible;
  const AdBannerWidget({super.key, required this.engine, required this.visible});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  late final WebViewController _ctrl;
  bool _webReady = false;
  bool _webFailed = false;

  @override
  void initState() {
    super.initState();
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
    if (size.width > size.height) return const SizedBox.shrink();

    return AnimatedSlide(
      offset: widget.visible ? Offset.zero : const Offset(0, 1.5),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: widget.visible ? 1.0 : 0.0,
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
                  color: RColors.bgCard.withOpacity(0.88),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: RColors.glassBorderMd, width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.32),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Ad content
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 40),
                          child: _webFailed
                              ? _FallbackBanner()
                              : Stack(fit: StackFit.expand, children: [
                                  WebViewWidget(controller: _ctrl),
                                  if (!_webReady)
                                    Container(color: RColors.bgCard)
                                        .animate(onPlay: (c) => c.repeat())
                                        .shimmer(
                                            duration: 1400.ms,
                                            color: const Color(0x0AFFFFFF)),
                                ]),
                        ),
                      ),
                    ),

                    // AD badge
                    Positioned(
                      top: 6,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: RColors.gold.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: RColors.gold.withOpacity(0.35),
                              width: 0.7),
                        ),
                        child: Text('AD',
                            style: RText.label(
                                size: 8, color: RColors.gold)),
                      ),
                    ),

                    // Close
                    Positioned(
                      top: 0,
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          widget.engine.onBannerClosed();
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 40,
                          decoration: BoxDecoration(
                            color: RColors.glass,
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(18),
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.close_rounded,
                                color: RColors.text3, size: 14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.14),
          ),
          child: const Icon(Icons.movie_filter_rounded,
              color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Watch More Free',
                  style: RText.body(
                      size: 12, weight: FontWeight.w700)),
              Text('Powered by Adsterra',
                  style: RText.label(
                      size: 9, color: Colors.white54)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('View',
              style: RText.body(
                  size: 10, weight: FontWeight.w700)),
        ),
      ]),
    );
  }
}
