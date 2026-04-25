import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';
import 'package:screen_brightness/screen_brightness.dart';
import '../controllers/player_controller.dart';
import '../controllers/settings_controller.dart';
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
    final ctrl = context.read<PlayerController>();
    _vc = VideoController(ctrl.player);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _loadBrightness();

    // Listen for episode end → auto next
    ctrl.player.stream.position.listen((pos) {
      final settings = context.read<SettingsController>();
      if (!settings.autoNextEpisode) return;
      final ep = ctrl.episode;
      if (pos.inSeconds >= ep.endSec - 1 &&
          ctrl.currentEp < ctrl.totalEpisodes - 1) {
        ctrl.playEpisode(ctrl.currentEp + 1);
      }
    });
  }

  Future<void> _loadBrightness() async {
    try {
      _brightness = await ScreenBrightness().current;
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerController>(
      builder: (_, ctrl, __) {
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

                // Buffering
                if (ctrl.isBuffering)
                  Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          color: RColors.brand,
                          strokeWidth: 2.5,
                        ),
                      ),
                    ),
                  ),

                // Controls
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

                // Lock overlay
                if (ctrl.isLocked)
                  Positioned.fill(
                    child: GestureDetector(
                      onLongPress: ctrl.toggleLock,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 11),
                          decoration: BoxDecoration(
                            color: RColors.bgRaised.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: RColors.glassBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock_rounded,
                                  color: RColors.text2, size: 15),
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

// ── Portrait Controls ─────────────────────────────────────────────────────────

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
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: const BoxDecoration(gradient: RColors.overlayTop),
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
                        style: RText.body(size: 14, weight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Episode indicator pill
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: RColors.brand.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: RColors.brand.withOpacity(0.35)),
                      ),
                      child: Text(
                        'EP ${ctrl.currentEp + 1}/${ctrl.totalEpisodes}',
                        style: RText.label(color: RColors.brand),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Double tap seek zones
          Positioned.fill(
            child: Row(
              children: [
                // Left — seek back
                Expanded(
                  child: GestureDetector(
                    onDoubleTap: () {
                      ctrl.seekRelative(-10);
                      ctrl.showControlsTemporary();
                    },
                    child: Container(color: Colors.transparent),
                  ),
                ),
                // Center — play/pause
                GestureDetector(
                  onTap: ctrl.togglePlayPause,
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: AnimatedContainer(
                        duration: RDur.sm,
                        width: 64,
                        height: 64,
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
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
                // Right — seek forward
                Expanded(
                  child: GestureDetector(
                    onDoubleTap: () {
                      ctrl.seekRelative(10);
                      ctrl.showControlsTemporary();
                    },
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ],
            ),
          ),

          // Right side actions — like feed
          Positioned(
            right: 12,
            bottom: 110,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PlayerActionBtn(
                  icon: Icons.favorite_border_rounded,
                  label: 'Like',
                  activeIcon: Icons.favorite_rounded,
                  activeColor: RColors.like,
                ),
                const SizedBox(height: 22),
                _PlayerActionBtn(
                  icon: Icons.share_rounded,
                  label: 'Share',
                ),
                const SizedBox(height: 22),
                _PlayerActionBtn(
                  icon: Icons.bookmark_border_rounded,
                  label: 'Save',
                  activeIcon: Icons.bookmark_rounded,
                  activeColor: RColors.brand,
                ),
              ],
            )
                .animate()
                .fadeIn(delay: 100.ms, duration: RDur.lg)
                .slideX(begin: 0.4, end: 0, curve: RCurve.spring),
          ),

          // Bottom controls
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.85),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Time row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(ctrl.positionLabel,
                          style: RText.label(color: RColors.text2)),
                      Text(ctrl.durationLabel,
                          style: RText.label(color: RColors.text3)),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Seek bar
                  _SeekBar(ctrl: ctrl),

                  const SizedBox(height: 14),

                  // Bottom actions row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Skip back 10s
                      _SeekBtn(
                        icon: Icons.replay_10_rounded,
                        label: '-10s',
                        onTap: () => ctrl.seekRelative(-10),
                      ),

                      // Episodes toggle
                      GestureDetector(
                        onTap: ctrl.toggleDrawer,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: BackdropFilter(
                            filter:
                                ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 9),
                              decoration: BoxDecoration(
                                color: RColors.glass,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                    color: RColors.glassBorderMd),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.list_rounded,
                                      color: RColors.text, size: 17),
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

                      // Skip forward 10s
                      _SeekBtn(
                        icon: Icons.forward_10_rounded,
                        label: '+10s',
                        onTap: () => ctrl.seekRelative(10),
                        reverse: true,
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

// ── Landscape Controls ────────────────────────────────────────────────────────

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
          // Top — back + title only (MX Player style)
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                  // Episode pill
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: RColors.brand.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: RColors.brand.withOpacity(0.35)),
                    ),
                    child: Text(
                      'EP ${ctrl.currentEp + 1}/${ctrl.totalEpisodes}',
                      style: RText.label(color: RColors.brand),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Double tap zones + center play
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onDoubleTap: () => ctrl.seekRelative(-10),
                    child: Container(color: Colors.transparent),
                  ),
                ),
                GestureDetector(
                  onTap: ctrl.togglePlayPause,
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        width: 60,
                        height: 60,
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
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onDoubleTap: () => ctrl.seekRelative(10),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ],
            ),
          ),

          // Bottom — progress + time only
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
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
                  Row(
                    children: [
                      Text(ctrl.positionLabel,
                          style: RText.label(color: RColors.text2)),
                      const Spacer(),
                      // Episodes button in landscape too
                      GestureDetector(
                        onTap: ctrl.toggleDrawer,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: RColors.glass,
                            borderRadius: BorderRadius.circular(16),
                            border:
                                Border.all(color: RColors.glassBorderMd),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.list_rounded,
                                  color: RColors.text, size: 14),
                              const SizedBox(width: 4),
                              Text('EP',
                                  style: RText.label(color: RColors.text)),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(ctrl.durationLabel,
                          style: RText.label(color: RColors.text3)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _SeekBar(ctrl: ctrl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Seek Bar ──────────────────────────────────────────────────────────────────

class _SeekBar extends StatelessWidget {
  final PlayerController ctrl;
  const _SeekBar({required this.ctrl});

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

// ── Seek Button ───────────────────────────────────────────────────────────────

class _SeekBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool reverse;

  const _SeekBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.reverse = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: reverse
            ? [
                Text(label, style: RText.label(color: RColors.text3)),
                const SizedBox(width: 4),
                Icon(icon, color: RColors.text2, size: 22),
              ]
            : [
                Icon(icon, color: RColors.text2, size: 22),
                const SizedBox(width: 4),
                Text(label, style: RText.label(color: RColors.text3)),
              ],
      ),
    );
  }
}

// ── Player Action Button (right side like feed) ───────────────────────────────

class _PlayerActionBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final IconData? activeIcon;
  final Color? activeColor;

  const _PlayerActionBtn({
    required this.icon,
    required this.label,
    this.activeIcon,
    this.activeColor,
  });

  @override
  State<_PlayerActionBtn> createState() => _PlayerActionBtnState();
}

