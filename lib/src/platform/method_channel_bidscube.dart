import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../core/sdk_config.dart';
import '../core/callbacks.dart';
import '../core/ad_type.dart';
import '../core/ad_position.dart';
import '../core/logger.dart';
import '../core/video_ad_format.dart';
import 'bidscube_platform.dart';

/// Method channel implementation for BidsCube SDK.
class MethodChannelBidscube extends BidscubePlatform {
  static const MethodChannel _channel = MethodChannel('bidscube_sdk');

  final Map<String, AdCallback> _callbacks = {};
  bool _handlerInitialized = false;

  void _ensureMethodCallHandler() {
    if (_handlerInitialized) return;
    _handlerInitialized = true;
    _channel.setMethodCallHandler(_onMethodCall);
  }

  Future<void> _onMethodCall(MethodCall call) async {
    final placementId = _placementId(call.arguments);

    switch (call.method) {
      case 'onAdLoading':
        _invoke(placementId, (c, id) => c.onAdLoading(id));
        break;
      case 'onAdLoaded':
        _invoke(placementId, (c, id) => c.onAdLoaded(id));
        break;
      case 'onAdDisplayed':
        _invoke(placementId, (c, id) => c.onAdDisplayed(id));
        break;
      case 'onAdClicked':
        _invoke(placementId, (c, id) => c.onAdClicked(id));
        break;
      case 'onAdClosed':
        _invoke(placementId, (c, id) => c.onAdClosed(id));
        break;
      case 'onVideoAdStarted':
        _invoke(placementId, (c, id) => c.onVideoAdStarted(id));
        break;
      case 'onVideoAdCompleted':
        _invoke(placementId, (c, id) => c.onVideoAdCompleted(id));
        break;
      case 'onVideoAdSkipped':
        _invoke(placementId, (c, id) => c.onVideoAdSkipped(id));
        break;
      case 'onUserRewarded':
        _invoke(placementId, (c, id) => c.onUserRewarded(id));
        break;
      case 'onAdFailed':
        final id = placementId;
        if (id == null || id.isEmpty) return;
        final callback = _callbacks[id];
        if (callback == null) return;
        final args = _argumentMap(call.arguments);
        callback.onAdFailed(
          id,
          '${args?['errorCode']}',
          '${args?['errorMessage'] ?? ''}',
        );
        break;
      default:
        SDKLogger.warning('Unknown method-channel event: ${call.method}');
    }
  }

  void _invoke(
    String? placementId,
    void Function(AdCallback c, String id) invoke,
  ) {
    final id = placementId;
    if (id == null || id.isEmpty) return;
    final callback = _callbacks[id];
    if (callback == null) return;
    invoke(callback, id);
  }

  String? _placementId(dynamic raw) =>
      _argumentMap(raw)?['placementId'] as String?;

