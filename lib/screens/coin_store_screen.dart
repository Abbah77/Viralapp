import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/coin_service.dart';
import '../theme/tokens.dart';
import '../widgets/dot_loader.dart';

class CoinStoreScreen extends StatefulWidget {
  const CoinStoreScreen({super.key});
  @override
  State<CoinStoreScreen> createState() => _CoinStoreScreenState();
}

class _CoinStoreScreenState extends State<CoinStoreScreen> with SingleTickerProviderStateMixin {
  late Timer _offerTick;
  int _countdown = 0;

  @override
  void initState() {
    super.initState();
    _offerTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _offerTick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coins = context.watch<CoinService>();

    return Scaffold(
      backgroundColor: RColors.bg,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(children: [
                    GestureDetector(
                      onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); },
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(color: RColors.bgRaised, borderRadius: BorderRadius.circular(12), border: Border.all(color: RColors.glassBorder)),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: RColors.text, size: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('Coin Store', style: RText.wordmark(size: 18)),
                    const Spacer(),
                    _CoinBadge(coins: coins.coins),
                  ]),
                ),
                const SizedBox(height: 24),
                _WalletHero(coins: coins.coins),
                const SizedBox(height: 20),
              ]),
            ),
          ),

          // ── New user offer ───────────────────────────────────────────────
          if (coins.newUserOfferActive)
            SliverToBoxAdapter(
              child: _NewUserBanner(coins: coins).animate().fadeIn().slideY(begin: -0.2, end: 0, curve: RCurve.spring),
            ),

          // ── Flash offer ──────────────────────────────────────────────────
          if (coins.activeOffer != null && !coins.activeOffer!.isExpired)
            SliverToBoxAdapter(
              child: _FlashOfferBanner(offer: coins.activeOffer!, coins: coins)
                  .animate().fadeIn().scale(begin: const Offset(0.96, 0.96), curve: RCurve.spring),
            ),

          // ── Packages ─────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Choose a package', style: RText.body(size: 13, color: RColors.text3)),
                  const SizedBox(height: 12),
                  ...CoinService.packages.asMap().entries.map((e) =>
                    _PackageCard(
                      pkg: e.value,
                      coinService: coins,
                      index: e.key,
                    ).animate().fadeIn(delay: Duration(milliseconds: e.key * 60)).slideY(begin: 0.2, end: 0, curve: RCurve.spring),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Wallet Hero ────────────────────────────────────────────────────────────────

class _WalletHero extends StatelessWidget {
  final int coins;
  const _WalletHero({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: RColors.brand.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: RColors.brand.withOpacity(0.2), blurRadius: 30, spreadRadius: 0)],
      ),
      child: Row(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [Color(0xFFFFBB38), Color(0xFFFF8C00)]),
            boxShadow: [BoxShadow(color: const Color(0xFFFFBB38).withOpacity(0.4), blurRadius: 16)],
          ),
          child: const Center(child: Text('🪙', style: TextStyle(fontSize: 26))),
        ),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Your Balance', style: RText.label(color: RColors.text3)),
          const SizedBox(height: 4),
          Text(
            '$coins coins',
            style: RText.body(size: 28, weight: FontWeight.w800, color: RColors.gold),
          ),
        ]),
      ]),
    );
  }
}

// ── New User Banner ────────────────────────────────────────────────────────────

class _NewUserBanner extends StatelessWidget {
  final CoinService coins;
  const _NewUserBanner({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B2FF7), Color(0xFFE040FB)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF7B2FF7).withOpacity(0.4), blurRadius: 20)],
      ),
      child: Row(children: [
        const Text('🎁', style: TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('New User Exclusive!', style: RText.body(size: 14, weight: FontWeight.w800, color: Colors.white)),
          Text('2× coins on ALL purchases — valid 7 days', style: RText.label(color: Colors.white70)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
          child: Text('ACTIVE', style: RText.label(size: 10, color: Colors.white)),
        ),
      ]),
    );
  }
}

