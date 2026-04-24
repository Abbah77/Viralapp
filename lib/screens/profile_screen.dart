import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/tokens.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RColors.bg,
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            backgroundColor: RColors.bg,
            expandedHeight: 220,
            pinned: true,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background gradient
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x440090FF),
                          RColors.bg,
                        ],
                      ),
                    ),
                  ),
                  // Profile info
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [RColors.brand, RColors.brand2],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: RColors.brand.withOpacity(0.4),
                                blurRadius: 16,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'R',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reelz User',
                                style: RText.body(
                                    size: 18, weight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '@reelzuser',
                                style: RText.body(
                                    size: 13, color: RColors.text3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const SettingsScreen()),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: RColors.glass,
                    shape: BoxShape.circle,
                    border: Border.all(color: RColors.glassBorder),
                  ),
                  child: const Icon(Icons.settings_outlined,
                      color: RColors.text, size: 20),
                ),
              ),
            ],
          ),

          // Stats row
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Stat(label: 'Watched', value: '0'),
                  _Divider(),
                  _Stat(label: 'Saved', value: '0'),
                  _Divider(),
                  _Stat(label: 'Liked', value: '0'),
                ],
              ),
            ),
          ),

          // Sections
          SliverToBoxAdapter(
            child: _Section(title: 'Continue Watching'),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 120,
              child: Center(
                child: Text(
                  'Your watch history will appear here',
                  style: RText.body(size: 13, color: RColors.text3),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: _Section(title: 'Saved Movies'),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 120,
              child: Center(
                child: Text(
                  'Your saved movies will appear here',
                  style: RText.body(size: 13, color: RColors.text3),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
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
        Text(
          value,
          style: RText.body(size: 22, weight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(label, style: RText.label()),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: RColors.glassBorder,
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Text(
        title,
        style: RText.body(size: 16, weight: FontWeight.w700),
      ),
    );
  }
}

// ── Settings Screen ──────────────────────────────────────────────────────────

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoplay = true;
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RColors.bg,
      appBar: AppBar(
        backgroundColor: RColors.bg,
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
          _SettingsSection(title: 'Playback'),
          _ToggleTile(
            icon: Icons.play_circle_outline_rounded,
            label: 'Autoplay',
            subtitle: 'Auto play next episode',
            value: _autoplay,
            onChanged: (v) => setState(() => _autoplay = v),
          ),
          _SettingsTile(
            icon: Icons.speed_rounded,
            label: 'Video Quality',
            trailing: 'Auto',
            onTap: () {},
          ),

          const SizedBox(height: 16),
          _SettingsSection(title: 'Notifications'),
          _ToggleTile(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            subtitle: 'Get notified about new content',
            value: _notifications,
            onChanged: (v) => setState(() => _notifications = v),
          ),

          const SizedBox(height: 16),
          _SettingsSection(title: 'About'),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            label: 'About Reelz',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy Policy',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            label: 'Terms of Service',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.delete_outline_rounded,
            label: 'Clear Cache',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  const _SettingsSection({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title.toUpperCase(),
        style: RText.label(color: RColors.brand),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            if (trailing != null)
              Text(trailing!, style: RText.label(color: RColors.text3)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: RColors.text4, size: 14),
          ],
        ),
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    style: RText.body(size: 14, weight: FontWeight.w500)),
                Text(subtitle, style: RText.label(color: RColors.text3)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: RColors.brand,
            activeTrackColor: RColors.brand.withOpacity(0.3),
            inactiveThumbColor: RColors.text3,
            inactiveTrackColor: RColors.glass,
          ),
        ],
      ),
    );
  }
}
