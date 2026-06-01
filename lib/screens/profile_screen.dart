import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../controllers/player_controller.dart';
import '../controllers/settings_controller.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/tokens.dart';
import '../widgets/dot_loader.dart';
import 'player_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    if (!auth.isSignedIn) {
      return const _SignedOutProfile();
    }
    return _SignedInProfile(auth: auth);
  }
}

// ── Signed out ─────────────────────────────────────────────────────────────────

class _SignedOutProfile extends StatelessWidget {
  const _SignedOutProfile();

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    return Scaffold(
      backgroundColor: RColors.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [RColors.brandDeep, RColors.brand, RColors.brand2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: RColors.brand.withOpacity(0.4),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('R',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w900)),
                ),
              ).animate().fadeIn(duration: 600.ms).scale(
                  begin: const Offset(0.85, 0.85), curve: RCurve.spring),
              const SizedBox(height: 24),
              Text('Sign in to save & like',
                  style: RText.body(
                      size: 20, weight: FontWeight.w700, color: RColors.text))
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 500.ms),
              const SizedBox(height: 8),
              Text('Your liked and saved movies live here',
                  style: RText.body(size: 14, color: RColors.text3),
                  textAlign: TextAlign.center)
                  .animate()
                  .fadeIn(delay: 160.ms, duration: 500.ms),
              const SizedBox(height: 36),
              _GoogleSignInButton(auth: auth)
                  .animate()
                  .fadeIn(delay: 260.ms, duration: 500.ms)
                  .slideY(begin: 0.3, end: 0, curve: RCurve.spring),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatefulWidget {
  final AuthService auth;
  const _GoogleSignInButton({required this.auth});
  @override
  State<_GoogleSignInButton> createState() => _GSIBState();
}

class _GSIBState extends State<_GoogleSignInButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (_loading) return;
        HapticFeedback.mediumImpact();
        setState(() => _loading = true);
        await widget.auth.signInWithGoogle();
        if (mounted) setState(() => _loading = false);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.16)),
            ),
            child: _loading
                ? const Center(child: SamsungLoader(size: 24))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _GIcon(),
                      const SizedBox(width: 12),
                      Text('Continue with Google',
                          style: RText.body(
                              size: 15, weight: FontWeight.w600)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _GIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text('G',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4285F4),
        ));
  }
}

// ── Signed in ─────────────────────────────────────────────────────────────────

class _SignedInProfile extends StatefulWidget {
  final AuthService auth;
  const _SignedInProfile({required this.auth});
  @override
  State<_SignedInProfile> createState() => _SignedInProfileState();
}

