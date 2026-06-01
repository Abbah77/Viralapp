import 'dart:async';
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
import '../widgets/dot_loader.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final VideoController _vc;
  double _brightness = 0.5;
  late final PageController _epPageCtrl;

  // Auto-next countdown
  bool _showAutoNext = false;
  int _autoNextCount = 3;
  Timer? _autoNextTimer;

  // Double-tap seek ripple
  bool _showLeftRipple = false;
  bool _showRightRipple = false;

  // Swipe-to-seek state
  double? _seekDragStart;
  double _seekDragDelta = 0;
  bool _isSeeking = false;

  @override
  void initState() {
    super.initState();
    final ctrl = context.read<PlayerController>();
    _vc = VideoController(ctrl.player);
    _epPageCtrl = PageController(initialPage: ctrl.currentEp);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _loadBrightness();
    ctrl.addListener(_onPlayerUpdate);
  }

  void _onPlayerUpdate() {
    final ctrl = context.read<PlayerController>();
    if (ctrl.progress >= 0.999 && ctrl.currentEp < ctrl.totalEpisodes - 1 && !_showAutoNext) {
      _startAutoNextCountdown();
    }
    // Keep PageView in sync when episode changes from drawer or auto-next
    if (_epPageCtrl.hasClients &&
        _epPageCtrl.page?.round() != ctrl.currentEp) {
      _epPageCtrl.animateToPage(
        ctrl.currentEp,
        duration: RDur.md,
        curve: RCurve.spring,
      );
    }
  }

  void _startAutoNextCountdown() {
    if (!mounted) return;
    setState(() { _showAutoNext = true; _autoNextCount = 3; });
    _autoNextTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _autoNextCount--);
      if (_autoNextCount <= 0) {
        t.cancel();
        final ctrl = context.read<PlayerController>();
        final next = ctrl.currentEp + 1;
        ctrl.playEpisode(next);
        _epPageCtrl.animateToPage(next, duration: RDur.md, curve: RCurve.spring);
        setState(() => _showAutoNext = false);
      }
    });
  }

  void _cancelAutoNext() {
    _autoNextTimer?.cancel();
    if (mounted) setState(() => _showAutoNext = false);
  }

  Future<void> _loadBrightness() async {
    try {
      _brightness = await ScreenBrightness().current;
      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _onDoubleTapLeft() {
    HapticFeedback.lightImpact();
    context.read<PlayerController>().seekRelative(-10);
    setState(() => _showLeftRipple = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _showLeftRipple = false);
    });
  }

  void _onDoubleTapRight() {
    HapticFeedback.lightImpact();
    context.read<PlayerController>().seekRelative(10);
    setState(() => _showRightRipple = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _showRightRipple = false);
    });
  }

  @override
  void dispose() {
    _autoNextTimer?.cancel();
    _epPageCtrl.dispose();
    final ctrl = context.read<PlayerController>();
    ctrl.removeListener(_onPlayerUpdate);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlayerController, SettingsController>(
      builder: (_, ctrl, settings, __) {
        final isVertical = ctrl.isVerticalVideo;

        return Scaffold(
          backgroundColor: Colors.black,
          body: OrientationBuilder(
            builder: (context, orientation) {
              final isLandscapeDevice = orientation == Orientation.landscape;

              // Landscape mode — single fixed player, no swipe
              if (isLandscapeDevice) {
                return _buildPlayerStack(context, ctrl, settings, isLandscapeDevice);
              }

              // Portrait mode — vertical PageView per episode
              return PageView.builder(
                controller: _epPageCtrl,
                scrollDirection: Axis.vertical,
                itemCount: ctrl.totalEpisodes,
                physics: const PageScrollPhysics(),
                onPageChanged: (i) {
                  HapticFeedback.selectionClick();
                  ctrl.playEpisode(i);
                },
                itemBuilder: (_, i) => _buildPlayerStack(context, ctrl, settings, isLandscapeDevice),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPlayerStack(BuildContext context, PlayerController ctrl,
      SettingsController settings, bool isLandscapeDevice) {
    return GestureDetector(
      onTap: ctrl.isLocked ? null : ctrl.toggleControls,
      onLongPress: () {
        HapticFeedback.mediumImpact();
        ctrl.toggleToolsDrawer();
      },
      onHorizontalDragStart: (d) {
        _seekDragStart = d.localPosition.dx;
        _seekDragDelta = 0;
        _isSeeking = true;
      },
      onHorizontalDragUpdate: (d) {
        if (!_isSeeking) return;
        final screenW = MediaQuery.of(context).size.width;
        _seekDragDelta = d.localPosition.dx - (_seekDragStart ?? 0);
        final seekSecs = (_seekDragDelta / screenW) * 60;
        ctrl.showControlsTemporary();
        setState(() {});
      },
      onHorizontalDragEnd: (_) {
        if (!_isSeeking) return;
        final screenW = MediaQuery.of(context).size.width;
        final seekSecs = (_seekDragDelta / screenW * 60).round();
        ctrl.seekRelative(seekSecs);
        HapticFeedback.selectionClick();
        setState(() { _isSeeking = false; _seekDragDelta = 0; _seekDragStart = null; });
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          _VideoArea(vc: _vc, ctrl: ctrl, isLandscapeDevice: isLandscapeDevice),

          if (ctrl.isBuffering)
            const Center(child: SamsungLoader(size: 34)),

          Positioned.fill(
            child: Row(
              children: [
                Expanded(child: GestureDetector(
                    onDoubleTap: _onDoubleTapLeft,
                    child: Container(color: Colors.transparent))),
                const SizedBox(width: 80),
                Expanded(child: GestureDetector(
                    onDoubleTap: _onDoubleTapRight,
                    child: Container(color: Colors.transparent))),
              ],
            ),
          ),

          if (_showLeftRipple)
            Positioned(left: 24, top: 0, bottom: 0,
                child: Center(child: _SeekRipple(label: '-10s', isLeft: true))),

          if (_showRightRipple)
            Positioned(right: 24, top: 0, bottom: 0,
                child: Center(child: _SeekRipple(label: '+10s', isLeft: false))),

          if (_isSeeking && _seekDragDelta.abs() > 5)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _seekDragDelta > 0 ? Icons.fast_forward_rounded : Icons.fast_rewind_rounded,
                      color: Colors.white, size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_seekDragDelta > 0 ? '+' : ''}${(_seekDragDelta / MediaQuery.of(context).size.width * 60).round()}s',
                      style: RText.body(size: 16, weight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),

          if (isLandscapeDevice)
            _LandscapeControls(ctrl: ctrl)
          else
            _PortraitControls(ctrl: ctrl),

          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _ThinProgressBar(ctrl: ctrl),
          ),

          if (ctrl.showDrawer) _EpisodeDrawer(ctrl: ctrl, pageCtrl: _epPageCtrl),

          if (ctrl.showToolsDrawer)
            _ToolsDrawer(
              ctrl: ctrl,
              settings: settings,
              brightness: _brightness,
              onBrightnessChange: (v) async {
                setState(() => _brightness = v);
                try { await ScreenBrightness().setScreenBrightness(v); } catch (_) {}
              },
            ),

          if (_showAutoNext)
            _AutoNextBanner(
              count: _autoNextCount,
              onCancel: _cancelAutoNext,
              onSkipNow: () {
                _cancelAutoNext();
                final next = ctrl.currentEp + 1;
                ctrl.playEpisode(next);
                _epPageCtrl.animateToPage(next, duration: RDur.md, curve: RCurve.spring);
              },
            ),

          if (ctrl.isLocked)
            Positioned.fill(
              child: GestureDetector(
                onLongPress: ctrl.toggleLock,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                    decoration: BoxDecoration(
                      color: RColors.bgRaised.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: RColors.glassBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_rounded, color: RColors.text2, size: 15),
                        const SizedBox(width: 8),
                        Text('Hold to unlock', style: RText.label(color: RColors.text2)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Thin TikTok-style progress bar (always visible at very bottom) ─────────────

class _ThinProgressBar extends StatelessWidget {
  final PlayerController ctrl;
  const _ThinProgressBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2,
      child: LinearProgressIndicator(
        value: ctrl.progress,
        backgroundColor: Colors.white.withOpacity(0.15),
        valueColor: const AlwaysStoppedAnimation<Color>(RColors.brand),
        minHeight: 2,
      ),
    );
  }
}

// ── Seek Ripple ────────────────────────────────────────────────────────────────

class _SeekRipple extends StatelessWidget {
  final String label;
  final bool isLeft;
  const _SeekRipple({required this.label, required this.isLeft});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.15),
          ),
          child: Icon(
            isLeft ? Icons.replay_10_rounded : Icons.forward_10_rounded,
            color: Colors.white, size: 32,
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: RText.body(size: 13, weight: FontWeight.w700)),
      ],
    ).animate()
        .scale(begin: const Offset(0.7, 0.7), duration: RDur.sm, curve: RCurve.spring)
        .fadeIn(duration: RDur.xs)
        .then(delay: 300.ms)
        .fadeOut(duration: RDur.md);
  }
}

// ── Auto-next Banner ───────────────────────────────────────────────────────────

class _AutoNextBanner extends StatelessWidget {
  final int count;
  final VoidCallback onCancel;
  final VoidCallback onSkipNow;
  const _AutoNextBanner({required this.count, required this.onCancel, required this.onSkipNow});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80, right: 16, left: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: RColors.bgCard.withOpacity(0.92),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: RColors.glassBorderMd),
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: RColors.brand, width: 2),
                  ),
                  child: Center(
                    child: Text('$count', style: RText.body(size: 16, weight: FontWeight.w800, color: RColors.brand)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Next episode in $count…', style: RText.body(size: 13, weight: FontWeight.w700)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onSkipNow,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [RColors.brand, RColors.brand2]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('Play Now', style: RText.body(size: 12, weight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onCancel,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: const Icon(Icons.close_rounded, color: RColors.text3, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().slideY(begin: 1, end: 0, duration: RDur.md, curve: RCurve.spring).fadeIn(duration: RDur.sm);
  }
}

// ── Video Area ─────────────────────────────────────────────────────────────────

class _VideoArea extends StatelessWidget {
  final VideoController vc;
  final PlayerController ctrl;
  final bool isLandscapeDevice;
  const _VideoArea({required this.vc, required this.ctrl, required this.isLandscapeDevice});

  @override
  Widget build(BuildContext context) {
    if (isLandscapeDevice) {
      return Center(
        child: AspectRatio(
          aspectRatio: ctrl.videoAspectRatio > 0 ? ctrl.videoAspectRatio : 16 / 9,
          child: Video(controller: vc, controls: NoVideoControls, fit: BoxFit.contain),
        ),
      );
    }
    if (ctrl.isVerticalVideo) {
      return Video(controller: vc, controls: NoVideoControls, fit: BoxFit.cover);
    } else {
      return Column(
        children: [
          Expanded(flex: 1, child: Container(color: Colors.black)),
          AspectRatio(
            aspectRatio: ctrl.videoAspectRatio > 0 ? ctrl.videoAspectRatio : 16 / 9,
            child: Video(controller: vc, controls: NoVideoControls, fit: BoxFit.contain),
          ),
          Expanded(flex: 1, child: Container(color: Colors.black)),
        ],
      );
    }
  }
}

// ── Portrait Controls — TikTok style ──────────────────────────────────────────

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
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: RColors.text, size: 20),
                    ),
                    Expanded(
                      child: Text(ctrl.movie.title,
                        style: RText.body(size: 14, weight: FontWeight.w700),
                        maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                    ),
                    IconButton(
                      onPressed: () => ctrl.setLandscape(true),
                      icon: const Icon(Icons.fullscreen_rounded, color: RColors.text2, size: 24),
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
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: RColors.glassMd,
                      border: Border.all(color: RColors.glassBorderMd),
                    ),
                    child: Icon(
                      ctrl.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: RColors.text, size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Right side — TikTok-style social actions
          Positioned(
            right: 12, bottom: 120,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PlayerAction(icon: Icons.favorite_border_rounded, activeIcon: Icons.favorite_rounded,
                    activeColor: RColors.like, label: 'Like'),
                const SizedBox(height: 20),
                _PlayerAction(icon: Icons.share_rounded, label: 'Share',
                    onTap: () => _showSharePlayer(context)),
                const SizedBox(height: 20),
                _PlayerAction(icon: Icons.bookmark_border_rounded, activeIcon: Icons.bookmark_rounded,
                    activeColor: RColors.brand, label: 'Save'),
                const SizedBox(height: 20),
                // Episodes
                GestureDetector(
                  onTap: ctrl.toggleDrawer,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: RColors.glass,
                              border: Border.all(color: RColors.glassBorder),
                            ),
                            child: const Icon(Icons.list_rounded, color: RColors.text, size: 22),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text('Episodes', style: RText.label()),
                    ],
                  ),
                ),
              ],
            ).animate()
                .fadeIn(delay: 100.ms, duration: RDur.lg)
                .slideX(begin: 0.4, end: 0, curve: RCurve.spring),
          ),

          // Bottom — minimal time + thin seek bar only
          Positioned(
            bottom: 8, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Time row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(ctrl.positionLabel, style: RText.label(color: RColors.text2)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: RColors.brand.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: RColors.brand.withOpacity(0.35)),
                          ),
                          child: Text('EP ${ctrl.currentEp + 1}/${ctrl.totalEpisodes}',
                              style: RText.label(color: RColors.brand)),
                        ),
                        Text(ctrl.durationLabel, style: RText.label(color: RColors.text3)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Seek bar
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

void _showCommentsPlayer(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _CommentsSheetPlayer(),
  );
}