  Map<String, dynamic>? _argumentMap(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  void _registerCallback(String placementId, AdCallback? callback) {
    if (placementId.isEmpty || callback == null) return;
    _callbacks[placementId] = callback;
    _ensureMethodCallHandler();
  }

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
  Future<Widget> getBannerAdView(
    String placementId,
    AdCallback? callback,
    AdPosition position, [
    double? borderRadius,
  ]) async {
    try {
      SDKLogger.info(
        'Requesting native banner ad view for placement: $placementId',
      );

      final result = await _channel.invokeMethod('getBannerAdView', {
        'placementId': placementId,
        'position': position.value,
      });

      SDKLogger.info('Received result from native: $result');

      _registerCallback(placementId, callback);

      final widget = _createAdWidget(result, placementId);
      SDKLogger.info('Created ad widget: ${widget.runtimeType}');

      return widget;
    } on PlatformException catch (e) {
      SDKLogger.error('Failed to get banner ad view', e);
      rethrow;
    }
  }

  @override
  Future<Widget> getInterstitialVideoAdView(
    String placementId,
    AdCallback? callback,
    AdPosition position, [
    double? borderRadius,
    String? vastXmlOverride,
    VoidCallback? onDismiss,
  ]) async {
    try {
      final result = await _channel.invokeMethod('getInterstitialVideoAdView', {
        'placementId': placementId,
        'position': position.value,
        'videoAdFormat': VideoAdFormat.interstitial.value,
      });

      _registerCallback(placementId, callback);

      return _createAdWidget(result, placementId);
    } on PlatformException catch (e) {
      SDKLogger.error('Failed to get interstitial video ad view', e);
      rethrow;
    }
  }

  @override
  Future<Widget> getRewardedVideoAdView(
    String placementId,
    AdCallback? callback,
    AdPosition position, [
    double? borderRadius,
    String? vastXmlOverride,
    VoidCallback? onDismiss,
  ]) async {
    try {
      final result = await _channel.invokeMethod('getRewardedVideoAdView', {
        'placementId': placementId,
        'position': position.value,
        'videoAdFormat': VideoAdFormat.rewarded.value,
      });

      _registerCallback(placementId, callback);

      return _createAdWidget(result, placementId);
    } on PlatformException catch (e) {
      SDKLogger.error('Failed to get rewarded video ad view', e);
      rethrow;
    }
  }

  @override
  Future<Widget> getNativeAdView(
    String placementId,
    AdCallback? callback,
    AdPosition position, [
    double? borderRadius,
  ]) async {
    try {
      final result = await _channel.invokeMethod('getNativeAdView', {
        'placementId': placementId,
        'position': position.value,
      });

      _registerCallback(placementId, callback);

      return _createAdWidget(result, placementId);
    } on PlatformException catch (e) {
      SDKLogger.error('Failed to get native ad view', e);
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

      _registerCallback(placementId, callback);
    } on PlatformException catch (e) {
      SDKLogger.error('Failed to request ad', e);
      rethrow;
    }
  }

  @override
  Future<void> setAdCallback(String placementId, AdCallback callback) async {
    _callbacks[placementId] = callback;
    _ensureMethodCallHandler();
  }

  @override
  Future<void> removeAdCallback(String placementId) async {
    _callbacks.remove(placementId);
    try {
      await _channel.invokeMethod('removeAdCallback', {
        'placementId': placementId,
      });
    } on PlatformException catch (e) {
      SDKLogger.error('Failed to remove ad callback', e);
      rethrow;
    }
  }

  @override
  bool isConsentRequired() => false;

  @override
  bool hasAdsConsent() => true;

  @override
  bool hasAnalyticsConsent() => true;

  @override
  Future<void> requestConsentInfoUpdate({AdCallback? callback}) async {
    try {
      await _channel.invokeMethod('requestConsentInfoUpdate');

      if (callback != null) {
        callback.onAdLoading('consent_info_update');
        callback.onAdLoaded('consent_info_update');
      }
    } on PlatformException catch (e) {
      SDKLogger.error('Failed to request consent info update', e);
      rethrow;
    }
  }

  @override
  Future<void> showConsentForm({AdCallback? callback}) async {
    try {
      await _channel.invokeMethod('showConsentForm');

      if (callback != null) {
        callback.onAdLoading('consent_form');
        callback.onAdLoaded('consent_form');
        callback.onAdDisplayed('consent_form');
      }
    } on PlatformException catch (e) {
      SDKLogger.error('Failed to show consent form', e);
      rethrow;
    }
  }

  @override
  String getConsentStatusSummary() =>
      "required=false, ads=true, analytics=true";

  @override
  void enableConsentDebugMode(String testDeviceId) {
    SDKLogger.info('Consent debug mode enabled for device: $testDeviceId');
  }

  @override
  void resetConsent() {
    SDKLogger.info('Consent information reset');
  }

  @override
  void cleanup() {
    _callbacks.clear();
    _handlerInitialized = false;
    try {
      _channel.setMethodCallHandler(null);
    } catch (_) {
      // Older embedders behave best-effort here.
    }
    SDKLogger.info('SDK cleanup completed');
  }

  @override
  Future<List<String>> getSKAdNetworkIds() async {
    try {
      final result = await _channel.invokeMethod('getSKAdNetworkIds');
      if (result is List) {
        return result.cast<String>();
      }
      return [];
    } on PlatformException catch (e) {
      SDKLogger.error('Failed to get SKAdNetwork IDs', e);
      return [];
    }
  }

  Widget _createAdWidget(
    dynamic result,
    String placementId,
  ) {
    if (result is Map && result.containsKey('viewId')) {
      final viewId = result['viewId'] as String;

      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
          return SizedBox(
            width: 320,
            height: 240,
            child: UiKitView(
              viewType: viewId,
              creationParams: {'placementId': placementId},
              creationParamsCodec: const StandardMessageCodec(),
            ),
          );
        case TargetPlatform.android:
          return SizedBox(
            width: 320,
            height: 240,
            child: AndroidView(
              viewType: viewId,
              creationParams: {'placementId': placementId},
              creationParamsCodec: const StandardMessageCodec(),
            ),
          );
        default:
          return SizedBox(
            width: 320,
            height: 240,
            child: UiKitView(
              viewType: viewId,
              creationParams: {'placementId': placementId},
              creationParamsCodec: const StandardMessageCodec(),
            ),
          );
      }
    }

    return SizedBox(
      width: 320,
      height: 240,
      child: Container(
        color: Colors.grey[300],
        child: Center(child: Text('Ad View for $placementId')),
      ),
    );
  }
}
