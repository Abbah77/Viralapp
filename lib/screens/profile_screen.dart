import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/settings_controller.dart';
import '../theme/tokens.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  // Settings icon
                  Positioned(
                    top: 12, right: 16,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: context.read<SettingsController>(),
                            child: const SettingsScreen(),
                          ),
                        ));
                      },
                      child: ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: RColors.glass,
                              border: Border.all(color: RColors.glassBorder),
                            ),
                            child: const Icon(Icons.settings_outlined, color: RColors.text, size: 20),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Profile info
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),

                        // Avatar
                        Container(
                          width: 88, height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [RColors.brand, RColors.brand2],
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: RColors.brand.withOpacity(0.45),
                                blurRadius: 24, spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('R', style: TextStyle(
                              color: Colors.white, fontSize: 34, fontWeight: FontWeight.w700,
                            )),
                          ),
                        ),

                        const SizedBox(height: 14),

                        Text('Reelz User', style: RText.body(size: 20, weight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('@reelzuser', style: RText.body(size: 13, color: RColors.text3)),

                        const SizedBox(height: 20),

                        // Stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _Stat(label: 'Saved', value: '0'),
                            Container(width: 1, height: 28, margin: const EdgeInsets.symmetric(horizontal: 28), color: RColors.glassBorder),
                            _Stat(label: 'Liked', value: '0'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(child: Container(height: 0.5, color: RColors.glassBorder)),

          // Empty saved state
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, color: RColors.bgRaised,
                      border: Border.all(color: RColors.glassBorder),
                    ),
                    child: const Icon(Icons.bookmark_border_rounded, color: RColors.text3, size: 30),
                  ),
                  const SizedBox(height: 16),
                  Text('No saved videos yet',
                      style: RText.body(size: 15, weight: FontWeight.w600, color: RColors.text2)),
                  const SizedBox(height: 8),
                  Text('Save videos from the feed', style: RText.body(size: 13, color: RColors.text3)),
                ],
              ),
            ),
          ),
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
        Text(value, style: RText.body(size: 20, weight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(label, style: RText.label()),
      ],
    );
  }
}

// ── Settings Screen ───────────────────────────────────────────────────────────

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsController>();

    return Scaffold(
      backgroundColor: RColors.bg,
      appBar: AppBar(
        backgroundColor: RColors.bg,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: RColors.text, size: 20),
        ),
        title: Text('Settings', style: RText.body(size: 17, weight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SLabel('Playback'),
          _Toggle(
            icon: Icons.skip_next_rounded,
            label: 'Auto Next Episode',
            subtitle: 'Automatically play next episode when current ends',
            value: s.autoNext,
            onChanged: s.setAutoNext,
          ),
          _Picker(
            icon: Icons.hd_rounded,
            label: 'Video Quality',
            value: s.quality,
            options: ['Auto', '1080p', '720p', '480p'],
            onChanged: s.setQuality,
          ),

          const SizedBox(height: 16),
          _SLabel('About'),
          _Tap(icon: Icons.info_outline_rounded, label: 'About Reelz', onTap: () {}),
          _Tap(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy', onTap: () {}),
          _Tap(icon: Icons.description_outlined, label: 'Terms of Service', onTap: () {}),
          _Tap(
            icon: Icons.delete_sweep_outlined,
            label: 'Clear Cache',
            onTap: () => HapticFeedback.mediumImpact(),
          ),

          const SizedBox(height: 32),
          Center(child: Text('Reelz v1.0.0', style: RText.label(color: RColors.text4))),
        ],
      ),
    );
  }
}

class _SLabel extends StatelessWidget {
  final String label;
  const _SLabel(this.label);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 4, left: 2),
    child: Text(label.toUpperCase(), style: RText.label(size: 11, color: RColors.brand)),
  );
}

class _Toggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final Function(bool) onChanged;

  const _Toggle({required this.icon, required this.label, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    decoration: BoxDecoration(color: RColors.bgRaised, borderRadius: BorderRadius.circular(14), border: Border.all(color: RColors.glassBorder)),
    child: Row(children: [
      Icon(icon, color: RColors.text2, size: 20),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: RText.body(size: 14, weight: FontWeight.w500)),
        Text(subtitle, style: RText.label(color: RColors.text3)),
      ])),
      Switch(value: value, onChanged: onChanged,
        activeColor: RColors.brand,
        activeTrackColor: RColors.brand.withOpacity(0.28),
        inactiveThumbColor: RColors.text3,
        inactiveTrackColor: RColors.glass,
      ),
    ]),
  );
}

class _Tap extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Tap({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(color: RColors.bgRaised, borderRadius: BorderRadius.circular(14), border: Border.all(color: RColors.glassBorder)),
      child: Row(children: [
        Icon(icon, color: RColors.text2, size: 20),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: RText.body(size: 14, weight: FontWeight.w500))),
        const Icon(Icons.arrow_forward_ios_rounded, color: RColors.text4, size: 14),
      ]),
    ),
  );
}

class _Picker extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<String> options;
  final Function(String) onChanged;

  const _Picker({required this.icon, required this.label, required this.value, required this.options, required this.onChanged});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => showModalBottomSheet(
      context: context,
      backgroundColor: RColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 38, height: 4, margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: RColors.glassMd, borderRadius: BorderRadius.circular(2))),
          ...options.map((o) => ListTile(
            title: Text(o, style: RText.body(size: 15)),
            trailing: o == value ? const Icon(Icons.check_rounded, color: RColors.brand) : null,
            onTap: () { onChanged(o); Navigator.of(context).pop(); },
          )),
        ]),
      ),
    ),
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(color: RColors.bgRaised, borderRadius: BorderRadius.circular(14), border: Border.all(color: RColors.glassBorder)),
      child: Row(children: [
        Icon(icon, color: RColors.text2, size: 20),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: RText.body(size: 14, weight: FontWeight.w500))),
        Text(value, style: RText.label(color: RColors.text3)),
        const SizedBox(width: 6),
        const Icon(Icons.arrow_forward_ios_rounded, color: RColors.text4, size: 14),
      ]),
    ),
  );
}
