import 'package:flutter_test/flutter_test.dart';
import 'package:bidscube_sdk_flutter/bidscube_sdk_flutter.dart';

void main() {
  group('BidsCube SDK Tests', () {
    late SDKConfig config;

    setUp(() {
      config = SDKConfig.builder()
          .baseURL('https://api.bidscube.com')
          .enableLogging(true)
          .enableDebugMode(true)
          .defaultAdTimeout(30000)
          .defaultAdPosition(AdPosition.header)
          .enableTestMode(true)
          .build();
    });

    test('SDKConfig should be created correctly', () {
      expect(config.baseURL, 'https://api.bidscube.com');
      expect(config.enableLogging, true);
      expect(config.enableDebugMode, true);
      expect(config.defaultAdTimeout, 30000);
      expect(config.defaultAdPosition, AdPosition.header);
      expect(config.enableTestMode, true);
    });

    test('SDKConfig should convert to map correctly', () {
      final map = config.toMap();
      expect(map['baseURL'], 'https://api.bidscube.com');
      expect(map['enableLogging'], true);
      expect(map['enableDebugMode'], true);
      expect(map['defaultAdTimeout'], 30000);
      expect(map['defaultAdPosition'], 'header');
      expect(map['enableTestMode'], true);
    });

    test('SDKConfig should be created from map correctly', () {
      final map = {
        'baseURL': 'https://test.api.com',
        'enableLogging': false,
        'enableDebugMode': true,
        'defaultAdTimeout': 15000,
        'defaultAdPosition': 'footer',
        'enableTestMode': false,
      };
      
      final configFromMap = SDKConfig.fromMap(map);
      expect(configFromMap.baseURL, 'https://test.api.com');
      expect(configFromMap.enableLogging, false);
      expect(configFromMap.enableDebugMode, true);
      expect(configFromMap.defaultAdTimeout, 15000);
      expect(configFromMap.defaultAdPosition, AdPosition.footer);
      expect(configFromMap.enableTestMode, false);
    });

    test('AdType should have correct string values', () {
      expect(AdType.image.value, 'image');
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
      expect(() => callback.onAdFailed(placementId, 404, 'Not found'), returnsNormally);
      expect(() => callback.onAdClicked(placementId), returnsNormally);
      expect(() => callback.onAdClosed(placementId), returnsNormally);
      expect(() => callback.onVideoAdStarted(placementId), returnsNormally);
      expect(() => callback.onVideoAdCompleted(placementId), returnsNormally);
      expect(() => callback.onVideoAdSkipped(placementId), returnsNormally);
    });

    test('SDK should not be initialized by default', () {
      expect(BidscubeSDK.isInitialized, false);
      expect(BidscubeSDK.config, null);
    });
  });
}