// ── Flash Offer Banner ─────────────────────────────────────────────────────────

class _FlashOfferBanner extends StatefulWidget {
  final FlashOffer offer;
  final CoinService coins;
  const _FlashOfferBanner({required this.offer, required this.coins});
  @override
  State<_FlashOfferBanner> createState() => _FlashOfferBannerState();
}

class _FlashOfferBannerState extends State<_FlashOfferBanner> {
  late Timer _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() {}); });
  }

  @override
  void dispose() { _tick.cancel(); super.dispose(); }

  String _format(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.offer.remaining;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B00), Color(0xFFFF0080)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFFFF6B00).withOpacity(0.45), blurRadius: 24)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.offer.title, style: RText.body(size: 15, weight: FontWeight.w800, color: Colors.white)),
            Text(widget.offer.subtitle, style: RText.label(color: Colors.white70)),
          ])),
          GestureDetector(
            onTap: () { HapticFeedback.lightImpact(); widget.coins.dismissOffer(); },
            child: const Icon(Icons.close_rounded, color: Colors.white54, size: 18),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.timer_outlined, color: Colors.white70, size: 14),
          const SizedBox(width: 4),
          Text('Expires in ${_format(remaining)}', style: RText.label(color: Colors.white70)),
          const Spacer(),
          Text('Only 47 people grabbed this!', style: RText.label(size: 10, color: Colors.white54)),
        ]),
      ]),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
     .boxShadow(duration: 1200.ms,
       begin: const BoxShadow(color: Color(0x55FF6B00), blurRadius: 24),
       end: const BoxShadow(color: Color(0xAAFF6B00), blurRadius: 38));
  }
}

// ── Package Card ───────────────────────────────────────────────────────────────

class _PackageCard extends StatefulWidget {
  final CoinPackage pkg;
  final CoinService coinService;
  final int index;
  const _PackageCard({required this.pkg, required this.coinService, required this.index});
  @override
  State<_PackageCard> createState() => _PackageCardState();
}

class _PackageCardState extends State<_PackageCard> {
  bool _loading = false;
  bool _pressed = false;

  int get _displayCoins {
    final coins = widget.coinService;
    if (coins.newUserOfferActive) return widget.pkg.coins * 2;
    if (coins.activeOffer != null && !coins.activeOffer!.isExpired) {
      return widget.pkg.coins * coins.activeOffer!.multiplier;
    }
    return widget.pkg.coins;
  }

  bool get _hasBonus => _displayCoins > widget.pkg.coins;
  bool get _isMostPopular => widget.pkg.isMostPopular;
  bool get _isBestValue => widget.pkg.isBestValue;

  Future<void> _buy() async {
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    // TODO: Hook real IAP here (in_app_purchase package)
    await Future.delayed(const Duration(milliseconds: 800));
    await widget.coinService.purchasePackage(widget.pkg);
    if (mounted) {
      setState(() => _loading = false);
      _showSuccess();
    }
  }

