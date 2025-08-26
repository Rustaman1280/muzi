import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import 'mini_player.dart';

class MainScaffold extends ConsumerWidget {
  final Widget child;

  const MainScaffold({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
  final audioState = ref.watch(audioControllerProvider);
    final currentLocation = GoRouterState.of(context).uri.path;

    return Scaffold(
      body: Column(
        children: [
          Expanded(child: child),
          // Mini Player - shows when something is playing
          if (audioState.current != null)
            const MiniPlayer(),
          // Bottom Navigation Bar
          BottomNavigationBar(
            currentIndex: _getIndexFromLocation(currentLocation),
            onTap: (index) => _onTabTapped(context, index),
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.download),
                label: 'Download',
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _getIndexFromLocation(String location) {
    switch (location) {
      case '/':
        return 0;
      case '/download':
        return 1;
      default:
        return 0;
    }
  }

  void _onTabTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/download');
        break;
    }
  }
}
