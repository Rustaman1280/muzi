import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../shared/providers/app_providers.dart';

class MuziekApp extends ConsumerWidget {
  const MuziekApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    final darkScheme = ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark);
    return MaterialApp.router(
      title: 'Muziek',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        colorScheme: darkScheme,
        scaffoldBackgroundColor: const Color(0xFF0E121B),
        useMaterial3: true,
        textTheme: Typography.whiteMountainView.apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      theme: ThemeData(
        colorScheme: darkScheme,
        scaffoldBackgroundColor: const Color(0xFF0E121B),
        useMaterial3: true,
        textTheme: Typography.whiteMountainView.apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      routerConfig: router,
    );
  }
}
