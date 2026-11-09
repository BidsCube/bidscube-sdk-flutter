import 'package:flutter_test/flutter_test.dart';
import 'package:bidscube_sdk_flutter/src/core/ad_position.dart';
import 'package:bidscube_sdk_flutter/src/core/television_detector.dart';
import 'package:bidscube_sdk_flutter/src/core/video_ui_policy.dart';

void main() {
  group('VideoUiPolicy', () {
    test('AUTO is fullscreen on television for any position', () {
      expect(
        VideoUiPolicy.shouldShowFullscreen(
          policy: VideoFullscreenPolicy.auto,
          isTelevision: true,
          position: AdPosition.header,
        ),
        isTrue,
      );
    });

    test('AUTO on phone is fullscreen only for fullScreen and unknown', () {
      expect(
        VideoUiPolicy.shouldShowFullscreen(
          policy: VideoFullscreenPolicy.auto,
          isTelevision: false,
          position: AdPosition.fullScreen,
        ),
        isTrue,
      );
      expect(
        VideoUiPolicy.shouldShowFullscreen(
          policy: VideoFullscreenPolicy.auto,
          isTelevision: false,
          position: AdPosition.unknown,
        ),
        isTrue,
      );
      expect(
        VideoUiPolicy.shouldShowFullscreen(
          policy: VideoFullscreenPolicy.auto,
          isTelevision: false,
          position: AdPosition.header,
        ),
        isFalse,
      );
    });

    test('FORCE policies ignore device and position', () {
      expect(
        VideoUiPolicy.shouldShowFullscreen(
          policy: VideoFullscreenPolicy.forceFullscreen,
          isTelevision: false,
          position: AdPosition.footer,
        ),
        isTrue,
      );
      expect(
        VideoUiPolicy.shouldShowFullscreen(
          policy: VideoFullscreenPolicy.forceWindowed,
          isTelevision: true,
          position: AdPosition.fullScreen,
        ),
        isFalse,
      );
    });

    test('rewarded never allows skip', () {
      expect(VideoUiPolicy.skipAllowed(isRewarded: true), isFalse);
      expect(VideoUiPolicy.skipAllowed(isRewarded: false), isTrue);
    });
  });

  group('TelevisionDetector.detectFromSignals', () {
    test('leanback and fire tv features', () {
      expect(
        TelevisionDetector.detectFromSignals(
          systemFeatures: ['android.software.leanback'],
        ),
        isTrue,
      );
      expect(
        TelevisionDetector.detectFromSignals(
          systemFeatures: ['amazon.hardware.fire_tv'],
        ),
        isTrue,
      );
    });

    test('Amazon AFT model heuristic', () {
      expect(
        TelevisionDetector.detectFromSignals(
          manufacturer: 'Amazon',
          model: 'AFTMM',
        ),
        isTrue,
      );
      expect(
        TelevisionDetector.detectFromSignals(
          manufacturer: 'Amazon',
          model: 'KFTRWI',
        ),
        isFalse,
      );
    });

    test('Apple TV machine and model', () {
      expect(
        TelevisionDetector.detectFromSignals(iosMachine: 'AppleTV14,1'),
        isTrue,
      );
      expect(
        TelevisionDetector.detectFromSignals(iosModel: 'Apple TV'),
        isTrue,
      );
      expect(
        TelevisionDetector.detectFromSignals(iosMachine: 'iPhone17,1'),
        isFalse,
      );
    });
  });
}
