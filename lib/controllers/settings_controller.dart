import 'package:flutter/foundation.dart';

class SettingsController extends ChangeNotifier {
  bool _autoNextEpisode = true;
  String _videoQuality = 'Auto';

  bool get autoNextEpisode => _autoNextEpisode;
  String get videoQuality => _videoQuality;

  void setAutoNextEpisode(bool val) {
    _autoNextEpisode = val;
    notifyListeners();
  }

  void setVideoQuality(String val) {
    _videoQuality = val;
    notifyListeners();
  }
}