void _showSharePlayer(BuildContext context) {
  HapticFeedback.lightImpact();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ShareSheetPlayer(),
  );
}

class _CommentsSheetPlayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: BoxDecoration(
            color: RColors.bgCard.withOpacity(0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: RColors.glassBorderMd, width: 0.8)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 14),
                  width: 38, height: 4,
                  decoration: BoxDecoration(color: RColors.glassMd, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Comments', style: RText.body(size: 16, weight: FontWeight.w700)),
              ),
              Expanded(
                child: Center(
                  child: _ComingSoonBlock(
                    icon: Icons.comment_outlined,
                    title: 'Comments',
                    subtitle: 'Join the conversation when\nwe hit 5M users 🚀',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().slideY(begin: 0.3, end: 0, duration: RDur.md, curve: RCurve.spring).fadeIn(duration: RDur.sm);
  }
}

class _ShareSheetPlayer extends StatelessWidget {
  const _ShareSheetPlayer();
  @override
  Widget build(BuildContext context) {
    final options = [
      (Icons.link_rounded, 'Copy Link'),
      (Icons.message_rounded, 'Messages'),
      (Icons.telegram, 'Telegram'),
      (Icons.public_rounded, 'WhatsApp'),
      (Icons.more_horiz_rounded, 'More'),
    ];
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: RColors.bgCard.withOpacity(0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: RColors.glassBorderMd, width: 0.8)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(margin: const EdgeInsets.only(bottom: 20),
                  width: 38, height: 4,
                  decoration: BoxDecoration(color: RColors.glassMd, borderRadius: BorderRadius.circular(2)))),
              Text('Share', style: RText.body(size: 16, weight: FontWeight.w700)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: options.map((o) => GestureDetector(
                  onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); },
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 54, height: 54,
                      decoration: BoxDecoration(color: RColors.bgRaised,
                          borderRadius: BorderRadius.circular(16), border: Border.all(color: RColors.glassBorder)),
                      child: Icon(o.$1, color: RColors.text, size: 24)),
                    const SizedBox(height: 6),
                    Text(o.$2, style: RText.label(size: 10)),
                  ]),
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    ).animate().slideY(begin: 0.3, end: 0, duration: RDur.md, curve: RCurve.spring).fadeIn(duration: RDur.sm);
  }
}

