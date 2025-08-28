package com.crustdev.muziek

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.RatingBar
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory

class SmallNativeAdFactory(private val inflater: LayoutInflater): NativeAdFactory {
    override fun createNativeAd(nativeAd: NativeAd, customOptions: MutableMap<String, Any>?): NativeAdView {
        val adView = inflater.inflate(R.layout.native_ad_small, null) as NativeAdView

        val headline: TextView = adView.findViewById(R.id.ad_headline)
        val body: TextView = adView.findViewById(R.id.ad_body)
        val icon: ImageView = adView.findViewById(R.id.ad_app_icon)
        val media: MediaView = adView.findViewById(R.id.ad_media)
        val cta: Button = adView.findViewById(R.id.ad_call_to_action)
        val rating: RatingBar = adView.findViewById(R.id.ad_stars)

        adView.headlineView = headline
        adView.bodyView = body
        adView.iconView = icon
        adView.mediaView = media
        adView.callToActionView = cta
        adView.starRatingView = rating

        headline.text = nativeAd.headline
        body.text = nativeAd.body ?: ""
        cta.text = nativeAd.callToAction ?: "Install"
        val star = nativeAd.starRating?.toFloat() ?: 0f
        if(star > 0f){
            rating.rating = star
            rating.visibility = View.VISIBLE
        } else {
            rating.visibility = View.GONE
        }
        val iconDrawable = nativeAd.icon?.drawable
        if(iconDrawable != null){
            icon.setImageDrawable(iconDrawable)
            icon.visibility = View.VISIBLE
        } else {
            icon.visibility = View.GONE
        }

        adView.setNativeAd(nativeAd)
        return adView
    }
}
