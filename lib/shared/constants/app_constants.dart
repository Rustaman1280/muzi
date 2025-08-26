class AppConstants {
  static const String appName = 'Muziek';
  static const String packageName = 'com.crustdev.muziek';
  
  // Audio formats
  static const List<String> supportedAudioFormats = [
    '.mp3',
    '.flac',
    '.wav',
    '.aac',
    '.ogg',
    '.m4a',
  ];
  
  // Hive box names
  static const String songBoxName = 'songs';
  static const String playlistBoxName = 'playlists';
  static const String settingsBoxName = 'settings';
  
  // Navigation
  static const String homeRoute = '/';
  static const String libraryRoute = '/library';
  static const String playerRoute = '/player';
  static const String settingsRoute = '/settings';
  
  // Settings keys
  static const String themeKey = 'theme';
  static const String volumeKey = 'volume';
  static const String repeatModeKey = 'repeat_mode';
  static const String shuffleModeKey = 'shuffle_mode';
}
