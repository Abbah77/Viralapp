import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/video.dart' as models;

class PlayerCache {
  static const int maxActivePlayers = 5;
  
  final Map<String, Player> _players = {};
  final Map<String, VideoController> _controllers = {};

  Player? getPlayer(String videoId) => _players[videoId];
  VideoController? getController(String videoId) => _controllers[videoId];

  Future<Player> createPlayer(models.Video video) async {
    if (_players.length >= maxActivePlayers) {
      _evictOldest();
    }

    final player = Player(
      configuration: const PlayerConfiguration(),
    );
    
    await player.open(
      Media(video.videoUrl),
      play: false,
    );
    
    _players[video.id] = player;
    _controllers[video.id] = VideoController(player);
    
    return player;
  }

  Future<void> preloadVideo(String videoUrl) async {
    final player = Player();
    await player.open(Media(videoUrl), play: false);
    await player.dispose();
  }

  void _evictOldest() {
    if (_players.isNotEmpty) {
      final oldestKey = _players.keys.first;
      disposePlayer(oldestKey);
    }
  }

  void disposePlayer(String videoId) {
    _players[videoId]?.dispose();
    _players.remove(videoId);
    _controllers.remove(videoId);
  }

  void disposeAll() {
    for (var player in _players.values) {
      player.dispose();
    }
    _players.clear();
    _controllers.clear();
  }
}
