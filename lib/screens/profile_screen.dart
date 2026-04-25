import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../controllers/player_controller.dart';
import '../controllers/settings_controller.dart';
import '../models/models.dart';
import '../theme/tokens.dart';
import '../screens/player_screen.dart';

// Saved videos store — simple in-memory for now
class SavedVideos extends ChangeNotifier {
  final List<VideoModel> _videos = [];
  List<VideoModel> get videos => _videos;

  void add(VideoModel v) {
    if (!_videos.any((x) => x.id == v.id)) {
      _videos.add(v);
      notifyListeners();
    }
  }

  void remove(String id) {
    _videos.removeWhere((v) => v.id == id);
    notifyListeners();
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final saved = context.watch<SavedVideos>();

    return Scaffold(
      backgroundColor: RColors.bg,
      body: CustomScrollView(
        slivers: [
          // ── Header ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  // Settings icon top right
                  Positioned(
                    top: 12,
                    right: 16,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChangeNotifierProvider.value(
                              value: context.read<SettingsController>(),
                              child: const SettingsScreen(),
                            ),
                          ),
                        );
                      },
                      child: ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: RColors.glass,
                              border:
                                  Border.all(color: RColors.glassBorder),
                            ),
                            child: const Icon(Icons.settings_outlined,
                                color: RColors.text, size: 20),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Profile info — avatar center, username below
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),

                        // Avatar circle
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [RColors.brand, RColors.brand2],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: RColors.brand.withOpacity(0.45),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'R',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                            .animate()
                            .scale(
                              begin: const Offset(0.8, 0.8),
                              duration: RDur.lg,
                              curve: RCurve.spring,
                            )
                            .fadeIn(duration: RDur.md),

                        const SizedBox(height: 14),

                        // Username
                        Text(
                          'Reelz User',
                          style: RText.body(
                              size: 20, weight: FontWeight.w700),
                        )
                            .animate()
                            .fadeIn(delay: 100.ms, duration: RDur.lg),

                        const SizedBox(height: 4),

                        Text(
                          '@reelzuser',
                          style:
                              RText.body(size: 13, color: RColors.text3),
                        )
                            .animate()
                            .fadeIn(delay: 150.ms, duration: RDur.lg),

                        const SizedBox(height: 20),

                        // Stats row
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            _Stat(
                                label: 'Saved',
                                value: '${saved.videos.length}'),
                            Container(
                              width: 1,
                              height: 28,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 28),
                              color: RColors.glassBorder,
                            ),
                            _Stat(label: 'Liked', value: '0'),
                          ],
                        )
                            .animate()
                            .fadeIn(delay: 200.ms, duration: RDur.lg),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Divider ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              height: 0.5,
              color: RColors.glassBorder,
            ),
          ),

          // ── Saved Videos Grid ─────────────────────────────────
          if (saved.videos.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: RColors.bgRaised,
                        border: Border.all(color: RColors.glassBorder),
                      ),
                      child: const Icon(Icons.bookmark_border_rounded,
                          color: RColors.text3, size: 30),
                    ),
                    const SizedBox(height: 16),
                    Text('No saved videos yet',
                        style: RText.body(
                            size: 15,
                            weight: FontWeight.w600,
                            color: RColors.text2)),
                    const SizedBox(height: 8),
                    Text('Save videos from the feed',
                        style: RText.body(
                            size: 13, color: RColors.text3)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(1),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _SavedVideoTile(
                    video: saved.videos[i],
                    index: i,
                  ),
                  childCount: saved.videos.length,
                ),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 1.5,
                  crossAxisSpacing: 1.5,
                  childAspectRatio: 0.6,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: RText.body(size: 20, weight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(label, style: RText.label()),
      ],
    );
  }
}

