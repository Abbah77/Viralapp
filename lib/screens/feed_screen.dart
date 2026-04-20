import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/feed_controller.dart';
import '../widgets/video_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late final PageController _pageController;
  late final FeedController _feedController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _feedController = FeedController();
    _feedController.init();

    // Full immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
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
        backgroundColor: Colors.black,
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: Consumer<FeedController>(
          builder: (context, controller, _) {
            if (controller.isLoading) {
              return const _LoadingScreen();
            }

            if (controller.error != null && controller.videos.isEmpty) {
              return _ErrorScreen(error: controller.error!);
            }

            return Stack(
              children: [
                // Main feed
                PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: controller.videos.length,
                  onPageChanged: controller.onPageChanged,
                  physics: const _FastPageScrollPhysics(),
                  itemBuilder: (context, index) {
                    return VideoCard(
                      video: controller.videos[index],
                      index: index,
                      controller: controller,
                    );
                  },
                ),

                // Top bar
                const _TopBar(),
              ],
            );
          },
        ),

        // Bottom nav
        bottomNavigationBar: const _BottomNav(),
      ),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TabText(label: 'Following', active: false),
              const SizedBox(width: 24),
              _TabText(label: 'For You', active: true),
              const SizedBox(width: 24),
              _TabText(label: 'Explore', active: false),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabText extends StatelessWidget {
  final String label;
  final bool active;

  const _TabText({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.white60,
            fontSize: active ? 16 : 14,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: active ? 0.3 : 0,
          ),
        ),
        if (active) ...[
          const SizedBox(height: 3),
          Container(
            width: 20,
            height: 2.5,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ],
    );
  }
}

class _BottomNav extends StatefulWidget {
  const _BottomNav();

  @override
  State<_BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<_BottomNav> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.08), width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(icon: Icons.home_rounded, label: 'Home', index: 0, selected: _selected, onTap: (i) => setState(() => _selected = i)),
            _NavItem(icon: Icons.search_rounded, label: 'Explore', index: 1, selected: _selected, onTap: (i) => setState(() => _selected = i)),
            _PostButton(),
            _NavItem(icon: Icons.notifications_none_rounded, label: 'Inbox', index: 3, selected: _selected, onTap: (i) => setState(() => _selected = i)),
            _NavItem(icon: Icons.person_outline_rounded, label: 'Profile', index: 4, selected: _selected, onTap: (i) => setState(() => _selected = i)),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int selected;
  final Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selected;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white54,
              size: 26,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 44,
        height: 30,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF25F4EE), Color(0xFFFE2C55)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Icon(Icons.add, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              color: Color(0xFFFE2C55),
              strokeWidth: 2.5,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Loading feed...',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String error;
  const _ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white38, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Could not load feed',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Ultra smooth page scroll physics
class _FastPageScrollPhysics extends ScrollPhysics {
  const _FastPageScrollPhysics({super.parent});

  @override
  _FastPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _FastPageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
    mass: 80,
    stiffness: 100,
    damping: 1,
  );
}