// ── Landscape Controls ─────────────────────────────────────────────────────────

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
          // Top
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: const BoxDecoration(gradient: RColors.overlayTop),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => ctrl.setLandscape(false),
                      icon: const Icon(Icons.fullscreen_exit_rounded, color: RColors.text, size: 22),
                    ),
                    Expanded(child: Text(ctrl.movie.title,
                        style: RText.body(size: 14, weight: FontWeight.w700),
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: RColors.brand.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: RColors.brand.withOpacity(0.35)),
                      ),
                      child: Text('EP ${ctrl.currentEp + 1}/${ctrl.totalEpisodes}',
                          style: RText.label(color: RColors.brand)),
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
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: RColors.glassMd,
                      border: Border.all(color: RColors.glassBorderMd),
                    ),
                    child: Icon(ctrl.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: RColors.text, size: 30),
                  ),
                ),
              ),
            ),
          ),

          // Bottom
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(ctrl.positionLabel, style: RText.label(color: RColors.text2)),
                        const Spacer(),
                        GestureDetector(
                          onTap: ctrl.toggleDrawer,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: RColors.glass, borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: RColors.glassBorderMd),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.list_rounded, color: RColors.text, size: 14),
                              const SizedBox(width: 4),
                              Text('EP', style: RText.label(color: RColors.text)),
                            ]),
                          ),
                        ),
                        const Spacer(),
                        Text(ctrl.durationLabel, style: RText.label(color: RColors.text3)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _SeekBar(ctrl: ctrl),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Seek Bar ───────────────────────────────────────────────────────────────────

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
        value: ctrl.progress,
        onChanged: (v) {
          ctrl.showControlsTemporary();
          ctrl.seekProgress(v);
        },
      ),
    );
  }
}

