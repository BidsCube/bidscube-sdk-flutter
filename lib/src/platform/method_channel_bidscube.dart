import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'bidscube_platform.dart';
import '../core/sdk_config.dart';
import '../core/callbacks.dart';
import '../core/ad_type.dart';
import '../core/ad_position.dart';
import '../core/logger.dart';

/// Method channel implementation for BidsCube SDK
class MethodChannelBidscube extends BidscubePlatform {
  static const MethodChannel _channel = MethodChannel('bidscube_sdk');

  @override
  Future<void> initialize({required SDKConfig config}) async {
    try {
      await _channel.invokeMethod('initialize', config.toMap());
      SDKLogger.info('BidsCube SDK initialized successfully');
    } on PlatformException catch (e) {
      SDKLogger.error('Failed to initialize BidsCube SDK', e);
      rethrow;
    }
  }

  @override
  Future<Widget> getImageAdView(String placementId, AdCallback? callback) async {
    try {
      final result = await _channel.invokeMethod('getImageAdView', {
        'placementId': placementId,
      });
      
      if (callback != null) {
        _setCallback(placementId, callback);
      }
      
      return _createAdWidget(result, placementId, callback);
    } on PlatformException catch (e) {
      SDKLogger.error('Failed to get image ad view', e);
      rethrow;
    }
  }

  @override
  Future<Widget> getVideoAdView(String placementId, AdCallback? callback) async {
    try {
      final result = await _channel.invokeMethod('getVideoAdView', {
        'placementId': placementId,
      });
      
      if (callback != null) {
        _setCallback(placementId, callback);
      }
      
      return _createAdWidget(result, placementId, callback);
    } on PlatformException catch (e) {
      SDKLogger.error('Failed to get video ad view', e);
      rethrow;
    }
  }

  @override
  Future<Widget> getNativeAdView(String placementId, AdCallback? callback) async {
    try {
      final result = await _channel.invokeMethod('getNativeAdView', {
        'placementId': placementId,
      });
      
      if (callback != null) {
        _setCallback(placementId, callback);
      }
      
      return _createAdWidget(result, placementId, callback);
    } on PlatformException catch (e) {
      SDKLogger.error('Failed to get native ad view', e);
      rethrow;
    }
  }

  @override
  Future<Widget> getBannerAdView(String placementId, AdCallback? callback) async {
    try {
      final result = await _channel.invokeMethod('getBannerAdView', {
        'placementId': placementId,
      });
      
      if (callback != null) {
        _setCallback(placementId, callback);
      }
      
      return _createAdWidget(result, placementId, callback);
    } on PlatformException catch (e) {
      SDKLogger.error('Failed to get banner ad view', e);
      rethrow;
    }
  }

  @override
  Future<void> requestAd({
    required String placementId,
    required AdType adType,
    AdPosition position = AdPosition.unknown,
    AdCallback? callback,
  }) async {
    try {
      await _channel.invokeMethod('requestAd', {
        'placementId': placementId,
        'adType': adType.value,
        'position': position.value,
      });
      
      if (callback != null) {
        _setCallback(placementId, callback);
      }
    } on PlatformException catch (e) {
      SDKLogger.error('Failed to request ad', e);
      rethrow;
    }
  }

  @override
  Future<void> setAdCallback(String placementId, AdCallback callback) async {
    _setCallback(placementId, callback);
  }

  @override
  Future<void> removeAdCallback(String placementId) async {
    try {
      await _channel.invokeMethod('removeAdCallback', {
        'placementId': placementId,
      });
    } on PlatformException catch (e) {
      SDKLogger.error('Failed to remove ad callback', e);
      rethrow;
    }
  }

  void _setCallback(String placementId, AdCallback callback) {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onAdLoading':
          callback.onAdLoading(call.arguments['placementId']);
          break;
        case 'onAdLoaded':
          callback.onAdLoaded(call.arguments['placementId']);
          break;
        case 'onAdDisplayed':
          callback.onAdDisplayed(call.arguments['placementId']);
          break;
        case 'onAdFailed':
          callback.onAdFailed(
            call.arguments['placementId'],
            call.arguments['errorCode'],
            call.arguments['errorMessage'],
          );
          break;
        case 'onAdClicked':
          callback.onAdClicked(call.arguments['placementId']);
          break;
        case 'onAdClosed':
          callback.onAdClosed(call.arguments['placementId']);
          break;
        case 'onVideoAdStarted':
          callback.onVideoAdStarted(call.arguments['placementId']);
          break;
        case 'onVideoAdCompleted':
          callback.onVideoAdCompleted(call.arguments['placementId']);
          break;
        case 'onVideoAdSkipped':
          callback.onVideoAdSkipped(call.arguments['placementId']);
          break;
      }
    });
  }

  Widget _createAdWidget(dynamic result, String placementId, AdCallback? callback) {
    // This is a placeholder - in a real implementation, you would create
    // platform-specific widgets based on the result
    return Container(
      width: 320,
      height: 240,
      color: Colors.grey[300],
      child: Center(
        child: Text('Ad View for $placementId'),
      ),
    );
  }
}
