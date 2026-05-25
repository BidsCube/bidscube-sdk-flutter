package com.bidscube.bidscube_sdk_flutter

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Flutter ↔ Android Bidscube bridge.
 *
 * **Expected Dart callbacks (invoke from native/thread main):**
 * `onAdLoading`, `onAdLoaded`, `onAdDisplayed`, `onAdFailed`, `onAdClicked`,
 * `onAdClosed`, `onVideoAdStarted`, `onVideoAdCompleted`, `onVideoAdSkipped`,
 * `onUserRewarded`
 *
 * Use argument map `{ "placementId": id }` plus `errorCode`, `errorMessage` for failures
 * (`onAdFailed`), matching Dart [MethodChannelBidscube].
 */
class BidscubeSdkPlugin : FlutterPlugin, MethodCallHandler {

    companion object {
        private const val TAG = "BidscubeSdkFlutter"
    }

    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "bidscube_sdk")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> {
                @Suppress("UNCHECKED_CAST")
                val map = call.arguments as? Map<String, Any?> ?: emptyMap()
                initializeSDK(map, result)
            }
            "getImageAdView" -> {
                val placementId = call.argument<String>("placementId")
                getImageAdView(placementId, call.arguments, result)
            }
            "getVideoAdView", "getInterstitialVideoAdView" -> {
                val placementId = call.argument<String>("placementId")
                val videoFormat = call.argument<String>("videoAdFormat")
                    ?: "interstitial"
                _logVideoRequest("interstitial", placementId, videoFormat)
                getInterstitialVideoPlaceholder(placementId, result)
            }
            "getRewardedVideoAdView" -> {
                val placementId = call.argument<String>("placementId")
                val videoFormat = call.argument<String>("videoAdFormat")
                    ?: "rewarded"
                _logVideoRequest("rewarded", placementId, videoFormat)
                getRewardedVideoPlaceholder(placementId, result)
            }
            "getNativeAdView" -> {
                val placementId = call.argument<String>("placementId")
                getNativeAdView(placementId, result)
            }
            "getBannerAdView" -> {
                val placementId = call.argument<String>("placementId")
                getBannerAdView(placementId, result)
            }
            "requestAd" -> {
                val placementId = call.argument<String>("placementId")
                val adType = call.argument<String>("adType")
                val position = call.argument<String>("position")
                requestAd(placementId, adType, position, result)
            }
            "removeAdCallback" -> {
                val placementId = call.argument<String>("placementId")
                removeAdCallback(placementId, result)
            }
            "requestConsentInfoUpdate" -> {
                requestConsentInfoUpdate(result)
            }
            "showConsentForm" -> {
                showConsentForm(result)
            }
            "getSKAdNetworkIds" -> {
                // Flutter API is iOS-centric; Android returns empty list.
                result.success(emptyList<String>())
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun _logVideoRequest(role: String, placementId: String?, videoAdFormatArg: String) {
        Log.d(
            TAG,
            "Flutter requested $role video placementId=$placementId videoAdFormat=$videoAdFormatArg " +
                    "(native Bidscube view factory not yet bridged)",
        )
    }

    private fun initializeSDK(_config: Map<String, Any?>?, result: Result) {
        try {
            // TODO: BidscubeSDK.initialize(context, sdkConfigFrom(config)) when bridged.
            result.success("SDK initialized successfully")
        } catch (e: Exception) {
            result.error("INITIALIZATION_ERROR", "Failed to initialize SDK: ${e.message}", null)
        }
    }

    private fun getImageAdView(placementId: String?, _: Any?, result: Result) {
        try {
            // TODO: Create and return actual image ad platform view registration
            result.success("ImageAdView created for placement: $placementId")
        } catch (e: Exception) {
            result.error("IMAGE_AD_ERROR", "Failed to create image ad view: ${e.message}", null)
        }
    }

    private fun getInterstitialVideoPlaceholder(placementId: String?, result: Result) {
        try {
            // TODO: BidscubeSDK.getInterstitialVideoAdView(...) + PlatformView registration
            result.success("VideoAdView (interstitial) placeholder for placement: $placementId")
        } catch (e: Exception) {
            result.error("VIDEO_AD_ERROR", "Failed to create interstitial video ad view: ${e.message}", null)
        }
    }

    private fun getRewardedVideoPlaceholder(placementId: String?, result: Result) {
        try {
            // TODO: BidscubeSDK.getRewardedVideoAdView(...) + PlatformView registration
            result.success("VideoAdView (rewarded) placeholder for placement: $placementId")
        } catch (e: Exception) {
            result.error("VIDEO_AD_ERROR", "Failed to create rewarded video ad view: ${e.message}", null)
        }
    }

    private fun getNativeAdView(placementId: String?, result: Result) {
        try {
            // TODO: Create and return actual native ad view
            result.success("NativeAdView created for placement: $placementId")
        } catch (e: Exception) {
            result.error("NATIVE_AD_ERROR", "Failed to create native ad view: ${e.message}", null)
        }
    }

    private fun getBannerAdView(placementId: String?, result: Result) {
        try {
            // TODO: Create and return actual banner ad view
            result.success("BannerAdView created for placement: $placementId")
        } catch (e: Exception) {
            result.error("BANNER_AD_ERROR", "Failed to create banner ad view: ${e.message}", null)
        }
    }

    private fun requestAd(placementId: String?, adType: String?, position: String?, result: Result) {
        try {
            // TODO: Request actual ad
            result.success(
                "Ad requested for placement: $placementId, type: $adType, position: $position",
            )
        } catch (e: Exception) {
            result.error("REQUEST_AD_ERROR", "Failed to request ad: ${e.message}", null)
        }
    }

    private fun removeAdCallback(placementId: String?, result: Result) {
        try {
            // TODO: Detach Bidscube native listeners keyed by placement
            result.success("Ad callback removed for placement: $placementId")
        } catch (e: Exception) {
            result.error("REMOVE_CALLBACK_ERROR", "Failed to remove ad callback: ${e.message}", null)
        }
    }

    private fun requestConsentInfoUpdate(result: Result) {
        try {
            result.success("Consent info update requested")
        } catch (e: Exception) {
            result.error("CONSENT_INFO_ERROR", "Failed to request consent info update: ${e.message}", null)
        }
    }

    private fun showConsentForm(result: Result) {
        try {
            result.success("Consent form shown")
        } catch (e: Exception) {
            result.error("CONSENT_FORM_ERROR", "Failed to show consent form: ${e.message}", null)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
