import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/tokens.dart';

class SkeletonLoader extends StatelessWidget {
  const SkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ReelzColors.bg,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Shimmer background
          Container(color: ReelzColors.bgCard)
              .animate(onPlay: (c) => c.repeat())
              .shimmer(
                duration: 1200.ms,
                color: ReelzColors.glassMd,
              ),

          // Gradient overlay
          Container(
            decoration: const BoxDecoration(
              gradient: ReelzColors.overlayBottom,
            ),
          ),

          // Right side skeleton actions
          Positioned(
            right: 14,
            bottom: 110,
            child: Column(
              children: List.generate(4, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 22),
                  child: Column(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: ReelzColors.glass,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ReelzColors.glassBorder,
                            width: 1,
                          ),
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat())
                          .shimmer(
                            delay: Duration(milliseconds: i * 100),
                            duration: 1200.ms,
                            color: ReelzColors.glassMd,
                          ),
                      const SizedBox(height: 5),
                      Container(
                        width: 28,
                        height: 8,
                        decoration: BoxDecoration(
                          color: ReelzColors.glass,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),

          // Bottom left caption skeleton
          Positioned(
            left: 16,
            right: 80,
            bottom: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: BoxDecoration(
                    color: ReelzColors.glass,
                    borderRadius: BorderRadius.circular(7),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(duration: 1200.ms, color: ReelzColors.glassMd),
                const SizedBox(height: 8),
                Container(
                  width: 200,
                  height: 14,
                  decoration: BoxDecoration(
                    color: ReelzColors.glass,
                    borderRadius: BorderRadius.circular(7),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(
                      delay: 100.ms,
                      duration: 1200.ms,
                      color: ReelzColors.glassMd,
                    ),
                const SizedBox(height: 10),
                Container(
                  width: 150,
                  height: 12,
                  decoration: BoxDecoration(
                    color: ReelzColors.glass,
                    borderRadius: BorderRadius.circular(6),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(
                      delay: 200.ms,
                      duration: 1200.ms,
                      color: ReelzColors.glassMd,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