class _SignedInProfileState extends State<_SignedInProfile>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  // Fetched movie cards for liked + saved
  List<MovieCard?> _likedCards = [];
  List<MovieCard?> _savedCards = [];
  bool _loadingCards = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadCards();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    setState(() => _loadingCards = true);
    final liked = widget.auth.likedIds.toList();
    final saved = widget.auth.savedIds.toList();

    Future<MovieCard?> fetch(int id) async {
      try {
        final detail = await ApiService.getMovie(id.toString());
        return detail.movie;
      } catch (_) {
        return null;
      }
    }

    final lCards = await Future.wait(liked.map(fetch));
    final sCards = await Future.wait(saved.map(fetch));
    if (mounted) {
      setState(() {
        _likedCards = lCards;
        _savedCards = sCards;
        _loadingCards = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.auth.user!;
    return Scaffold(
      backgroundColor: RColors.bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // ── Top bar with settings ─────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
                    child: Row(
                      children: [
                        Text('Profile',
                            style: RText.wordmark(size: 18)
                                .copyWith(letterSpacing: 1)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => MultiProvider(
                                providers: [
                                  ChangeNotifierProvider.value(
                                      value:
                                          context.read<SettingsController>()),
                                  ChangeNotifierProvider.value(
                                      value: widget.auth),
                                ],
                                child: const SettingsScreen(),
                              ),
                            ));
                          },
                          child: ClipOval(
                            child: BackdropFilter(
                              filter:
                                  ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: RColors.glass,
                                  border: Border.all(
                                      color: RColors.glassBorder),
                                ),
                                child: const Icon(Icons.settings_outlined,
                                    color: RColors.text, size: 18),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Avatar ───────────────────────────────────────────
                  _Avatar(user: user),

                  const SizedBox(height: 14),

                  // ── Name ─────────────────────────────────────────────
                  Text(user.name,
                      style: RText.body(
                          size: 20, weight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('@${user.username}',
                      style:
                          RText.body(size: 13, color: RColors.text3)),

                  const SizedBox(height: 20),

                  // ── Stats ────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Stat(
                          label: 'Saved',
                          value:
                              '${widget.auth.savedIds.length}'),
                      Container(
                          width: 1,
                          height: 28,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 28),
                          color: RColors.glassBorder),
                      _Stat(
                          label: 'Liked',
                          value:
                              '${widget.auth.likedIds.length}'),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── Tabs ─────────────────────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabDelegate(tab: _tab),
          ),
        ],
        body: TabBarView(
          controller: _tab,
          children: [
            _MovieGrid(
              cards: _savedCards,
              loading: _loadingCards,
              emptyIcon: Icons.bookmark_border_rounded,
              emptyText: 'No saved movies yet',
              emptyHint: 'Bookmark movies from the feed',
            ),
            _MovieGrid(
              cards: _likedCards,
              loading: _loadingCards,
              emptyIcon: Icons.favorite_border_rounded,
              emptyText: 'No liked movies yet',
              emptyHint: 'Heart movies you love in the feed',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Avatar ─────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final UserModel user;
  const _Avatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = user.photoUrl != null && user.photoUrl!.isNotEmpty;
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: !hasPhoto
            ? const LinearGradient(
                colors: [RColors.brandDeep, RColors.brand, RColors.brand2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: RColors.brand.withOpacity(0.38),
            blurRadius: 22,
            spreadRadius: 2,
          ),
        ],
      ),
      child: hasPhoto
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: user.photoUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _initial(user.name),
              ),
            )
          : _initial(user.name),
    );
  }

  Widget _initial(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'R';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 36,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Tab header delegate ────────────────────────────────────────────────────────

class _TabDelegate extends SliverPersistentHeaderDelegate {
  final TabController tab;
  const _TabDelegate({required this.tab});

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(_, double _, bool __) {
    return Container(
      color: RColors.bg,
      child: TabBar(
        controller: tab,
        indicatorColor: RColors.brand,
        indicatorWeight: 2.5,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: RText.body(size: 14, weight: FontWeight.w600),
        unselectedLabelStyle:
            RText.body(size: 14, color: RColors.text3),
        labelColor: RColors.brand,
        unselectedLabelColor: RColors.text3,
        tabs: const [
          Tab(text: 'Saved'),
          Tab(text: 'Liked'),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_) => false;
}

// ── Movie grid ─────────────────────────────────────────────────────────────────

class _MovieGrid extends StatelessWidget {
  final List<MovieCard?> cards;
  final bool loading;
  final IconData emptyIcon;
  final String emptyText;
  final String emptyHint;

  const _MovieGrid({
    required this.cards,
    required this.loading,
    required this.emptyIcon,
    required this.emptyText,
    required this.emptyHint,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: SamsungLoader(size: 36));
    }

    final valid = cards.whereType<MovieCard>().toList();

    if (valid.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: RColors.bgRaised,
                border: Border.all(color: RColors.glassBorder),
              ),
              child: Icon(emptyIcon, color: RColors.text3, size: 28),
            ),
            const SizedBox(height: 14),
            Text(emptyText,
                style: RText.body(
                    size: 15,
                    weight: FontWeight.w600,
                    color: RColors.text2)),
            const SizedBox(height: 6),
            Text(emptyHint,
                style: RText.body(size: 13, color: RColors.text3)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.68,
      ),
      itemCount: valid.length,
      itemBuilder: (ctx, i) => _MovieTile(movie: valid[i]),
    );
  }
}

// ── Movie tile ─────────────────────────────────────────────────────────────────

class _MovieTile extends StatelessWidget {
  final MovieCard movie;
  const _MovieTile({required this.movie});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openPlayer(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (movie.hasThumbnail)
              CachedNetworkImage(
                imageUrl: movie.thumbnailUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: RColors.bgCard),
                errorWidget: (_, __, ___) =>
                    Container(color: RColors.bgCard),
              )
            else
              Container(color: RColors.bgCard),

            // Gradient
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xCC07070B), Colors.transparent],
                  ),
                ),
              ),
            ),

            // Title
            Positioned(
              bottom: 6,
              left: 6,
              right: 6,
              child: Text(
                movie.title,
                style: RText.label(size: 10, color: RColors.text),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPlayer(BuildContext context) async {
    HapticFeedback.selectionClick();
    try {
      final detail = await ApiService.getMovie(movie.slug);
      if (!context.mounted) return;
      await Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, __, ___) => MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: (_) => PlayerController(
                  movie: detail.movie,
                  episodes: detail.episodes,
                ),
              ),
              ChangeNotifierProvider(create: (_) => SettingsController()),
            ],
            child: const PlayerScreen(),
          ),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    } catch (_) {}
  }
}

