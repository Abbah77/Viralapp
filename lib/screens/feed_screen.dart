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

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  int _navIndex = 0;
  late final FeedController _fc;

  final _screens = const [
    _FeedView(),
    ExploreScreen(),
    ProfileScreen(),
  ];

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
  void dispose() {
    _fc.dispose();
    super.dispose();
  }

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
          children: _screens,
        ),
        bottomNavigationBar: _navIndex == 0
            ? _BottomNav(
                index: _navIndex,
                onTap: (i) => setState(() => _navIndex = i),
              )
            : null,
      ),
    );
  }
}

class _FeedView extends StatefulWidget {
  const _FeedView();

  @override
  State<_FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<_FeedView> {
  final _pageCtrl = PageController();

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FeedController>(
      builder: (_, ctrl, __) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Ambient
            const AmbientBg(),

            if (ctrl.isLoading)
              const _Skeleton()
            else if (ctrl.error != null && ctrl.videos.isEmpty)
              _ErrorView(onRetry: ctrl.refresh)
            else
              RefreshIndicator(
                onRefresh: ctrl.refresh,
                color: RColors.brand,
                backgroundColor: RColors.bgRaised,
                child: PageView.builder(
                  controller: _pageCtrl,
                  scrollDirection: Axis.vertical,
                  itemCount: ctrl.videos.length,
                  onPageChanged: ctrl.onPageChanged,
                  physics: const PageScrollPhysics(),
                  itemBuilder: (_, i) => ChangeNotifierProvider.value(
                    value: ctrl,
                    child: FeedCard(
                      key: ValueKey(ctrl.videos[i].id),
                      video: ctrl.videos[i],
                      index: i,
                    ),
                  ),
                ),
              ),

            // Top bar
            if (!ctrl.isLoading) const _TopBar(),
          ],
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 52,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('Reelz', style: RText.wordmark())
                    .animate()
                    .fadeIn(duration: RDur.lg)
                    .slideX(begin: -0.2, end: 0, curve: RCurve.spring),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Tab(label: 'Following', active: false),
                      const SizedBox(width: 20),
                      _Tab(label: 'For You', active: true),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const ExploreScreen()),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: RColors.glass,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: RColors.glassBorder),
                        ),
                        child: const Icon(Icons.search_rounded,
                            color: RColors.text, size: 20),
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: RDur.lg)
                    .slideX(begin: 0.2, end: 0, curve: RCurve.spring),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  const _Tab({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: RText.body(
            size: active ? 15 : 14,
            weight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? RColors.text : RColors.text3,
          ),
        ),
        const SizedBox(height: 3),
        AnimatedContainer(
          duration: RDur.md,
          curve: RCurve.spring,
          width: active ? 18 : 0,
          height: 2.5,
          decoration: BoxDecoration(
            color: active ? RColors.brand : Colors.transparent,
            borderRadius: BorderRadius.circular(2),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: RColors.brand.withOpacity(0.6),
                      blurRadius: 6,
                    )
                  ]
                : null,
          ),
        ),
      ],
    );
  }
}

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
            color: RColors.bg.withOpacity(0.82),
            border: Border(
                top: BorderSide(color: RColors.glassBorder, width: 0.5)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 58,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavBtn(
                    icon: index == 0
                        ? Icons.home_rounded
                        : Icons.home_outlined,
                    label: 'Home',
                    active: index == 0,
                    onTap: () => onTap(0),
                  ),
                  _NavBtn(
                    icon: index == 1
                        ? Icons.explore_rounded
                        : Icons.explore_outlined,
                    label: 'Explore',
                    active: index == 1,
                    onTap: () => onTap(1),
                  ),
                  // Post button
                  GestureDetector(
                    onTap: () => HapticFeedback.heavyImpact(),
                    child: Container(
                      width: 46,
                      height: 30,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [RColors.brand, RColors.brand2],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: RColors.brand.withOpacity(0.4),
                            blurRadius: 12,
                          )
                        ],
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                  _NavBtn(
                    icon: index == 2
                        ? Icons.person_rounded
                        : Icons.person_outline_rounded,
                    label: 'Profile',
                    active: index == 2,
                    onTap: () => onTap(2),
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

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: active ? RColors.brand : RColors.text3, size: 26),
            const SizedBox(height: 3),
            Text(
              label,
              style: RText.label(
                  color: active ? RColors.brand : RColors.text3),
            ),
          ],
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return Container(color: RColors.bgCard)
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1200.ms, color: RColors.glassMd);
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: RColors.text3, size: 48),
          const SizedBox(height: 16),
          Text('Could not load',
              style: RText.body(size: 16, weight: FontWeight.w700)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [RColors.brand, RColors.brand2]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: RColors.brand.withOpacity(0.4), blurRadius: 16)
                ],
              ),
              child: Text('Retry',
                  style: RText.body(size: 14, weight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
