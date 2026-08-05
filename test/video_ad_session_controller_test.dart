import 'package:flutter_test/flutter_test.dart';
import 'package:bidscube_sdk_flutter/src/core/video_ad_session_controller.dart';

void main() {
  group('VideoAdSessionController autoClose', () {
    test('defaults to autoClose=false post-video last frame', () {
      final session = VideoAdSessionController(
        autoClose: false,
        isRewarded: false,
        hasCompanion: false,
      );

      expect(session.autoClose, false);
      session.onLinearVideoComplete();

      expect(session.completed, isTrue);
      expect(session.closed, isFalse);
      expect(session.showEndCard, isFalse);
      expect(session.showManualCloseButton, isTrue);
      expect(session.postVideoPhase, VideoAdPostVideoPhase.lastFrame);
      expect(session.playerVisible, isTrue);
      expect(session.closedCount, 0);
    });

    test('explicit autoClose=true closes immediately without end card', () {
      final session = VideoAdSessionController(
        autoClose: true,
        isRewarded: false,
        hasCompanion: true,
      );

      session.onLinearVideoComplete();

      expect(session.closed, isTrue);
      expect(session.showEndCard, isFalse);
      expect(session.playerReleased, isTrue);
      expect(session.closedCount, 1);
    });

    test('autoClose=false with static companion shows end card and releases player', () {
      final session = VideoAdSessionController(
        autoClose: false,
        isRewarded: false,
        hasCompanion: true,
      );

      session.onLinearVideoComplete();

      expect(session.closed, isFalse);
      expect(session.showEndCard, isTrue);
      expect(session.showManualCloseButton, isFalse);
      expect(session.postVideoPhase, VideoAdPostVideoPhase.companionEndCard);
      expect(session.playerReleased, isTrue);
      expect(session.playerVisible, isFalse);
    });

    test('autoClose=false without companion keeps player for last frame', () {
      final session = VideoAdSessionController(
        autoClose: false,
        isRewarded: false,
        hasCompanion: false,
      );

      session.onLinearVideoComplete();

      expect(session.playerReleased, isFalse);
      expect(session.playerVisible, isTrue);
      expect(session.showManualCloseButton, isTrue);
    });

    test('skip does not grant reward on rewarded ads', () {
      final session = VideoAdSessionController(
        autoClose: false,
        isRewarded: true,
        hasCompanion: false,
      );

      session.onLinearVideoSkipped();

      expect(session.skipped, isTrue);
      expect(session.rewarded, isFalse);
      expect(session.rewardedCount, 0);
      expect(session.showManualCloseButton, isTrue);
    });

    test('reward only after full rewarded video completion', () {
      final session = VideoAdSessionController(
        autoClose: true,
        isRewarded: true,
        hasCompanion: false,
      );

      session.onLinearVideoComplete();

      expect(session.rewarded, isTrue);
      expect(session.rewardedCount, 1);
    });

    test('interactive post-video content is not closed after linear complete', () {
      final session = VideoAdSessionController(
        autoClose: false,
        isRewarded: false,
        hasCompanion: true,
      );

      session.onLinearVideoComplete(holdForInteractiveContent: true);

      expect(session.completed, isTrue);
      expect(session.closed, isFalse);
      expect(session.showEndCard, isFalse);
      expect(session.postVideoPhase, VideoAdPostVideoPhase.interactivePlayer);
      expect(session.playerReleased, isFalse);

      session.endInteractivePostVideoContent();

      expect(session.showEndCard, isTrue);
      expect(session.playerReleased, isTrue);
    });

    test('manual and system close fire once', () {
      final session = VideoAdSessionController(
        autoClose: false,
        isRewarded: false,
        hasCompanion: false,
      );

      session.onLinearVideoComplete();
      session.manualClose();
      session.manualClose();
      session.closeSession();

      expect(session.closedCount, 1);
    });

    test('duplicate complete/skip events do not duplicate counters', () {
      final session = VideoAdSessionController(
        autoClose: false,
        isRewarded: true,
        hasCompanion: false,
      );

      session.onLinearVideoComplete();
      session.onLinearVideoComplete();
      session.onLinearVideoSkipped();

      expect(session.completedCount, 1);
      expect(session.skippedCount, 0);
      expect(session.rewardedCount, 1);
    });

    test('failure closes session once', () {
      final session = VideoAdSessionController(
        autoClose: false,
        isRewarded: false,
        hasCompanion: false,
      );

      session.markFailed();
      session.markFailed();

      expect(session.failedCount, 1);
      expect(session.closedCount, 1);
    });
  });
}