class _SavedVideoTile extends StatelessWidget {
  final VideoModel video;
  final int index;
  const _SavedVideoTile({required this.video, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        final movie = MovieModel.fromVideo(video);
        final settings = context.read<SettingsController>();
        Navigator.of(context).push(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 400),
            pageBuilder: (_, __, ___) => MultiProvider(
              providers: [
                ChangeNotifierProvider(
                    create: (_) => PlayerController(movie: movie)),
                ChangeNotifierProvider.value(value: settings),
              ],
              child: const PlayerScreen(),
            ),
            transitionsBuilder: (_, anim, __, child) => FadeTransition(
              opacity: anim,
              child: child,
            ),
          ),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: video.thumbnailUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: RColors.bgCard),
            errorWidget: (_, __, ___) =>
                Container(color: RColors.bgCard),
          ),
          // Bottom gradient + title
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 24, 6, 8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xDD050508), Colors.transparent],
                ),
              ),
              child: Text(
                video.caption,
                style: RText.body(size: 11, weight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      )
          .animate()
          .fadeIn(
            delay: Duration(milliseconds: index * 30),
            duration: RDur.md,
          ),
    );
  }
}

// ── Settings Screen ───────────────────────────────────────────────────────────

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    return Scaffold(
      backgroundColor: RColors.bg,
      appBar: AppBar(
        backgroundColor: RColors.bg,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: RColors.text, size: 20),
        ),
        title: Text('Settings',
            style: RText.body(size: 17, weight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Playback section
          _SectionLabel('Playback'),
          _ToggleTile(
            icon: Icons.skip_next_rounded,
            label: 'Auto Next Episode',
            subtitle: 'Automatically play next episode when current ends',
            value: settings.autoNextEpisode,
            onChanged: settings.setAutoNextEpisode,
          ),
          _PickerTile(
            icon: Icons.hd_rounded,
            label: 'Video Quality',
            value: settings.videoQuality,
            options: ['Auto', '1080p', '720p', '480p'],
            onChanged: settings.setVideoQuality,
          ),

          const SizedBox(height: 16),

          // App section
          _SectionLabel('App'),
          _TapTile(
            icon: Icons.info_outline_rounded,
            label: 'About Reelz',
            onTap: () {},
          ),
          _TapTile(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy Policy',
            onTap: () {},
          ),
          _TapTile(
            icon: Icons.description_outlined,
            label: 'Terms of Service',
            onTap: () {},
          ),
          _TapTile(
            icon: Icons.delete_sweep_outlined,
            label: 'Clear Cache',
            onTap: () => HapticFeedback.mediumImpact(),
          ),

          const SizedBox(height: 32),

          // App version
          Center(
            child: Text(
              'Reelz v1.0.0',
              style: RText.label(color: RColors.text4),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4, left: 2),
      child: Text(
        label.toUpperCase(),
        style: RText.label(size: 11, color: RColors.brand),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final Function(bool) onChanged;

  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: RColors.bgRaised,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: RColors.glassBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: RColors.text2, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        RText.body(size: 14, weight: FontWeight.w500)),
                Text(subtitle,
                    style: RText.label(color: RColors.text3)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: RColors.brand,
            activeTrackColor: RColors.brand.withOpacity(0.28),
            inactiveThumbColor: RColors.text3,
            inactiveTrackColor: RColors.glass,
          ),
        ],
      ),
    );
  }
}

class _TapTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TapTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: RColors.bgRaised,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: RColors.glassBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: RColors.text2, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: RText.body(size: 14, weight: FontWeight.w500)),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: RColors.text4, size: 14),
          ],
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<String> options;
  final Function(String) onChanged;

  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: RColors.bgCard,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: RColors.glassMd,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ...options.map((o) => ListTile(
                      title: Text(o, style: RText.body(size: 15)),
                      trailing: o == value
                          ? const Icon(Icons.check_rounded,
                              color: RColors.brand)
                          : null,
                      onTap: () {
                        onChanged(o);
                        Navigator.of(context).pop();
                      },
                    )),
              ],
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: RColors.bgRaised,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: RColors.glassBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: RColors.text2, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: RText.body(size: 14, weight: FontWeight.w500)),
            ),
            Text(value, style: RText.label(color: RColors.text3)),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: RColors.text4, size: 14),
          ],
        ),
      ),
    );
  }
}
