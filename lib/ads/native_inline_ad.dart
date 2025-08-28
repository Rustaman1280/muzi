import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Displays a single native advanced ad (Android only) using factoryId 'smallAd'.
class NativeInlineAd extends StatefulWidget {
  final EdgeInsetsGeometry padding;
  const NativeInlineAd({super.key, this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12)});
  @override
  State<NativeInlineAd> createState() => _NativeInlineAdState();
}

class _NativeInlineAdState extends State<NativeInlineAd> {
  NativeAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if(Platform.isAndroid){
      _load();
    }
  }

  void _load(){
    final ad = NativeAd(
      adUnitId: 'ca-app-pub-9165746388253869/6924757495',
      factoryId: 'smallAd',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad){
          if(!mounted) return;
          setState(()=> _loaded = true);
        },
        onAdFailedToLoad: (ad, error){
          ad.dispose();
        },
      ),
    );
    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if(!Platform.isAndroid){
      return const SizedBox.shrink();
    }
    if(!_loaded || _ad == null){
      return const SizedBox.shrink();
    }
    return Padding(
      padding: widget.padding,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(.35),
          height: 120,
          alignment: Alignment.center,
          child: AdWidget(ad: _ad!),
        ),
      ),
    );
  }
}