class _PlayerActionBtnState extends State<_PlayerActionBtn> {
  bool _active = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color =
        _active && widget.activeColor != null ? widget.activeColor! : RColors.text;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() {
          _pressed = false;
          _active = !_active;
        });
        HapticFeedback.lightImpact();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.84 : 1.0,
        duration: RDur.xs,
        curve: RCurve.spring,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: AnimatedContainer(
                  duration: RDur.md,
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _active && widget.activeColor != null
                        ? widget.activeColor!.withOpacity(0.18)
                        : RColors.glass,
                    border: Border.all(
                      color: _active && widget.activeColor != null
                          ? widget.activeColor!.withOpacity(0.4)
                          : RColors.glassBorder,
                    ),
                    boxShadow: _active && widget.activeColor != null
                        ? [
                            BoxShadow(
                              color: widget.activeColor!.withOpacity(0.4),
                              blurRadius: 18,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                  child: Icon(
                    _active && widget.activeIcon != null
                        ? widget.activeIcon!
                        : widget.icon,
                    color: color,
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(widget.label, style: RText.label()),
          ],
        ),
      ),
    );
  }
}

// ── Episode Drawer ────────────────────────────────────────────────────────────

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
            onTap: () {},
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.52,
                  decoration: BoxDecoration(
                    color: RColors.bgCard.withOpacity(0.94),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border(
                      top: BorderSide(
                          color: RColors.glassBorderMd, width: 0.8),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 14),
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                            color: RColors.glassMd,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Episodes',
                                style: RText.body(
                                    size: 16, weight: FontWeight.w700)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: RColors.glass,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: RColors.glassBorder),
                              ),
                              child: Text(
                                '${ctrl.totalEpisodes} Episodes',
                                style: RText.label(color: RColors.text3),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Episode number grid
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
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
                                  borderRadius:
                                      BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isCurrent
                                        ? RColors.brand
                                        : RColors.glassBorder,
                                    width: isCurrent ? 1.5 : 1,
                                  ),
                                  boxShadow: isCurrent
                                      ? [
                                          BoxShadow(
                                            color: RColors.brand
                                                .withOpacity(0.3),
                                            blurRadius: 8,
                                          )
                                        ]
                                      : null,
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

