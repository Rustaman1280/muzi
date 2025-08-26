import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  static Future<bool> requestAudioPermission() async {
    final status = await Permission.audio.request();
    return status.isGranted;
  }

  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  static Future<bool> hasStoragePermission() async {
    final status = await Permission.storage.status;
    return status.isGranted;
  }

  static Future<bool> hasAudioPermission() async {
    final status = await Permission.audio.status;
    return status.isGranted;
  }

  static Future<bool> hasNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  static Future<Map<String, bool>> requestAllPermissions() async {
    final results = await [
      Permission.storage,
      Permission.audio,
      Permission.notification,
    ].request();

    return {
      'storage': results[Permission.storage]?.isGranted ?? false,
      'audio': results[Permission.audio]?.isGranted ?? false,
      'notification': results[Permission.notification]?.isGranted ?? false,
    };
  }
}
