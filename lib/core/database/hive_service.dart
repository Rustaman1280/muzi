import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String _songBox = 'songs';
  static const String _playlistBox = 'playlists';
  static const String _settingsBox = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Open boxes
    await Hive.openBox(_songBox);
    await Hive.openBox(_playlistBox);
    await Hive.openBox(_settingsBox);
  }

  static Box get songBox => Hive.box(_songBox);
  static Box get playlistBox => Hive.box(_playlistBox);
  static Box get settingsBox => Hive.box(_settingsBox);

  static Future<void> close() async {
    await Hive.close();
  }
}
