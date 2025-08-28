import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../features/home/home_screen.dart';
import '../features/download/download_screen.dart';
import '../features/player/player_screen.dart';
import '../shared/widgets/main_scaffold.dart';

final interstitialAdProvider = ChangeNotifierProvider<InterstitialAdManager>((ref){
  final m = InterstitialAdManager();
  m.load();
  return m;
});

class InterstitialAdManager extends ChangeNotifier {
  InterstitialAd? _ad;
  bool _loading = false;
  int _failed = 0;
  static const _adUnitId = 'ca-app-pub-9165746388253869/3845483808';
  bool get isReady => _ad != null;

  void load(){
    if(_ad!=null || _loading) return;
    _loading = true;
    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad){
          _ad = ad;
          _loading = false;
          _failed = 0;
          notifyListeners();
        },
        onAdFailedToLoad: (err){
          _loading = false;
          _failed++;
          if(_failed < 3){ load(); }
          notifyListeners();
        },
      ),
    );
  }

  Future<void> showIfAvailable({VoidCallback? onDismissed}) async {
    final ad = _ad;
    if(ad == null){
      load();
      onDismissed?.call();
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad){
    ad.dispose();
    _ad = null; notifyListeners();
    load(); onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, err){
        ad.dispose();
    _ad = null; notifyListeners();
    load(); onDismissed?.call();
      },
    );
    ad.show();
  _ad = null; notifyListeners();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  // Interstitial preloaded via provider initialization
  ref.read(interstitialAdProvider); // ensure loaded

  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/download',
            name: 'download',
            builder: (context, state) => const DownloadScreen(),
          ),
        ],
      ),
      // Player outside shell so bottom bar is hidden reliably and no caching interference
      GoRoute(
        path: '/player',
        name: 'player',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return PlayerScreen(
            title: extra?['title'] ?? 'Unknown',
            artist: extra?['artist'] ?? 'Unknown',
            artwork: extra?['artwork'] ?? const AssetImage('assets/images/foto (1).jpg'),
            duration: extra?['duration'] ?? Duration.zero,
            position: extra?['position'] ?? Duration.zero,
            isPlaying: extra?['playing'] ?? false,
          );
        },
      ),
    ],
  );
});
