import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app/app.dart';
import 'core/database/hive_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive only via service (service already calls Hive.initFlutter)
  await HiveService.init();
  debugPrint('Hive initialized');

  runApp(
    ProviderScope(
      child: const MuziekApp(),
    ),
  );
  debugPrint('App started, scheduling permission requests');

  // Defer permission requests until after first frame so Activity is ready
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _requestPermissions();
  });
}

Future<void> _requestPermissions() async {
  try {
  debugPrint('Requesting permissions...');
    await Permission.storage.request();
    // Some devices use media library permissions; request if present
  // Request audio permission (may be ignored on devices that don't define it)
  await Permission.audio.request();
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  debugPrint('Permission flow complete');
  } catch (_) {
    // Ignore startup permission errors; UI flow can retry later
  debugPrint('Permission request failed (ignored)');
  }
}


