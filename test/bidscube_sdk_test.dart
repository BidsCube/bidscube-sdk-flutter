import 'package:flutter_test/flutter_test.dart';
import 'package:bidscube_sdk_flutter/bidscube_sdk_flutter.dart';

void main() {
  group('BidsCube SDK Tests', () {
    late SDKConfig config;

    setUp(() {
      config = SDKConfig.builder()
          .enableLogging(true)
          .enableDebugMode(true)
          .defaultAdTimeout(30000)
          .defaultAdPosition(AdPosition.header)
          .enableTestMode(true)
          .userId('publisher-user-42')
          .build();
    });

    test('SDKConfig should be created correctly', () {
      expect(config.enableLogging, true);
      expect(config.enableDebugMode, true);
      expect(config.defaultAdTimeout, 30000);
      expect(config.defaultAdPosition, AdPosition.header);
      expect(config.enableTestMode, true);
      expect(config.userId, 'publisher-user-42');
      expect(config.autoClose, false);
    });

    test('SDKConfig autoClose defaults to false and can be set explicitly', () {
      expect(SDKConfig(baseURL: 'https://example.com').autoClose, false);
      expect(
        SDKConfig.builder().autoClose(true).build().autoClose,
        isTrue,
      );
    });

    test('SDKConfig should convert to map correctly', () {
      final map = config.toMap();
      expect(map['enableLogging'], true);
      expect(map['enableDebugMode'], true);
      expect(map['defaultAdTimeout'], 30000);
      expect(map['defaultAdPosition'], 'header');
      expect(map['enableTestMode'], true);
      expect(map['userId'], 'publisher-user-42');
      expect(map['autoClose'], false);
    });

    test('SDKConfig should be created from map correctly', () {
      final map = {
        'baseURL': 'https://ssp-bcc-ads.com/sdk',
        'enableLogging': false,
        'enableDebugMode': true,
        'defaultAdTimeout': 30000,
        'defaultAdPosition': 'footer',
        'enableTestMode': false,
        'userId': 'user-from-map',
      };

      final configFromMap = SDKConfig.fromMap(map);
      expect(configFromMap.baseURL, 'https://ssp-bcc-ads.com/sdk');
      expect(configFromMap.enableLogging, false);
      expect(configFromMap.enableDebugMode, true);
      expect(configFromMap.defaultAdTimeout, 30000);
      expect(configFromMap.defaultAdPosition, AdPosition.footer);
      expect(configFromMap.enableTestMode, false);
      expect(configFromMap.userId, 'user-from-map');
      expect(configFromMap.autoClose, false);
    });

    test('AdType should have correct string values', () {
      expect(AdType.video.value, 'video');
      expect(AdType.native.value, 'native');
      expect(AdType.banner.value, 'banner');
    });

    test('AdPosition should have correct string values', () {
      expect(AdPosition.header.value, 'header');
      expect(AdPosition.footer.value, 'footer');
      expect(AdPosition.sidebar.value, 'sidebar');
      expect(AdPosition.fullScreen.value, 'fullscreen');
      expect(AdPosition.aboveTheFold.value, 'above_the_fold');
      expect(AdPosition.belowTheFold.value, 'below_the_fold');
      expect(AdPosition.unknown.value, 'unknown');
    });

    test('DefaultAdCallback should handle all callbacks', () {
      final callback = DefaultAdCallback();
      final placementId = 'test_placement';

      // These should not throw exceptions
      expect(() => callback.onAdLoading(placementId), returnsNormally);
      expect(() => callback.onAdLoaded(placementId), returnsNormally);
      expect(() => callback.onAdDisplayed(placementId), returnsNormally);
      expect(
        () => callback.onAdFailed(placementId, "404", 'Not found'),
        returnsNormally,
      );
      expect(() => callback.onAdClicked(placementId), returnsNormally);
      expect(() => callback.onAdClosed(placementId), returnsNormally);
      expect(() => callback.onVideoAdStarted(placementId), returnsNormally);
      expect(() => callback.onVideoAdCompleted(placementId), returnsNormally);
      expect(() => callback.onVideoAdSkipped(placementId), returnsNormally);
      expect(() => callback.onUserRewarded(placementId), returnsNormally);
    });

    test('VideoAdFormat string serialization', () {
      expect(VideoAdFormat.interstitial.value, 'interstitial');
      expect(VideoAdFormat.rewarded.value, 'rewarded');
      expect(
        VideoAdFormatExtension.fromValue(null),
        VideoAdFormat.interstitial,
      );
      expect(VideoAdFormatExtension.fromValue(''), VideoAdFormat.interstitial);
      expect(
        VideoAdFormatExtension.fromValue('rewarded'),
        VideoAdFormat.rewarded,
      );
    });

    test('BidscubeSDK exposes legacy getVideoAdView API', () {
      expect(BidscubeSDK.getVideoAdView, isA<Function>());
      expect(BidscubeSDK.getInterstitialVideoAdView, isA<Function>());
      expect(BidscubeSDK.getRewardedVideoAdView, isA<Function>());
    });

    test('onAdRenderOverride receives placement before adm payload', () {
      late String capturedPid;
      late String capturedAdm;

      final callback = DefaultAdCallback();
      callback.onAdRenderOverride = (placementId, adm, position) {
        capturedPid = placementId;
        capturedAdm = adm;
      };

      final client = AdRequestClient(baseUrl: 'https://example.invalid');
      client.onAdReceived(
        {'adm': '<wrapper><VAST /></wrapper>', 'position': 3},
        callback,
        'placement-a',
      );

      expect(capturedPid, 'placement-a');
      expect(capturedAdm, '<wrapper><VAST /></wrapper>');
    });

    test('SDK should not be initialized by default', () {
      expect(BidscubeSDK.isInitialized, false);
      expect(BidscubeSDK.config, null);
    });
  });
}