// ── Player action button ───────────────────────────────────────────────────────

class _PlayerAction extends StatefulWidget {
  final IconData icon;
  final String label;
  final IconData? activeIcon;
  final Color? activeColor;
  final VoidCallback? onTap;

  const _PlayerAction({
    required this.icon, required this.label,
    this.activeIcon, this.activeColor, this.onTap,
  });

  @override
  State<_PlayerAction> createState() => _PlayerActionState();
}

class _PlayerActionState extends State<_PlayerAction> {
  bool _active = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = _active && widget.activeColor != null ? widget.activeColor! : RColors.text;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() { _pressed = false; if (widget.onTap == null) _active = !_active; });
        HapticFeedback.lightImpact();
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.84 : 1.0,
        duration: RDur.xs, curve: RCurve.spring,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: AnimatedContainer(
                  duration: RDur.md,
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _active && widget.activeColor != null
                        ? widget.activeColor!.withOpacity(0.18) : RColors.glass,
                    border: Border.all(
                      color: _active && widget.activeColor != null
                          ? widget.activeColor!.withOpacity(0.4) : RColors.glassBorder,
                    ),
                    boxShadow: _active && widget.activeColor != null ? [
                      BoxShadow(color: widget.activeColor!.withOpacity(0.4), blurRadius: 18, spreadRadius: 2),
                    ] : null,
                  ),
                  child: Icon(_active && widget.activeIcon != null ? widget.activeIcon! : widget.icon,
                      color: color, size: 22),
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

