import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Coin packages available for purchase
class CoinPackage {
  final String id;
  final int coins;
  final double price;
  final String label;
  final String? badge;
  final bool isMostPopular;
  final bool isBestValue;

  const CoinPackage({
    required this.id,
    required this.coins,
    required this.price,
    required this.label,
    this.badge,
    this.isMostPopular = false,
    this.isBestValue = false,
  });

  int get originalCoins => coins; // used for crossed-out display
  String get formattedPrice => '\$${price.toStringAsFixed(2)}';
}

/// Flash offer — appears randomly, expires after duration
class FlashOffer {
  final String id;
  final String title;
  final String subtitle;
  final int multiplier; // 2x, 3x
  final DateTime expiresAt;
  final CoinPackage package;

  FlashOffer({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.multiplier,
    required this.expiresAt,
    required this.package,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  Duration get remaining => expiresAt.difference(DateTime.now());
}

class CoinService extends ChangeNotifier {
  static const String _coinKey = 'user_coins';
  static const String _newUserKey = 'is_new_user';
  static const String _installDateKey = 'install_date';
  static const String _totalPurchasedKey = 'total_purchased';

  int _coins = 0;
  bool _isNewUser = false;
  DateTime? _installDate;
  FlashOffer? _activeOffer;
  Timer? _offerTimer;
  Timer? _offerScheduler;

  int get coins => _coins;
  bool get isNewUser => _isNewUser;
  FlashOffer? get activeOffer => _activeOffer;
  bool get newUserOfferActive {
    if (!_isNewUser || _installDate == null) return false;
    return DateTime.now().difference(_installDate!).inDays < 7;
  }

  // ── Standard packages ──────────────────────────────────────────────────────
  static const List<CoinPackage> packages = [
    CoinPackage(id: 'coins_80',   coins: 80,   price: 0.99,  label: '80 Coins'),
    CoinPackage(id: 'coins_400',  coins: 400,  price: 4.99,  label: '400 Coins',  isMostPopular: true),
    CoinPackage(id: 'coins_900',  coins: 900,  price: 9.99,  label: '900 Coins'),
    CoinPackage(id: 'coins_2000', coins: 2000, price: 19.99, label: '2000 Coins', isBestValue: true),
    CoinPackage(id: 'coins_5500', coins: 5500, price: 49.99, label: '5500 Coins', badge: '🔥 MAX VALUE'),
  ];

  // ── Episode unlock costs ───────────────────────────────────────────────────
  static const int episodeUnlockCost = 10;
  static const int finaleUnlockCost  = 20;
  static const int freeEpisodesCount = 5;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _coins = prefs.getInt(_coinKey) ?? 0;
    _isNewUser = prefs.getBool(_newUserKey) ?? true;

    final installMs = prefs.getInt(_installDateKey);
    if (installMs == null) {
      _installDate = DateTime.now();
      await prefs.setInt(_installDateKey, _installDate!.millisecondsSinceEpoch);
      // New user: give welcome coins
      await _addCoins(30);
    } else {
      _installDate = DateTime.fromMillisecondsSinceEpoch(installMs);
    }

    _scheduleRandomOffer();
    notifyListeners();
  }

  // ── Coin operations ────────────────────────────────────────────────────────

  Future<bool> unlockEpisode(int episodeNumber, {bool isFinale = false}) async {
    final cost = isFinale ? finaleUnlockCost : episodeUnlockCost;
    if (_coins < cost) return false;
    await _deductCoins(cost);
    return true;
  }

  Future<void> earnFromAd(int amount) async {
    await _addCoins(amount);
  }

  Future<void> earnFromQuest(int amount) async {
    await _addCoins(amount);
  }

  Future<void> purchasePackage(CoinPackage pkg) async {
    int coins = pkg.coins;
    // New user 2x bonus
    if (newUserOfferActive) coins = coins * 2;
    // Active flash offer multiplier
    if (_activeOffer != null && !_activeOffer!.isExpired) {
      coins = (pkg.coins * _activeOffer!.multiplier);
    }
    await _addCoins(coins);
    final prefs = await SharedPreferences.getInstance();
    final prev = prefs.getInt(_totalPurchasedKey) ?? 0;
    await prefs.setInt(_totalPurchasedKey, prev + pkg.coins);
  }

  bool canUnlock(int episodeNumber, {bool isFinale = false}) {
    final cost = isFinale ? finaleUnlockCost : episodeUnlockCost;
    return _coins >= cost;
  }

  bool isEpisodeFree(int episodeNumber) {
    return episodeNumber <= freeEpisodesCount;
  }

  // ── Flash offers (random psychology) ──────────────────────────────────────

  void _scheduleRandomOffer() {
    // Show first offer between 3-8 minutes after launch
    final delay = Duration(minutes: 3 + (DateTime.now().millisecond % 5));
    _offerScheduler = Timer(delay, _showRandomOffer);
  }

  void _showRandomOffer() {
    final offers = [
      FlashOffer(
        id: 'flash_2x',
        title: '🔥 2X Coins — Today Only!',
        subtitle: 'Double coins on any purchase',
        multiplier: 2,
        expiresAt: DateTime.now().add(const Duration(hours: 2)),
        package: packages[1],
      ),
      FlashOffer(
        id: 'flash_3x',
        title: '⚡ 3X Coins Flash Sale!',
        subtitle: 'Triple coins — limited time',
        multiplier: 3,
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        package: packages[2],
      ),
      FlashOffer(
        id: 'flash_70off',
        title: '🎉 Exclusive — Save 70%!',
        subtitle: 'Best deal you\'ll see today',
        multiplier: 2,
        expiresAt: DateTime.now().add(const Duration(minutes: 90)),
        package: packages[3],
      ),
    ];

    final idx = DateTime.now().millisecond % offers.length;
    _activeOffer = offers[idx];
    _offerTimer?.cancel();
    _offerTimer = Timer(_activeOffer!.expiresAt.difference(DateTime.now()), () {
      _activeOffer = null;
      notifyListeners();
      // Schedule next random offer after 10-20 min
      final next = Duration(minutes: 10 + (DateTime.now().second % 10));
      _offerScheduler = Timer(next, _showRandomOffer);
    });
    notifyListeners();
  }

  void dismissOffer() {
    _activeOffer = null;
    notifyListeners();
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  Future<void> _addCoins(int amount) async {
    _coins += amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_coinKey, _coins);
    notifyListeners();
  }

  Future<void> _deductCoins(int amount) async {
    _coins = (_coins - amount).clamp(0, 9999999);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_coinKey, _coins);
    notifyListeners();
  }

  @override
  void dispose() {
    _offerTimer?.cancel();
    _offerScheduler?.cancel();
    super.dispose();
  }
}
