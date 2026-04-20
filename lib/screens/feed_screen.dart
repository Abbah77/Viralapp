import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../controllers/feed_controller.dart';
import '../theme/tokens.dart';
import '../widgets/ambient_background.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/video_card.dart';
import '../widgets/action_button.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late final PageController _pageController;
  late final FeedController _feedController;
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _feedController = FeedController();
    _feedController.init();

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
    _pageController.dispose();
    _feedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _feedController,
      child: Scaffold(
        backgroundColor: ReelzColors.bg,
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: Consumer<FeedController>(
          builder: (context, controller, _) {
            return Stack(
              fit: StackFit.expand,
              children: [
                // ── Ambient background ──────────────────────────
                const AmbientBackground(),

                // ── Feed or skeleton ────────────────────────────
                if (controller.isLoading)
                  const SkeletonLoader()
                else if (controller.error != null && controller.videos.isEmpty)
                  _ErrorView(
                    error: controller.error!,
                    onRetry: controller.refresh,
                  )
                else
                  RefreshIndicator(
                    onRefresh: controller.refresh,
                    color: ReelzColors.brand,
                    backgroundColor: ReelzColors.bgRaised,
                    strokeWidth: 2,
                    child: PageView.builder(
                      controller: _pageController,
                      scrollDirection: Axis.vertical,
                      itemCount: controller.videos.length,
                      onPageChanged: controller.onPageChanged,
                      physics: const _ReelzScrollPhysics(),
                      itemBuilder: (context, index) {
                        return VideoCard(
                          key: ValueKey(controller.videos[index].id),
                          video: controller.videos[index],
                          index: index,
                          controller: controller,
                        );
                      },
                    ),
                  ),

                // ── Top header ──────────────────────────────────
                if (!controller.isLoading)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _TopHeader(),
                  ),
              ],
            );
          },
        ),
        bottomNavigationBar: _BottomNav(
          selectedIndex: _navIndex,
          onTap: (i) => setState(() => _navIndex = i),
        ),
      ),
    );
  }
}

// ── Top Header ──────────────────────────────────────────────────────────────

class _TopHeader extends StatelessWidget {
  const _TopHeader();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Logo wordmark
                  Text(
                    'Reelz',
                    style: ReelzTextStyles.wordmark(size: 22),
                  )
                      .animate()
                      .fadeIn(duration: ReelzDurations.lg)
                      .slideX(begin: -0.2, end: 0, curve: ReelzCurves.spring),

                  // Tabs center
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _HeaderTab(label: 'Following', active: false),
                        const SizedBox(width: 20),
                        _HeaderTab(label: 'For You', active: true),
                      ],
                    ),
                  ),

                  // Search icon
                  GestureDetector(
                    onTap: () => HapticFeedback.lightImpact(),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: ReelzColors.glass,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: ReelzColors.glassBorder,
                              width: 1,
                            ),
                          ),
                          child: ReelzIcons.search(color: ReelzColors.text),
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: ReelzDurations.lg)
                      .slideX(begin: 0.2, end: 0, curve: ReelzCurves.spring),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderTab extends StatelessWidget {
  final String label;
  final bool active;

  const _HeaderTab({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: ReelzTextStyles.body(
            size: active ? 15 : 14,
            weight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? ReelzColors.text : ReelzColors.text3,
          ),
        ),
        const SizedBox(height: 3),
        AnimatedContainer(
          duration: ReelzDurations.md,
          curve: ReelzCurves.spring,
          width: active ? 20 : 0,
          height: 2.5,
          decoration: BoxDecoration(
            color: active ? ReelzColors.brand : Colors.transparent,
            borderRadius: BorderRadius.circular(2),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: ReelzColors.brand.withOpacity(0.6),
                      blurRadius: 6,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
        ),
      ],
    );
  }
}

// ── Bottom Nav ───────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const _BottomNav({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: ReelzColors.bg.withOpacity(0.82),
            border: Border(
              top: BorderSide(
                color: ReelzColors.glassBorder,
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 58,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: ReelzIcons.home(filled: selectedIndex == 0),
                    label: 'Home',
                    active: selectedIndex == 0,
                    onTap: () => onTap(0),
                  ),
                  _NavItem(
                    icon: ReelzIcons.search(filled: selectedIndex == 1),
                    label: 'Explore',
                    active: selectedIndex == 1,
                    onTap: () => onTap(1),
                  ),

                  // Create button
                  GestureDetector(
                    onTap: () => HapticFeedback.heavyImpact(),
                    child: Container(
                      width: 46,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [ReelzColors.brand, ReelzColors.brand2],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: ReelzColors.brand.withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),

                  _NavItem(
                    icon: ReelzIcons.inbox(filled: selectedIndex == 3),
                    label: 'Inbox',
                    active: selectedIndex == 3,
                    onTap: () => onTap(3),
                  ),
                  _NavItem(
                    icon: ReelzIcons.profile(filled: selectedIndex == 4),
                    label: 'Profile',
                    active: selectedIndex == 4,
                    onTap: () => onTap(4),
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

class _NavItem extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
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
      child: AnimatedContainer(
        duration: ReelzDurations.md,
        curve: ReelzCurves.spring,
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedDefaultTextStyle(
              duration: ReelzDurations.md,
              style: TextStyle(
                color: active ? ReelzColors.brand : ReelzColors.text3,
              ),
              child: icon,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: ReelzTextStyles.navLabel.copyWith(
                color: active ? ReelzColors.brand : ReelzColors.text3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error view ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ReelzColors.bgRaised,
                border: Border.all(color: ReelzColors.glassBorder),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: ReelzColors.text3,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Could not load feed',
              style: ReelzTextStyles.body(
                size: 16,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: ReelzTextStyles.body(
                size: 13,
                color: ReelzColors.text3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [ReelzColors.brand, ReelzColors.brand2],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: ReelzColors.brand.withOpacity(0.4),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Text(
                  'Try again',
                  style: ReelzTextStyles.body(
                    size: 14,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        )
            .animate()
            .fadeIn(duration: ReelzDurations.lg)
            .scale(
              begin: const Offset(0.9, 0.9),
              curve: ReelzCurves.spring,
            ),
      ),
    );
  }
}

// ── Custom scroll physics — no bounce, pure snap ─────────────────────────────

class _ReelzScrollPhysics extends ScrollPhysics {
  const _ReelzScrollPhysics({super.parent});

  @override
  _ReelzScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _ReelzScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 50,
        stiffness: 200,
        damping: 1.1,
      );
}
