import 'package:flutter/widgets.dart';
import 'core/sdk_config.dart';
import 'core/callbacks.dart';
import 'core/ad_type.dart';
import 'core/ad_position.dart';
import 'platform/bidscube_platform.dart';
import 'platform/method_channel_bidscube.dart';

/// Main BidsCube SDK class for Flutter
class BidscubeSDK {
  static BidscubePlatform _platform = MethodChannelBidscube();
  static bool _isInitialized = false;
  static SDKConfig? _config;

  /// Initialize the BidsCube SDK
  ///
  /// [config] - SDK configuration object
  static Future<void> initialize({required SDKConfig config}) async {
    _config = config;
    await _platform.initialize(config: config);
    _isInitialized = true;
  }

  /// Check if SDK is initialized
  static bool get isInitialized => _isInitialized;

  /// Get current SDK configuration
  static SDKConfig? get config => _config;

  /// Get Image Ad View
  ///
  /// [placementId] - Unique placement identifier
  /// [callback] - Ad callback handler
  static Future<Widget> getImageAdView(
    String placementId, {
    AdCallback? callback,
  }) async {
    _checkInitialized();
    return await _platform.getImageAdView(placementId, callback);
  }

  /// Get Video Ad View
  ///
  /// [placementId] - Unique placement identifier
  /// [callback] - Ad callback handler
  static Future<Widget> getVideoAdView(
    String placementId, {
    AdCallback? callback,
  }) async {
    _checkInitialized();
    return await _platform.getVideoAdView(placementId, callback);
  }

  /// Get Native Ad View
  ///
  /// [placementId] - Unique placement identifier
  /// [callback] - Ad callback handler
  static Future<Widget> getNativeAdView(
    String placementId, {
    AdCallback? callback,
  }) async {
    _checkInitialized();
    return await _platform.getNativeAdView(placementId, callback);
  }

  /// Get Banner Ad View
  ///
  /// [placementId] - Unique placement identifier
  /// [callback] - Ad callback handler
  static Future<Widget> getBannerAdView(
    String placementId, {
    AdCallback? callback,
  }) async {
    _checkInitialized();
    return await _platform.getBannerAdView(placementId, callback);
  }

  /// Request Ad
  ///
  /// [placementId] - Unique placement identifier
  /// [adType] - Type of ad to request
  /// [position] - Ad position
  /// [callback] - Ad callback handler
  static Future<void> requestAd({
    required String placementId,
    required AdType adType,
    AdPosition position = AdPosition.unknown,
    AdCallback? callback,
  }) async {
    _checkInitialized();
    await _platform.requestAd(
      placementId: placementId,
      adType: adType,
      position: position,
      callback: callback,
    );
  }

  /// Set Ad Callback
  ///
  /// [placementId] - Unique placement identifier
  /// [callback] - Ad callback handler
  static Future<void> setAdCallback(
    String placementId,
    AdCallback callback,
  ) async {
    _checkInitialized();
    await _platform.setAdCallback(placementId, callback);
  }

  /// Remove Ad Callback
  ///
  /// [placementId] - Unique placement identifier
  static Future<void> removeAdCallback(String placementId) async {
    _checkInitialized();
    await _platform.removeAdCallback(placementId);
  }

  /// Check if consent is required
  static bool isConsentRequired() {
    _checkInitialized();
    return _platform.isConsentRequired();
  }

  /// Check if ads consent is granted
  static bool hasAdsConsent() {
    _checkInitialized();
    return _platform.hasAdsConsent();
  }

  /// Check if analytics consent is granted
  static bool hasAnalyticsConsent() {
    _checkInitialized();
    return _platform.hasAnalyticsConsent();
  }

  /// Request consent info update
  ///
  /// [callback] - Consent callback handler
  static Future<void> requestConsentInfoUpdate({AdCallback? callback}) async {
    _checkInitialized();
    await _platform.requestConsentInfoUpdate(callback: callback);
  }

  /// Show consent form
  ///
  /// [callback] - Consent callback handler
  static Future<void> showConsentForm({AdCallback? callback}) async {
    _checkInitialized();
    await _platform.showConsentForm(callback: callback);
  }

  /// Get consent status summary
  static String getConsentStatusSummary() {
    _checkInitialized();
    return _platform.getConsentStatusSummary();
  }

  /// Enable consent debug mode
  ///
  /// [testDeviceId] - Test device ID for debugging
  static void enableConsentDebugMode(String testDeviceId) {
    _checkInitialized();
    _platform.enableConsentDebugMode(testDeviceId);
  }

  /// Reset consent information
  static void resetConsent() {
    _checkInitialized();
    _platform.resetConsent();
  }

  /// Cleanup SDK
  static void cleanup() {
    _platform.cleanup();
    _isInitialized = false;
    _config = null;
  }

  /// Check if SDK is initialized
  static void _checkInitialized() {
    if (!_isInitialized) {
      throw Exception('BidscubeSDK not initialized. Call initialize() first.');
    }
  }
}
