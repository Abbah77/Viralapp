import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/tokens.dart';

class ActionButton extends StatefulWidget {
  final Widget icon;
  final Widget? activeIcon;
  final String label;
  final bool isLike;
  final VoidCallback? onTap;

  const ActionButton({
    super.key,
    required this.icon,
    this.activeIcon,
    required this.label,
    this.isLike = false,
    this.onTap,
  });

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  bool _active = false;
  bool _pressed = false;

  void _handleTap() {
    HapticFeedback.lightImpact();
    setState(() => _active = !_active);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.isLike ? ReelzColors.like : ReelzColors.brand;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        _handleTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: ReelzDurations.xs,
        curve: ReelzCurves.spring,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glass button
            ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: AnimatedContainer(
                  duration: ReelzDurations.md,
                  curve: ReelzCurves.spring,
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _active
                        ? activeColor.withOpacity(0.18)
                        : ReelzColors.glass,
                    border: Border.all(
                      color: _active
                          ? activeColor.withOpacity(0.35)
                          : ReelzColors.glassBorder,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: ReelzDurations.sm,
                      switchInCurve: ReelzCurves.spring,
                      switchOutCurve: ReelzCurves.easeOut,
                      transitionBuilder: (child, anim) => ScaleTransition(
                        scale: anim,
                        child: child,
                      ),
                      child: _active && widget.activeIcon != null
                          ? KeyedSubtree(
                              key: const ValueKey('active'),
                              child: widget.activeIcon!,
                            )
                          : KeyedSubtree(
                              key: const ValueKey('inactive'),
                              child: widget.icon,
                            ),
                    ),
                  ),
                ),
              ),
            )
                .animate(target: _active ? 1 : 0)
                .boxShadow(
                  duration: ReelzDurations.md,
                  curve: ReelzCurves.easeOut,
                  begin: const BoxShadow(color: Colors.transparent),
                  end: BoxShadow(
                    color: activeColor.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ),

            const SizedBox(height: 5),

            // Label
            Text(
              widget.label,
              style: ReelzTextStyles.actionCount.copyWith(
                color: _active ? activeColor : ReelzColors.text2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// SVG Icons as Flutter widgets
class ReelzIcons {
  static Widget heart({bool filled = false, Color color = ReelzColors.text}) {
    return filled
        ? Icon(Icons.favorite_rounded, color: color, size: 22)
        : Icon(Icons.favorite_border_rounded, color: color, size: 22);
  }

  static Widget comment({Color color = ReelzColors.text}) {
    return Icon(Icons.chat_bubble_outline_rounded, color: color, size: 21);
  }

  static Widget share({Color color = ReelzColors.text}) {
    return Icon(Icons.reply_rounded, color: color, size: 22,
        textDirection: TextDirection.rtl);
  }

  static Widget bookmark({bool filled = false, Color color = ReelzColors.text}) {
    return filled
        ? Icon(Icons.bookmark_rounded, color: color, size: 22)
        : Icon(Icons.bookmark_border_rounded, color: color, size: 22);
  }

  static Widget home({bool filled = false, Color color = ReelzColors.text}) {
    return filled
        ? Icon(Icons.home_rounded, color: color, size: 26)
        : Icon(Icons.home_outlined, color: color, size: 26);
  }

  static Widget search({bool filled = false, Color color = ReelzColors.text}) {
    return filled
        ? Icon(Icons.search_rounded, color: color, size: 26)
        : Icon(Icons.search_outlined, color: color, size: 26);
  }

  static Widget inbox({bool filled = false, Color color = ReelzColors.text}) {
    return filled
        ? Icon(Icons.notifications_rounded, color: color, size: 26)
        : Icon(Icons.notifications_outlined, color: color, size: 26);
  }

  static Widget profile({bool filled = false, Color color = ReelzColors.text}) {
    return filled
        ? Icon(Icons.person_rounded, color: color, size: 26)
        : Icon(Icons.person_outlined, color: color, size: 26);
  }

  static Widget play({Color color = ReelzColors.text}) =>
      Icon(Icons.play_arrow_rounded, color: color, size: 36);

  static Widget pause({Color color = ReelzColors.text}) =>
      Icon(Icons.pause_rounded, color: color, size: 36);
}
