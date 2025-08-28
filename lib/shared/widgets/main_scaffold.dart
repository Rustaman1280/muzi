import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../../app/router.dart';
import 'mini_player.dart';

class MainScaffold extends ConsumerStatefulWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});
  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  final _pageCache = <String, Widget>{};

  Widget _getOrCreate(String path, Widget child){
    if(path == '/player') return child; // never cache player
    return _pageCache.putIfAbsent(path, () => child);
  }

  @override
  Widget build(BuildContext context) {
  final audioState = ref.watch(audioControllerProvider);
    final currentLocation = GoRouterState.of(context).uri.path;

  final onPlayer = currentLocation == '/player';
  return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(child: _getOrCreate(currentLocation, widget.child)),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
        if (!onPlayer && audioState.current != null) const MiniPlayer(),
        if(!onPlayer) ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        border: const Border(top: BorderSide(color: Colors.white24, width: 0.6)),
                      ),
                      child: BottomNavigationBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        selectedItemColor: Theme.of(context).colorScheme.primary,
                        unselectedItemColor: Colors.white70,
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
                    ),
                  ),
                ),
              ],
            ),
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
        // show interstitial before navigating (if available)
        ref.read(interstitialAdProvider).showIfAvailable(onDismissed: (){ context.go('/download'); });
        // fallback navigate if ad not ready (showIfAvailable calls onDismissed immediately when null)
        break;
    }
  }
}
