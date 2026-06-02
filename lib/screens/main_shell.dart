import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/coin_service.dart';
import '../theme/tokens.dart';
import 'explore_screen.dart';
import 'feed_screen.dart';
import 'quest_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with SingleTickerProviderStateMixin {
  int _tab = 0; // 0=Explore, 1=ForYou, 2=Quests, 3=Profile

  static const _screens = [
    ExploreScreen(),
    FeedScreen(),
    QuestScreen(),
    ProfileScreen(),
  ];

  void _onTap(int i) {
    if (i == _tab) return;
    HapticFeedback.selectionClick();
    setState(() => _tab = i);
  }

  @override
  Widget build(BuildContext context) {
    final coins = context.watch<CoinService>();
    final hasFlashOffer = coins.activeOffer != null && !coins.activeOffer!.isExpired;

    return Scaffold(
      backgroundColor: RColors.bg,
      body: IndexedStack(index: _tab, children: _screens),
      bottomNavigationBar: _BottomNav(
        currentIndex: _tab,
        onTap: _onTap,
        hasFlashOffer: hasFlashOffer,
        newUserActive: coins.newUserOfferActive,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool hasFlashOffer;
  final bool newUserActive;
  const _BottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.hasFlashOffer,
    required this.newUserActive,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(icon: Icons.grid_view_rounded,      activeIcon: Icons.grid_view_rounded,   label: 'Explore'),
      _NavItem(icon: Icons.play_circle_outline,    activeIcon: Icons.play_circle_filled,  label: 'For You'),
      _NavItem(icon: Icons.bolt_outlined,          activeIcon: Icons.bolt_rounded,        label: 'Earn',    badge: true),
      _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded,      label: 'Profile'),
    ];

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: RColors.bg.withOpacity(0.92),
            border: Border(top: BorderSide(color: RColors.glassBorder, width: 0.8)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 62,
              child: Row(
                children: items.asMap().entries.map((e) {
                  final idx = e.key;
                  final item = e.value;
                  final isActive = currentIndex == idx;
                  final showBadge = item.badge && (hasFlashOffer || newUserActive);

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTap(idx),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: RDur.md,
                        curve: RCurve.spring,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(clipBehavior: Clip.none, children: [
                              AnimatedSwitcher(
                                duration: RDur.sm,
                                child: Icon(
                                  isActive ? item.activeIcon : item.icon,
                                  key: ValueKey(isActive),
                                  color: isActive ? RColors.brand : RColors.text3,
                                  size: 24,
                                ),
                              ),
                              if (showBadge)
                                Positioned(
                                  top: -3, right: -3,
                                  child: Container(
                                    width: 8, height: 8,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFFF6B00),
                                    ),
                                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                                   .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 800.ms),
                                ),
                            ]),
                            const SizedBox(height: 3),
                            AnimatedDefaultTextStyle(
                              duration: RDur.sm,
                              style: RText.label(
                                size: 10,
                                color: isActive ? RColors.brand : RColors.text4,
                                letterSpacing: 0.2,
                              ),
                              child: Text(item.label),
                            ),
                            // Active indicator dot
                            AnimatedContainer(
                              duration: RDur.md,
                              curve: RCurve.spring,
                              margin: const EdgeInsets.only(top: 3),
                              width: isActive ? 16 : 0,
                              height: 2,
                              decoration: BoxDecoration(
                                color: RColors.brand,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool badge;
  const _NavItem({required this.icon, required this.activeIcon, required this.label, this.badge = false});
}
