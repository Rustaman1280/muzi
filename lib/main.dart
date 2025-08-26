import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app/app.dart';
import 'core/database/hive_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  await HiveService.init();
  
  // Request permissions
  await _requestPermissions();
  
  runApp(
    ProviderScope(
      child: const MuziekApp(),
    ),
  );
}

Future<void> _requestPermissions() async {
  // Request storage permission
  await Permission.storage.request();
  
  // Request audio permission if needed
  await Permission.audio.request();
  
  // Request notification permission for Android 13+
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}