  void _showSuccess() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PurchaseSuccess(coins: _displayCoins),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); _buy(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: RDur.xs,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _isMostPopular ? RColors.brand.withOpacity(0.08) : RColors.bgRaised,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isMostPopular ? RColors.brand.withOpacity(0.5)
                   : _isBestValue  ? RColors.gold.withOpacity(0.4)
                   : RColors.glassBorder,
              width: _isMostPopular || _isBestValue ? 1.5 : 1,
            ),
            boxShadow: _isMostPopular ? [BoxShadow(color: RColors.brand.withOpacity(0.15), blurRadius: 20)] : null,
          ),
          child: Stack(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                // Coin icon
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isBestValue
                        ? [const Color(0xFFFFBB38), const Color(0xFFFF8C00)]
                        : [RColors.brand.withOpacity(0.8), RColors.brand2],
                    ),
                    boxShadow: [BoxShadow(color: (_isBestValue ? RColors.gold : RColors.brand).withOpacity(0.35), blurRadius: 12)],
                  ),
                  child: const Center(child: Text('🪙', style: TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(
                      '$_displayCoins coins',
                      style: RText.body(size: 16, weight: FontWeight.w800,
                          color: _isBestValue ? RColors.gold : RColors.text),
                    ),
                    if (_hasBonus) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B2FF7).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF7B2FF7).withOpacity(0.4)),
                        ),
                        child: Text('BONUS!', style: RText.label(size: 9, color: Color(0xFFE040FB))),
                      ),
                    ],
                  ]),
                  if (_hasBonus)
                    Text('Was ${widget.pkg.coins} coins', style: RText.label(size: 10, color: RColors.text4,
                      letterSpacing: 0).copyWith(decoration: TextDecoration.lineThrough)),
                  if (widget.pkg.badge != null)
                    Text(widget.pkg.badge!, style: RText.label(size: 10, color: RColors.gold)),
                ])),
                // Price
                _loading
                  ? const SamsungLoader(size: 22)
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isMostPopular || _isBestValue
                            ? [RColors.brand, RColors.brand2]
                            : [RColors.bgSurface, RColors.bgSurface],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: !_isMostPopular && !_isBestValue ? Border.all(color: RColors.glassBorderMd) : null,
                      ),
                      child: Text(widget.pkg.formattedPrice,
                          style: RText.body(size: 14, weight: FontWeight.w700)),
                    ),
              ]),
            ),
            // Badge
            if (_isMostPopular)
              Positioned(top: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [RColors.brand, RColors.brand2]),
                    borderRadius: const BorderRadius.only(topRight: Radius.circular(16), bottomLeft: Radius.circular(10)),
                  ),
                  child: Text('MOST POPULAR', style: RText.label(size: 9, color: Colors.white)),
                ),
              ),
            if (_isBestValue)
              Positioned(top: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFFBB38), Color(0xFFFF8C00)]),
                    borderRadius: const BorderRadius.only(topRight: Radius.circular(16), bottomLeft: Radius.circular(10)),
                  ),
                  child: Text('BEST VALUE', style: RText.label(size: 9, color: Colors.white)),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

// ── Purchase Success Sheet ─────────────────────────────────────────────────────

class _PurchaseSuccess extends StatelessWidget {
  final int coins;
  const _PurchaseSuccess({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
      decoration: BoxDecoration(
        color: RColors.bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: RColors.glassBorderMd, width: 0.8)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4, decoration: BoxDecoration(color: RColors.glassMd, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 24),
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [Color(0xFFFFBB38), Color(0xFFFF8C00)]),
            boxShadow: [BoxShadow(color: const Color(0xFFFFBB38).withOpacity(0.5), blurRadius: 30)],
          ),
          child: const Center(child: Text('🎉', style: TextStyle(fontSize: 36))),
        ).animate().scale(begin: const Offset(0.5, 0.5), curve: RCurve.spring),
        const SizedBox(height: 16),
        Text('+$coins Coins Added!', style: RText.body(size: 22, weight: FontWeight.w800, color: RColors.gold))
            .animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 8),
        Text('Keep watching your favourites!', style: RText.body(size: 14, color: RColors.text3)),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: double.infinity, height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [RColors.brand, RColors.brand2]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: Text('Awesome!', style: RText.body(size: 15, weight: FontWeight.w700))),
          ),
        ),
      ]),
    );
  }
}

// ── Coin Badge ─────────────────────────────────────────────────────────────────

class _CoinBadge extends StatelessWidget {
  final int coins;
  const _CoinBadge({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: RColors.gold.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: RColors.gold.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Text('🪙', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 5),
        Text('$coins', style: RText.body(size: 13, weight: FontWeight.w700, color: RColors.gold)),
      ]),
    );
  }
}