// ── Stat ──────────────────────────────────────────────────────────────────────

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: RText.body(size: 22, weight: FontWeight.w700)),
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
    final auth = context.watch<AuthService>();

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
          if (auth.isSignedIn) ...[
            _SLabel('Account'),
            _AccountTile(auth: auth),
            const SizedBox(height: 8),
          ],
          _SLabel('Playback'),
          _Toggle(
            icon: Icons.skip_next_rounded,
            label: 'Auto Next Episode',
            subtitle: 'Automatically play next episode',
            value: s.autoNext,
            onChanged: s.setAutoNext,
          ),
          _Picker(
            icon: Icons.hd_rounded,
            label: 'Video Quality',
            value: s.quality,
            options: const ['Auto', '1080p', '720p', '480p'],
            onChanged: s.setQuality,
          ),
          const SizedBox(height: 16),
          _SLabel('About'),
          _Tap(
              icon: Icons.info_outline_rounded,
              label: 'About Reelz',
              onTap: () {}),
          _Tap(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy Policy',
              onTap: () {}),
          _Tap(
              icon: Icons.description_outlined,
              label: 'Terms of Service',
              onTap: () {}),
          _Tap(
            icon: Icons.delete_sweep_outlined,
            label: 'Clear Cache',
            onTap: () => HapticFeedback.mediumImpact(),
          ),
          const SizedBox(height: 32),
          Center(
              child: Text('Reelz v1.0.0',
                  style: RText.label(color: RColors.text4))),
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final AuthService auth;
  const _AccountTile({required this.auth});

  @override
  Widget build(BuildContext context) {
    final user = auth.user!;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: RColors.bgRaised,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: RColors.glassBorder)),
      child: Row(
        children: [
          _Avatar(user: user),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    style:
                        RText.body(size: 14, weight: FontWeight.w600)),
                Text('@${user.username}',
                    style: RText.label(color: RColors.text3)),
                Text(user.email,
                    style: RText.label(
                        size: 10, color: RColors.text4)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              auth.signOut();
              Navigator.of(context).pop();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: RColors.glass,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: RColors.glassBorderMd),
              ),
              child: Text('Sign out',
                  style: RText.label(
                      size: 11, color: RColors.text2)),
            ),
          ),
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
        child: Text(label.toUpperCase(),
            style: RText.label(size: 11, color: RColors.brand)),
      );
}

class _Toggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final Function(bool) onChanged;

  const _Toggle({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
            color: RColors.bgRaised,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: RColors.glassBorder)),
        child: Row(children: [
          Icon(icon, color: RColors.text2, size: 20),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: RText.body(
                        size: 14, weight: FontWeight.w500)),
                Text(subtitle,
                    style: RText.label(color: RColors.text3)),
              ])),
          Switch(value: value, onChanged: onChanged),
        ]),
      );
}

class _Tap extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Tap(
      {required this.icon,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
              color: RColors.bgRaised,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: RColors.glassBorder)),
          child: Row(children: [
            Icon(icon, color: RColors.text2, size: 20),
            const SizedBox(width: 14),
            Expanded(
                child: Text(label,
                    style: RText.body(
                        size: 14, weight: FontWeight.w500))),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: RColors.text4, size: 14),
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

  const _Picker({
    required this.icon,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => showModalBottomSheet(
          context: context,
          backgroundColor: RColors.bgCard,
          shape: const RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: RColors.glassMd,
                      borderRadius: BorderRadius.circular(2))),
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
            ]),
          ),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
              color: RColors.bgRaised,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: RColors.glassBorder)),
          child: Row(children: [
            Icon(icon, color: RColors.text2, size: 20),
            const SizedBox(width: 14),
            Expanded(
                child: Text(label,
                    style: RText.body(
                        size: 14, weight: FontWeight.w500))),
            Text(value,
                style: RText.label(color: RColors.text3)),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: RColors.text4, size: 14),
          ]),
        ),
      );
}