// ── Episode Drawer ─────────────────────────────────────────────────────────────

class _EpisodeDrawer extends StatelessWidget {
  final PlayerController ctrl;
  final PageController pageCtrl;
  const _EpisodeDrawer({required this.ctrl, required this.pageCtrl});

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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.52,
                  decoration: BoxDecoration(
                    color: RColors.bgCard.withOpacity(0.94),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border(top: BorderSide(color: RColors.glassBorderMd, width: 0.8)),
                  ),
                  child: Column(
                    children: [
                      Center(child: Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 14),
                          width: 38, height: 4,
                          decoration: BoxDecoration(color: RColors.glassMd, borderRadius: BorderRadius.circular(2)))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Episodes', style: RText.body(size: 16, weight: FontWeight.w700)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: RColors.glass,
                                  borderRadius: BorderRadius.circular(10), border: Border.all(color: RColors.glassBorder)),
                              child: Text('${ctrl.totalEpisodes} eps', style: RText.label(color: RColors.text3)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ctrl.episodes.isEmpty
                            ? Center(child: Text('No episodes', style: RText.body(size: 13, color: RColors.text3)))
                            : GridView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 5, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.4,
                                ),
                                itemCount: ctrl.totalEpisodes,
                                itemBuilder: (_, i) {
                                  final isCurrent = ctrl.currentEp == i;
                                  final ep = ctrl.episodes[i];
                                  return GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      ctrl.playEpisode(i);
                                      pageCtrl.animateToPage(i,
                                          duration: RDur.md, curve: RCurve.spring);
                                      ctrl.toggleDrawer();
                                    },
                                    child: AnimatedContainer(
                                      duration: RDur.sm,
                                      decoration: BoxDecoration(
                                        color: isCurrent ? RColors.brand.withOpacity(0.2) : RColors.glass,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: isCurrent ? RColors.brand : RColors.glassBorder,
                                            width: isCurrent ? 1.5 : 1),
                                        boxShadow: isCurrent ? [
                                          BoxShadow(color: RColors.brand.withOpacity(0.3), blurRadius: 8)
                                        ] : null,
                                      ),
                                      child: Center(
                                        child: Text('${ep.number}',
                                          style: RText.body(size: 14,
                                              weight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                              color: isCurrent ? RColors.brand : RColors.text2)),
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
    ).animate().fadeIn(duration: RDur.sm).slideY(begin: 0.3, end: 0, duration: RDur.md, curve: RCurve.spring);
  }
}

