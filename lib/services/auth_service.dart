import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String username; // derived: email before @
  final String? photoUrl;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    this.photoUrl,
  });

  factory UserModel.fromGoogle(GoogleSignInAccount account) {
    final username = account.email.split('@').first;
    return UserModel(
      id: account.id,
      name: account.displayName ?? username,
      email: account.email,
      username: username,
      photoUrl: account.photoUrl,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'username': username,
    'photoUrl': photoUrl,
  };

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id: j['id'] as String,
    name: j['name'] as String,
    email: j['email'] as String,
    username: j['username'] as String,
    photoUrl: j['photoUrl'] as String?,
  );
}

class AuthService extends ChangeNotifier {
  static final _google = GoogleSignIn(
    serverClientId: '855194597614-8qh36vk8ijg3uq8aqse3nu6ffduus9m8.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );
  static const _kUser    = 'reelz_user';
  static const _kLiked   = 'reelz_liked';
  static const _kSaved   = 'reelz_saved';

  UserModel? _user;
  Set<int>   _liked = {};
  Set<int>   _saved = {};
  bool       _loading = true;

  UserModel? get user     => _user;
  bool       get isSignedIn => _user != null;
  bool       get loading  => _loading;
  Set<int>   get likedIds => _liked;
  Set<int>   get savedIds => _saved;

  bool isLiked(int id) => _liked.contains(id);
  bool isSaved(int id) => _saved.contains(id);

  /// Call once on app start
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUser);
    if (raw != null) {
      try {
        _user = UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        _liked = _loadSet(prefs, _kLiked);
        _saved = _loadSet(prefs, _kSaved);
      } catch (_) {}
    }
    _loading = false;
    notifyListeners();

    // Try silent re-auth if we have a saved user
    if (_user != null) {
      try {
        final account = await _google.signInSilently();
        if (account != null) _user = UserModel.fromGoogle(account);
      } catch (_) {}
    }
  }

  Set<int> _loadSet(SharedPreferences p, String key) {
    final list = p.getStringList(key) ?? [];
    return list.map((s) => int.tryParse(s) ?? -1).where((i) => i >= 0).toSet();
  }

  Future<void> _saveSet(String key, Set<int> set) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, set.map((i) => i.toString()).toList());
  }

  Future<UserModel?> signInWithGoogle() async {
    try {
      final account = await _google.signIn();
      if (account == null) return null;
      _user = UserModel.fromGoogle(account);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kUser, jsonEncode(_user!.toJson()));
      notifyListeners();
      return _user;
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _google.signOut();
    _user = null;
    _liked.clear();
    _saved.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUser);
    await prefs.remove(_kLiked);
    await prefs.remove(_kSaved);
    notifyListeners();
  }

  Future<void> toggleLike(int tmdbId) async {
    if (_liked.contains(tmdbId)) {
      _liked.remove(tmdbId);
    } else {
      _liked.add(tmdbId);
    }
    await _saveSet(_kLiked, _liked);
    notifyListeners();
  }

  Future<void> toggleSave(int tmdbId) async {
    if (_saved.contains(tmdbId)) {
      _saved.remove(tmdbId);
    } else {
      _saved.add(tmdbId);
    }
    await _saveSet(_kSaved, _saved);
    notifyListeners();
  }
}
