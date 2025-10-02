import 'package:flutter/widgets.dart';
import '../core/sdk_config.dart';
import '../core/callbacks.dart';
import '../core/ad_type.dart';
import '../core/ad_position.dart';

/// Platform abstraction for BidsCube SDK
abstract class BidscubePlatform {
  /// Initialize the platform
  Future<void> initialize({required SDKConfig config});

  /// Get Image Ad View
  Future<Widget> getImageAdView(String placementId, AdCallback? callback);

  /// Get Video Ad View
  Future<Widget> getVideoAdView(String placementId, AdCallback? callback);

  /// Get Native Ad View
  Future<Widget> getNativeAdView(String placementId, AdCallback? callback);

  /// Get Banner Ad View
  Future<Widget> getBannerAdView(String placementId, AdCallback? callback);

  /// Request Ad
  Future<void> requestAd({
    required String placementId,
    required AdType adType,
    AdPosition position = AdPosition.unknown,
    AdCallback? callback,
  });

  /// Set Ad Callback
  Future<void> setAdCallback(String placementId, AdCallback callback);

  /// Remove Ad Callback
  Future<void> removeAdCallback(String placementId);
}