// ── Tools Drawer ───────────────────────────────────────────────────────────────

class _ToolsDrawer extends StatelessWidget {
  final PlayerController ctrl;
  final SettingsController settings;
  final double brightness;
  final Function(double) onBrightnessChange;

  const _ToolsDrawer({required this.ctrl, required this.settings,
      required this.brightness, required this.onBrightnessChange});

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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: RColors.bgCard.withOpacity(0.96),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border(top: BorderSide(color: RColors.glassBorderMd, width: 0.8)),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: Container(margin: const EdgeInsets.only(bottom: 20),
                          width: 38, height: 4,
                          decoration: BoxDecoration(color: RColors.glassMd, borderRadius: BorderRadius.circular(2)))),
                      Text('Speed', style: RText.label(size: 11, color: RColors.text3)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: speeds.map((s) {
                          final active = ctrl.speed == s;
                          return GestureDetector(
                            onTap: () => ctrl.setSpeed(s),
                            child: AnimatedContainer(
                              duration: RDur.sm,
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                              decoration: BoxDecoration(
                                color: active ? RColors.brand.withOpacity(0.2) : RColors.glass,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: active ? RColors.brand : RColors.glassBorder),
                              ),
                              child: Text('${s}x', style: RText.body(size: 13, weight: FontWeight.w700,
                                  color: active ? RColors.brand : RColors.text2)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      Text('Brightness', style: RText.label(size: 11, color: RColors.text3)),
                      Row(children: [
                        const Icon(Icons.brightness_low_rounded, color: RColors.text3, size: 18),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 2,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              activeTrackColor: RColors.brand,
                              inactiveTrackColor: RColors.glassMd,
                              thumbColor: Colors.white,
                              overlayColor: RColors.brand.withOpacity(0.15),
                            ),
                            child: Slider(value: brightness, onChanged: onBrightnessChange),
                          ),
                        ),
                        const Icon(Icons.brightness_high_rounded, color: RColors.text2, size: 18),
                      ]),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _ToolBtn(
                            icon: ctrl.isLandscape ? Icons.stay_current_portrait_rounded : Icons.stay_current_landscape_rounded,
                            label: ctrl.isLandscape ? 'Portrait' : 'Landscape',
                            onTap: () { ctrl.toggleOrientation(); ctrl.toggleToolsDrawer(); },
                          ),
                          _ToolBtn(
                            icon: ctrl.isLocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                            label: ctrl.isLocked ? 'Unlock' : 'Lock',
                            onTap: () { ctrl.toggleLock(); ctrl.toggleToolsDrawer(); },
                          ),
                          _ToolBtn(
                            icon: Icons.skip_next_rounded,
                            label: 'Skip Intro',
                            onTap: () { ctrl.skipIntro(); ctrl.toggleToolsDrawer(); },
                          ),
                          _ToolBtn(
                            icon: settings.autoNext ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                            label: settings.autoNext ? 'Auto: On' : 'Auto: Off',
                            active: settings.autoNext,
                            onTap: () => settings.setAutoNext(!settings.autoNext),
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
    ).animate().fadeIn(duration: RDur.sm).slideY(begin: 0.3, end: 0, duration: RDur.md, curve: RCurve.spring);
  }
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  const _ToolBtn({required this.icon, required this.label, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: RDur.sm,
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: active ? RColors.brand.withOpacity(0.18) : RColors.glass,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: active ? RColors.brand : RColors.glassBorder),
              boxShadow: active ? [BoxShadow(color: RColors.brand.withOpacity(0.3), blurRadius: 10)] : null,
            ),
            child: Icon(icon, color: active ? RColors.brand : RColors.text, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: RText.label()),
        ],
      ),
    );
  }
}

// ── Coming Soon Block ──────────────────────────────────────────────────────────

class _ComingSoonBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _ComingSoonBlock({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            border: Border.all(color: RColors.brand.withOpacity(0.3)),
          ),
          child: Icon(icon, color: RColors.brand, size: 32),
        ),
        const SizedBox(height: 16),
        Text(title, style: RText.body(size: 16, weight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(subtitle, style: RText.body(size: 13, color: RColors.text3), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: RColors.brand.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: RColors.brand.withOpacity(0.3)),
          ),
          child: Text('Coming Soon 🚀',
              style: RText.body(size: 12, weight: FontWeight.w700, color: RColors.brand)),
        ),
      ],
    );
  }
}
