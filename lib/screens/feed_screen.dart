import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../controllers/feed_controller.dart';
import '../widgets/dot_loader.dart';
import '../theme/tokens.dart';
import '../widgets/ambient_bg.dart';
import '../widgets/feed_card.dart';
import 'explore_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  int _navIndex = 0;
  late final FeedController _fc;

  @override
  void initState() {
    super.initState();
    _fc = FeedController()..init();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() { _fc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _fc,
      child: Scaffold(
        backgroundColor: RColors.bg,
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: IndexedStack(
          index: _navIndex,
          children: const [_FeedView(), ExploreScreen(), ProfileScreen()],
        ),
        bottomNavigationBar: _BottomNav(
          index: _navIndex,
          onTap: (i) => setState(() => _navIndex = i),
        ),
      ),
    );
  }
}

// ── Feed View ──────────────────────────────────────────────────────────────────

class _FeedView extends StatefulWidget {
  const _FeedView();
  @override
  State<_FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<_FeedView> {
  final _pageCtrl = PageController();

  @override
  void dispose() { _pageCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Consumer<FeedController>(
      builder: (_, ctrl, __) {
        return Stack(
          fit: StackFit.expand,
          children: [
            const AmbientBg(),
            if (ctrl.isLoading)
              _FeedSkeleton(isWakingUp: ctrl.isWakingUp)
            else if (ctrl.error != null && ctrl.movies.isEmpty)
              _ErrorView(onRetry: ctrl.refresh)
            else
              RefreshIndicator(
                onRefresh: ctrl.refresh,
                color: RColors.brand,
                backgroundColor: RColors.bgRaised,
                displacement: 80,
                child: PageView.builder(
                  controller: _pageCtrl,
                  scrollDirection: Axis.vertical,
                  itemCount: ctrl.movies.length,
                  onPageChanged: ctrl.onPageChanged,
                  physics: const PageScrollPhysics(),
                  itemBuilder: (_, i) => ChangeNotifierProvider.value(
                    value: ctrl,
                    child: FeedCard(
                      key: ValueKey(ctrl.movies[i].id),
                      movie: ctrl.movies[i],
                      index: i,
                    ),
                  ),
                ),
              ),
            if (!ctrl.isLoading)
              const _TopBar(),
          ],
        );
      },
    );
  }
}

// ── Top Bar — wordmark left, search right, no tabs ────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Wordmark ──
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [RColors.brand, RColors.brand2],
                    ).createShader(bounds),
                    child: Text('REELZ',
                      style: RText.wordmark(size: 20).copyWith(
                        color: Colors.white,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    height: 2,
                    width: 28,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [RColors.brand, RColors.brand2]),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: RDur.lg).slideX(begin: -0.3, end: 0, curve: RCurve.spring),

              const Spacer(),

              // ── Search pill ──
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 320),
                    pageBuilder: (_, __, ___) => const SearchScreen(),
                    transitionsBuilder: (_, anim, __, child) =>
                        FadeTransition(opacity: anim, child: child),
                  ));
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: RColors.glassMd,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: RColors.glassBorderMd),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_rounded, color: RColors.text2, size: 17),
                          const SizedBox(width: 7),
                          Text('Search', style: RText.body(size: 13, color: RColors.text2)),
                        ],
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: RDur.lg).slideX(begin: 0.3, end: 0, curve: RCurve.spring),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bottom Nav — floating pill style ──────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int index;
  final Function(int) onTap;
  const _BottomNav({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          decoration: BoxDecoration(
            color: RColors.bg.withOpacity(0.82),
            border: Border(
              top: BorderSide(color: RColors.glassBorderMd, width: 0.6),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 62,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavBtn(icon: Icons.movie_filter_rounded, outlineIcon: Icons.movie_filter_outlined,
                      active: index == 0, onTap: () => onTap(0)),
                  _NavBtn(icon: Icons.grid_view_rounded, outlineIcon: Icons.grid_view_outlined,
                      active: index == 1, onTap: () => onTap(1)),
                  _NavBtn(icon: Icons.person_rounded, outlineIcon: Icons.person_outline_rounded,
                      active: index == 2, onTap: () => onTap(2)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBtn extends StatefulWidget {
  final IconData icon, outlineIcon;
  final bool active;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.outlineIcon,
      required this.active, required this.onTap});
  @override
  State<_NavBtn> createState() => _NavBtnState();
}

class _NavBtnState extends State<_NavBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); widget.onTap(); },
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.82 : 1.0,
        duration: RDur.xs,
        curve: RCurve.spring,
        child: SizedBox(
          width: 64, height: 60,
          child: Center(
            child: AnimatedContainer(
              duration: RDur.sm,
              curve: RCurve.spring,
              width: widget.active ? 44 : 38,
              height: widget.active ? 44 : 38,
              decoration: widget.active ? BoxDecoration(
                gradient: const LinearGradient(
                  colors: [RColors.brand, RColors.brand2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: RColors.brand.withOpacity(0.5),
                    blurRadius: 14,
                    spreadRadius: 0,
                  ),
                ],
              ) : null,
              child: Icon(
                widget.active ? widget.icon : widget.outlineIcon,
                color: widget.active ? Colors.white : RColors.text3,
                size: widget.active ? 22 : 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Feed Skeleton — positions match real content exactly ──────────────────────

class _FeedSkeleton extends StatelessWidget {
  final bool isWakingUp;
  const _FeedSkeleton({this.isWakingUp = false});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-screen shimmer bg
        Container(color: RColors.bgCard)
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1600.ms, color: const Color(0x12FFFFFF)),

        // Bottom overlay gradient — same as real card
        const Positioned(
          bottom: 0, left: 0, right: 0, height: 420,
          child: DecoratedBox(decoration: BoxDecoration(gradient: RColors.overlayBottom)),
        ),

        // ── Right side actions — exact match to real card positions ──
        Positioned(
          right: 12,
          // bottom: 110 same as real _ActionBtn column
          bottom: 110,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: RColors.glass,
                      border: Border.all(color: RColors.glassBorder),
                    ),
                  ).animate(onPlay: (c) => c.repeat())
                      .shimmer(
                        delay: Duration(milliseconds: i * 150),
                        duration: 1600.ms,
                        color: const Color(0x16FFFFFF),
                      ),
                  const SizedBox(height: 6),
                  // Label stub under each icon
                  Container(
                    width: 32, height: 7,
                    decoration: BoxDecoration(
                      color: RColors.glassSm,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            )),
          ),
        ),

        // ── Bottom left content — title + CTA button ──
        // Matches Positioned(left:16, right:76, bottom:80) in FeedCard
        Positioned(
          left: 16, right: 76, bottom: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title line 1 — full width
              Container(
                height: 15,
                decoration: BoxDecoration(
                  color: RColors.glass,
                  borderRadius: BorderRadius.circular(8),
                ),
              ).animate(onPlay: (c) => c.repeat())
                  .shimmer(duration: 1600.ms, color: const Color(0x16FFFFFF)),

              const SizedBox(height: 8),

              // Title line 2 — shorter
              Container(
                width: size.width * 0.45,
                height: 15,
                decoration: BoxDecoration(
                  color: RColors.glassSm,
                  borderRadius: BorderRadius.circular(8),
                ),
              ).animate(onPlay: (c) => c.repeat())
                  .shimmer(delay: 80.ms, duration: 1600.ms, color: const Color(0x14FFFFFF)),

              const SizedBox(height: 18),

              // CTA button stub — same size as real "Watch Episode 1" button
              Container(
                height: 40,
                width: 164,
                decoration: BoxDecoration(
                  color: RColors.brand.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: RColors.brand.withOpacity(0.22)),
                ),
              ).animate(onPlay: (c) => c.repeat())
                  .shimmer(delay: 160.ms, duration: 1600.ms,
                      color: RColors.brand.withOpacity(0.07)),
            ],
          ),
        ),

        // ── Top bar skeleton — wordmark + search pill ──
        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  // Wordmark stub
                  Container(
                    width: 72, height: 18,
                    decoration: BoxDecoration(
                      color: RColors.brand.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ).animate(onPlay: (c) => c.repeat())
                      .shimmer(duration: 1600.ms, color: RColors.brand.withOpacity(0.12)),
                  const Spacer(),
                  // Search pill stub
                  Container(
                    width: 96, height: 36,
                    decoration: BoxDecoration(
                      color: RColors.glassSm,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: RColors.glassBorder),
                    ),
                  ).animate(onPlay: (c) => c.repeat())
                      .shimmer(delay: 100.ms, duration: 1600.ms, color: const Color(0x10FFFFFF)),
                ],
              ),
            ),
          ),
        ),

        // ── Waking up hint ──
        if (isWakingUp)
          Positioned(
            bottom: 160, left: 0, right: 0,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: RColors.bgRaised.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: RColors.glassBorderMd),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const DotLoader(size: 26),
                        const SizedBox(width: 12),
                        Text('Waking up server…',
                            style: RText.body(size: 12, color: RColors.text3)),
                      ],
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: RDur.md),
          ),
      ],
    );
  }
}

// ── Error View ─────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: RColors.bgRaised,
              border: Border.all(color: RColors.glassBorderMd),
            ),
            child: const Icon(Icons.wifi_off_rounded, color: RColors.text3, size: 32),
          ),
          const SizedBox(height: 20),
          Text('No connection', style: RText.body(size: 17, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Check your internet and try again',
              style: RText.body(size: 13, color: RColors.text3)),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [RColors.brand, RColors.brand2]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: RColors.brand.withOpacity(0.45), blurRadius: 20, spreadRadius: 0),
                ],
              ),
              child: Text('Try Again', style: RText.body(size: 14, weight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
