import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../controllers/feed_controller.dart';
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
  int _tab = 0;

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
            else if (_tab == 1)
              const _FollowingPlaceholder()
            else
              RefreshIndicator(
                onRefresh: ctrl.refresh,
                color: RColors.brand,
                backgroundColor: RColors.bgRaised,
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
              _TopBar(tab: _tab, onTabChanged: (t) => setState(() => _tab = t)),
          ],
        );
      },
    );
  }
}

// ── Top Bar ────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final int tab;
  final ValueChanged<int> onTabChanged;
  const _TopBar({required this.tab, required this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 52,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('Reelz', style: RText.wordmark())
                    .animate().fadeIn(duration: RDur.lg).slideX(begin: -0.2, end: 0, curve: RCurve.spring),
                const Spacer(),
                _TabPill(tab: tab, onChanged: onTabChanged).animate().fadeIn(duration: RDur.lg),
                const Spacer(),
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
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: RColors.glass,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: RColors.glassBorder),
                        ),
                        child: const Icon(Icons.search_rounded, color: RColors.text, size: 20),
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: RDur.lg).slideX(begin: 0.2, end: 0, curve: RCurve.spring),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final int tab;
  final ValueChanged<int> onChanged;
  const _TabPill({required this.tab, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: RColors.glass,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: RColors.glassBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Tab(label: 'For You', active: tab == 0, onTap: () => onChanged(0)),
              _Tab(label: 'Following', active: tab == 1, onTap: () => onChanged(1)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onTap(); },
      child: AnimatedContainer(
        duration: RDur.sm,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? RColors.brand.withOpacity(0.9) : Colors.transparent,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Text(label,
          style: RText.body(size: 12, weight: FontWeight.w700,
              color: active ? Colors.white : RColors.text3)),
      ),
    );
  }
}

class _FollowingPlaceholder extends StatelessWidget {
  const _FollowingPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle, color: RColors.bgRaised,
              border: Border.all(color: RColors.glassBorder),
            ),
            child: const Icon(Icons.people_outline_rounded, color: RColors.text3, size: 30),
          ),
          const SizedBox(height: 16),
          Text('Following feed', style: RText.body(size: 16, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Coming soon 🚀', style: RText.body(size: 13, color: RColors.text3)),
        ],
      ),
    );
  }
}

// ── Bottom Nav ─────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int index;
  final Function(int) onTap;
  const _BottomNav({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: RColors.bg.withOpacity(0.85),
            border: Border(top: BorderSide(color: RColors.glassBorder, width: 0.5)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 58,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavBtn(activeIcon: Icons.home_rounded, inactiveIcon: Icons.home_outlined,
                      label: 'Home', active: index == 0, onTap: () => onTap(0)),
                  _NavBtn(activeIcon: Icons.explore_rounded, inactiveIcon: Icons.explore_outlined,
                      label: 'Explore', active: index == 1, onTap: () => onTap(1)),
                  _NavBtn(activeIcon: Icons.person_rounded, inactiveIcon: Icons.person_outline_rounded,
                      label: 'Profile', active: index == 2, onTap: () => onTap(2)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData activeIcon, inactiveIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavBtn({required this.activeIcon, required this.inactiveIcon,
      required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onTap(); },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: RDur.sm,
              child: Icon(active ? activeIcon : inactiveIcon,
                  key: ValueKey(active),
                  color: active ? RColors.brand : RColors.text3, size: 26),
            ),
            const SizedBox(height: 3),
            Text(label, style: RText.label(color: active ? RColors.brand : RColors.text3)),
          ],
        ),
      ),
    );
  }
}

// ── Feed Skeleton ──────────────────────────────────────────────────────────────

class _FeedSkeleton extends StatelessWidget {
  final bool isWakingUp;
  const _FeedSkeleton({this.isWakingUp = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: RColors.bgCard)
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1400.ms, color: RColors.glassMd),
        const Positioned(
          bottom: 0, left: 0, right: 0, height: 420,
          child: DecoratedBox(decoration: BoxDecoration(gradient: RColors.overlayBottom)),
        ),
        Positioned(
          right: 14, bottom: 110,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Column(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: RColors.glass, border: Border.all(color: RColors.glassBorder)),
                ).animate(onPlay: (c) => c.repeat())
                    .shimmer(delay: Duration(milliseconds: i * 120), duration: 1400.ms, color: RColors.glassMd),
                const SizedBox(height: 6),
                Container(width: 28, height: 8,
                  decoration: BoxDecoration(color: RColors.glass, borderRadius: BorderRadius.circular(4))),
              ]),
            )),
          ),
        ),
        Positioned(
          left: 16, right: 80, bottom: 100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: double.infinity, height: 16,
                decoration: BoxDecoration(color: RColors.glass, borderRadius: BorderRadius.circular(8)))
                  .animate(onPlay: (c) => c.repeat()).shimmer(duration: 1400.ms, color: RColors.glassMd),
              const SizedBox(height: 8),
              Container(width: 160, height: 16,
                decoration: BoxDecoration(color: RColors.glass, borderRadius: BorderRadius.circular(8)))
                  .animate(onPlay: (c) => c.repeat()).shimmer(delay: 100.ms, duration: 1400.ms, color: RColors.glassMd),
              const SizedBox(height: 16),
              Container(width: 160, height: 38,
                decoration: BoxDecoration(
                  color: RColors.brand.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: RColors.brand.withOpacity(0.25)),
                )).animate(onPlay: (c) => c.repeat())
                  .shimmer(delay: 200.ms, duration: 1400.ms, color: RColors.brand.withOpacity(0.08)),
            ],
          ),
        ),
        if (isWakingUp)
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: RColors.bgRaised.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: RColors.glassBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: RColors.brand),
                            ),
                            const SizedBox(width: 10),
                            Text('Waking up server…', style: RText.body(size: 12, color: RColors.text2)),
                          ],
                        ),
                      ),
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
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle, color: RColors.bgRaised,
              border: Border.all(color: RColors.glassBorder),
            ),
            child: const Icon(Icons.wifi_off_rounded, color: RColors.text3, size: 30),
          ),
          const SizedBox(height: 16),
          Text('Could not load', style: RText.body(size: 16, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Check your connection', style: RText.body(size: 13, color: RColors.text3)),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 13),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [RColors.brand, RColors.brand2]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: RColors.brand.withOpacity(0.4), blurRadius: 16)],
              ),
              child: Text('Try Again', style: RText.body(size: 14, weight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