// ── Tools Drawer ──────────────────────────────────────────────────────────────

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
    final settings = context.watch<SettingsController>();

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
                    color: RColors.bgCard.withOpacity(0.96),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border(
                      top: BorderSide(
                          color: RColors.glassBorderMd, width: 0.8),
                    ),
                  ),
                  padding:
                      const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                            color: RColors.glassMd,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Speed
                      Text('Speed',
                          style: RText.label(
                              size: 11, color: RColors.text3)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: speeds.map((s) {
                          final active = ctrl.speed == s;
                          return GestureDetector(
                            onTap: () => ctrl.setSpeed(s),
                            child: AnimatedContainer(
                              duration: RDur.sm,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 11, vertical: 8),
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
                                  color: active
                                      ? RColors.brand
                                      : RColors.text2,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),

                      // Brightness
                      Text('Brightness',
                          style: RText.label(
                              size: 11, color: RColors.text3)),
                      Row(
                        children: [
                          const Icon(Icons.brightness_low_rounded,
                              color: RColors.text3, size: 18),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 2,
                                thumbShape:
                                    const RoundSliderThumbShape(
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

                      // Tools grid
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceAround,
                        children: [
                          _ToolBtn(
                            icon: ctrl.isLandscape
                                ? Icons.stay_current_portrait_rounded
                                : Icons.stay_current_landscape_rounded,
                            label: ctrl.isLandscape
                                ? 'Portrait'
                                : 'Landscape',
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
                            icon: settings.autoNextEpisode
                                ? Icons.repeat_one_rounded
                                : Icons.repeat_rounded,
                            label: settings.autoNextEpisode
                                ? 'Auto: On'
                                : 'Auto: Off',
                            active: settings.autoNextEpisode,
                            onTap: () {
                              settings.setAutoNextEpisode(
                                  !settings.autoNextEpisode);
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
  final bool active;

  const _ToolBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
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
          AnimatedContainer(
            duration: RDur.sm,
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: active
                  ? RColors.brand.withOpacity(0.18)
                  : RColors.glass,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active ? RColors.brand : RColors.glassBorder,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: RColors.brand.withOpacity(0.3),
                        blurRadius: 10,
                      )
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: active ? RColors.brand : RColors.text,
              size: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: RText.label()),
        ],
      ),
    );
  }
}
