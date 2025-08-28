package com.crustdev.muziek

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity : FlutterActivity() {
	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		// Register native ad factory (must match factoryId used in Dart: 'smallAd')
		GoogleMobileAdsPlugin.registerNativeAdFactory(flutterEngine, "smallAd", SmallNativeAdFactory(layoutInflater))
	}

	override fun onDestroy() {
		// Unregister to avoid memory leaks / hot reload issues
		GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "smallAd")
		super.onDestroy()
	}
}
