import 'package:flutter/foundation.dart';

class SettingsController extends ChangeNotifier {
  bool _autoNext = true;
  String _quality = 'Auto';

  bool get autoNext => _autoNext;
  String get quality => _quality;

  void setAutoNext(bool v) { _autoNext = v; notifyListeners(); }
  void setQuality(String v) { _quality = v; notifyListeners(); }
}
