import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String username;
  final String? photoUrl;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    this.photoUrl,
  });

  factory UserModel.fromGoogle(GoogleSignInAccount account) {
    return UserModel(
      id: account.id,
      name: account.displayName ?? account.email.split('@').first,
      email: account.email,
      username: account.email.split('@').first,
      photoUrl: account.photoUrl,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'email': email,
    'username': username, 'photoUrl': photoUrl,
  };

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id: j['id'], name: j['name'], email: j['email'],
    username: j['username'], photoUrl: j['photoUrl'],
  );
}

class AuthService extends ChangeNotifier {
  static const _base = 'https://tt-b577.onrender.com';
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  static final _google = GoogleSignIn(
    serverClientId: '855194597614-8qh36vk8ijg3uq8aqse3nu6ffduus9m8.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  static const _kUser  = 'reelz_user';
  static const _kLiked = 'reelz_liked';
  static const _kSaved = 'reelz_saved';

  UserModel? _user;
  Set<int>   _liked = {};
  Set<int>   _saved = {};
  bool       _loading = true;

  UserModel? get user      => _user;
  bool       get isSignedIn => _user != null;
  bool       get loading   => _loading;
  Set<int>   get likedIds  => _liked;
  Set<int>   get savedIds  => _saved;

  bool isLiked(int id) => _liked.contains(id);
  bool isSaved(int id) => _saved.contains(id);

  /// On app start — restore local user then sync from Supabase via backend
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUser);
    if (raw != null) {
      try {
        _user = UserModel.fromJson(jsonDecode(raw));
        _liked = _loadSet(prefs, _kLiked);
        _saved = _loadSet(prefs, _kSaved);
      } catch (_) {}
    }
    _loading = false;
    notifyListeners();

    // Sync from backend in background
    if (_user != null) {
      _syncFromBackend();
      // Try silent re-auth
      try {
        final account = await _google.signInSilently();
        if (account != null) {
          _user = UserModel.fromGoogle(account);
          notifyListeners();
        }
      } catch (_) {}
    }
  }

  /// Pull liked/saved from Supabase via backend — restores data on new device
  Future<void> _syncFromBackend() async {
    if (_user == null) return;
    try {
      final res = await _dio.get('$_base/user/${_user!.id}/interactions');
      final data = res.data as Map<String, dynamic>;
      final liked = (data['liked'] as List).cast<int>().toSet();
      final saved = (data['saved'] as List).cast<int>().toSet();
      _liked = liked;
      _saved = saved;
      // Persist locally
      final prefs = await SharedPreferences.getInstance();
      await _saveSet(prefs, _kLiked, _liked);
      await _saveSet(prefs, _kSaved, _saved);
      notifyListeners();
    } catch (e) {
      debugPrint('Sync error: $e');
    }
  }

  Future<UserModel?> signInWithGoogle() async {
    try {
      final account = await _google.signIn();
      if (account == null) return null;
      _user = UserModel.fromGoogle(account);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kUser, jsonEncode(_user!.toJson()));
      notifyListeners();
      // Fetch their data from Supabase after sign in
      await _syncFromBackend();
      return _user;
    } catch (e) {
      debugPrint('Sign-in error: $e');
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
    notifyListeners();
    await _persist();
    await _postToggle('like', tmdbId);
  }

  Future<void> toggleSave(int tmdbId) async {
    if (_saved.contains(tmdbId)) {
      _saved.remove(tmdbId);
    } else {
      _saved.add(tmdbId);
    }
    notifyListeners();
    await _persist();
    await _postToggle('save', tmdbId);
  }

  /// Tell backend to toggle in Supabase
  Future<void> _postToggle(String kind, int tmdbId) async {
    if (_user == null) return;
    try {
      await _dio.post('$_base/user/${_user!.id}/$kind/$tmdbId');
    } catch (e) {
      debugPrint('Toggle $kind error: $e');
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await _saveSet(prefs, _kLiked, _liked);
    await _saveSet(prefs, _kSaved, _saved);
  }

  Set<int> _loadSet(SharedPreferences p, String key) {
    final list = p.getStringList(key) ?? [];
    return list.map((s) => int.tryParse(s) ?? -1).where((i) => i >= 0).toSet();
  }

  Future<void> _saveSet(SharedPreferences p, String key, Set<int> set) async {
    await p.setStringList(key, set.map((i) => i.toString()).toList());
  }
}
