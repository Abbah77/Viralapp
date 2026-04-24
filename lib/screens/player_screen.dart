import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';
import 'package:screen_brightness/screen_brightness.dart';
import '../controllers/player_controller.dart';
import '../theme/tokens.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final VideoController _vc;
  double _brightness = 0.5;

  @override
  void initState() {
    super.initState();
    _vc = VideoController(context.read<PlayerController>().player);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _loadBrightness();
  }

  Future<void> _loadBrightness() async {
    try {
      _brightness = await ScreenBrightness().current;
      setState(() {});
    } catch (_) {}
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerController>(
      builder: (context, ctrl, _) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            onTap: ctrl.isLocked ? null : ctrl.toggleControls,
            onLongPress: () {
              HapticFeedback.mediumImpact();
              ctrl.toggleToolsDrawer();
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Video
                Hero(
                  tag: 'video_${ctrl.movie.id}',
                  child: Video(
                    controller: _vc,
                    controls: NoVideoControls,
                    fit: ctrl.isLandscape ? BoxFit.contain : BoxFit.cover,
                  ),
                ),

                // Buffering indicator
                if (ctrl.isBuffering)
                  const Center(
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        color: RColors.brand,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),

                // Controls overlay (portrait)
                if (!ctrl.isLandscape)
                  _PortraitControls(ctrl: ctrl)
                else
                  _LandscapeControls(ctrl: ctrl),

                // Episode drawer
                if (ctrl.showDrawer) _EpisodeDrawer(ctrl: ctrl),

                // Tools drawer
                if (ctrl.showToolsDrawer)
                  _ToolsDrawer(
                    ctrl: ctrl,
                    brightness: _brightness,
                    onBrightnessChange: (v) async {
                      setState(() => _brightness = v);
                      try {
                        await ScreenBrightness().setScreenBrightness(v);
                      } catch (_) {}
                    },
                  ),

                // Lock indicator
                if (ctrl.isLocked)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onLongPress: ctrl.toggleLock,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: RColors.bgRaised.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: RColors.glassBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock_rounded,
                                  color: RColors.text2, size: 16),
                              const SizedBox(width: 8),
                              Text('Hold to unlock',
                                  style: RText.label(color: RColors.text2)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Portrait Controls ────────────────────────────────────────────────────────

class _PortraitControls extends StatelessWidget {
  final PlayerController ctrl;
  const _PortraitControls({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: ctrl.showControls ? 1.0 : 0.0,
      duration: RDur.md,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: const BoxDecoration(
                  gradient: RColors.overlayTop,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: RColors.text, size: 20),
                    ),
                    Expanded(
                      child: Text(
                        ctrl.movie.title,
                        style: RText.body(
                          size: 14,
                          weight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.bookmark_border_rounded,
                          color: RColors.text, size: 22),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Center play/pause
          Center(
            child: GestureDetector(
              onTap: ctrl.togglePlayPause,
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: RColors.glassMd,
                      border: Border.all(color: RColors.glassBorderMd),
                    ),
                    child: Icon(
                      ctrl.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: RColors.text,
                      size: 34,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Right actions
          Positioned(
            right: 12,
            top: 0,
            bottom: 80,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PlayerAction(
                  icon: Icons.favorite_border_rounded,
                  label: 'Like',
                  onTap: () => HapticFeedback.lightImpact(),
                ),
                const SizedBox(height: 20),
                _PlayerAction(
                  icon: Icons.share_rounded,
                  label: 'Share',
                  onTap: () => HapticFeedback.lightImpact(),
                ),
                const SizedBox(height: 20),
                _PlayerAction(
                  icon: Icons.people_outline_rounded,
                  label: 'Episodes',
                  onTap: ctrl.toggleDrawer,
                ),
              ],
            ),
          ),

          // Bottom — progress + episode info
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding:
                  const EdgeInsets.only(left: 16, right: 16, bottom: 24, top: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Episode label + time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'EP ${ctrl.currentEp + 1} of ${ctrl.totalEpisodes}',
                        style: RText.label(color: RColors.brand),
                      ),
                      Text(
                        '${ctrl.positionLabel} / ${ctrl.durationLabel}',
                        style: RText.label(color: RColors.text2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Progress bar
                  _ProgressBar(ctrl: ctrl),

                  const SizedBox(height: 12),

                  // Bottom actions row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Skip back
                      GestureDetector(
                        onTap: () => ctrl.seekRelative(-10),
                        child: Row(
                          children: [
                            const Icon(Icons.replay_10_rounded,
                                color: RColors.text2, size: 22),
                            const SizedBox(width: 4),
                            Text('10s', style: RText.label()),
                          ],
                        ),
                      ),

                      // Episodes drawer btn
                      GestureDetector(
                        onTap: ctrl.toggleDrawer,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: RColors.glass,
                                borderRadius: BorderRadius.circular(20),
                                border:
                                    Border.all(color: RColors.glassBorderMd),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.list_rounded,
                                      color: RColors.text, size: 18),
                                  const SizedBox(width: 6),
                                  Text('Episodes',
                                      style: RText.body(
                                          size: 13,
                                          weight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Skip forward
                      GestureDetector(
                        onTap: () => ctrl.seekRelative(10),
                        child: Row(
                          children: [
                            Text('10s', style: RText.label()),
                            const SizedBox(width: 4),
                            const Icon(Icons.forward_10_rounded,
                                color: RColors.text2, size: 22),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Progress Bar ─────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final PlayerController ctrl;
  const _ProgressBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 2.5,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        activeTrackColor: RColors.brand,
        inactiveTrackColor: RColors.glassMd,
        thumbColor: Colors.white,
        overlayColor: RColors.brand.withOpacity(0.2),
      ),
      child: Slider(
        value: ctrl.episodeProgress.clamp(0.0, 1.0),
        onChanged: (v) {
          ctrl.showControlsTemporary();
          ctrl.seekEpisodeProgress(v);
        },
      ),
    );
  }
}

// ── Landscape Controls ───────────────────────────────────────────────────────

class _LandscapeControls extends StatelessWidget {
  final PlayerController ctrl;
  const _LandscapeControls({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: ctrl.showControls ? 1.0 : 0.0,
      duration: RDur.md,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Top bar — title + back only
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: const BoxDecoration(gradient: RColors.overlayTop),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => ctrl.toggleOrientation(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: RColors.text, size: 18),
                  ),
                  Expanded(
                    child: Text(
                      ctrl.movie.title,
                      style: RText.body(size: 14, weight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Center play/pause
          Center(
            child: GestureDetector(
              onTap: ctrl.togglePlayPause,
              child: Icon(
                ctrl.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.white.withOpacity(0.9),
                size: 52,
              ),
            ),
          ),

          // Bottom — progress only
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.75),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(ctrl.positionLabel, style: RText.label()),
                      Text(ctrl.durationLabel, style: RText.label()),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _ProgressBar(ctrl: ctrl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Episode Drawer ───────────────────────────────────────────────────────────

class _EpisodeDrawer extends StatelessWidget {
  final PlayerController ctrl;
  const _EpisodeDrawer({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ctrl.toggleDrawer,
      child: Container(
        color: Colors.black54,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {}, // prevent close on drawer tap
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.55,
                  decoration: BoxDecoration(
                    color: RColors.bgCard.withOpacity(0.92),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border(
                      top: BorderSide(color: RColors.glassBorderMd, width: 1),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 16),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: RColors.glassMd,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Episodes',
                              style: RText.body(
                                size: 16,
                                weight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${ctrl.totalEpisodes} Episodes',
                              style: RText.label(color: RColors.text3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Episode grid — numbers only like TikTok
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.4,
                          ),
                          itemCount: ctrl.totalEpisodes,
                          itemBuilder: (_, i) {
                            final isCurrent = ctrl.currentEp == i;
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                ctrl.playEpisode(i);
                                ctrl.toggleDrawer();
                              },
                              child: AnimatedContainer(
                                duration: RDur.sm,
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? RColors.brand.withOpacity(0.2)
                                      : RColors.glass,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isCurrent
                                        ? RColors.brand
                                        : RColors.glassBorder,
                                    width: isCurrent ? 1.5 : 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '${i + 1}',
                                    style: RText.body(
                                      size: 14,
                                      weight: isCurrent
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isCurrent
                                          ? RColors.brand
                                          : RColors.text2,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: RDur.sm)
        .slideY(begin: 0.3, end: 0, duration: RDur.md, curve: RCurve.spring);
  }
}

// ── Tools Drawer ─────────────────────────────────────────────────────────────

class _ToolsDrawer extends StatelessWidget {
  final PlayerController ctrl;
  final double brightness;
  final Function(double) onBrightnessChange;

  const _ToolsDrawer({
    required this.ctrl,
    required this.brightness,
    required this.onBrightnessChange,
  });

  @override
  Widget build(BuildContext context) {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

    return GestureDetector(
      onTap: ctrl.toggleToolsDrawer,
      child: Container(
        color: Colors.black54,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: RColors.bgCard.withOpacity(0.94),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border(
                      top: BorderSide(color: RColors.glassBorderMd, width: 1),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: RColors.glassMd,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Speed
                      Text('Playback Speed',
                          style:
                              RText.label(size: 12, color: RColors.text3)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: speeds.map((s) {
                          final active = ctrl.speed == s;
                          return GestureDetector(
                            onTap: () => ctrl.setSpeed(s),
                            child: AnimatedContainer(
                              duration: RDur.sm,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: active
                                    ? RColors.brand.withOpacity(0.2)
                                    : RColors.glass,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: active
                                      ? RColors.brand
                                      : RColors.glassBorder,
                                ),
                              ),
                              child: Text(
                                '${s}x',
                                style: RText.body(
                                  size: 13,
                                  weight: FontWeight.w700,
                                  color: active ? RColors.brand : RColors.text2,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),

                      // Brightness
                      Text('Brightness',
                          style: RText.label(size: 12, color: RColors.text3)),
                      Row(
                        children: [
                          const Icon(Icons.brightness_low_rounded,
                              color: RColors.text3, size: 18),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 2,
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6),
                                activeTrackColor: RColors.brand,
                                inactiveTrackColor: RColors.glassMd,
                                thumbColor: Colors.white,
                                overlayColor:
                                    RColors.brand.withOpacity(0.15),
                              ),
                              child: Slider(
                                value: brightness,
                                onChanged: onBrightnessChange,
                              ),
                            ),
                          ),
                          const Icon(Icons.brightness_high_rounded,
                              color: RColors.text2, size: 18),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Tools row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _ToolBtn(
                            icon: ctrl.isLandscape
                                ? Icons.stay_current_portrait_rounded
                                : Icons.stay_current_landscape_rounded,
                            label: ctrl.isLandscape ? 'Portrait' : 'Landscape',
                            onTap: () {
                              ctrl.toggleOrientation();
                              ctrl.toggleToolsDrawer();
                            },
                          ),
                          _ToolBtn(
                            icon: ctrl.isLocked
                                ? Icons.lock_open_rounded
                                : Icons.lock_rounded,
                            label: ctrl.isLocked ? 'Unlock' : 'Lock',
                            onTap: () {
                              ctrl.toggleLock();
                              ctrl.toggleToolsDrawer();
                            },
                          ),
                          _ToolBtn(
                            icon: Icons.skip_next_rounded,
                            label: 'Skip Intro',
                            onTap: () {
                              ctrl.skipIntro();
                              ctrl.toggleToolsDrawer();
                            },
                          ),
                          _ToolBtn(
                            icon: Icons.fast_forward_rounded,
                            label: 'Next Ep',
                            onTap: () {
                              ctrl.playEpisode(ctrl.currentEp + 1);
                              ctrl.toggleToolsDrawer();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: RDur.sm)
        .slideY(begin: 0.3, end: 0, duration: RDur.md, curve: RCurve.spring);
  }
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: RColors.glass,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: RColors.glassBorder),
            ),
            child: Icon(icon, color: RColors.text, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: RText.label()),
        ],
      ),
    );
  }
}

class _PlayerAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PlayerAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: RColors.glass,
                  border: Border.all(color: RColors.glassBorder),
                ),
                child: Icon(icon, color: RColors.text, size: 21),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(label, style: RText.label()),
        ],
      ),
    );
  }
}
