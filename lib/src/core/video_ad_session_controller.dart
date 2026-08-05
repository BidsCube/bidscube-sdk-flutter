/// Post-linear video UI phase for fullscreen ads.
enum VideoAdPostVideoPhase {
  none,
  /// IMA/player still showing interactive or mini-game content.
  interactivePlayer,
  /// Companion end card visible; linear player may be released.
  companionEndCard,
  /// Last frame frozen; manual close only.
  lastFrame,
}

/// Pure lifecycle controller for fullscreen video session semantics.
///
/// Separates linear video completion from ad session close and centralizes
/// [autoClose] behavior for unit testing without IMA/platform views.
class VideoAdSessionController {
  VideoAdSessionController({
    required this.autoClose,
    required this.isRewarded,
    required this.hasCompanion,
  });

  final bool autoClose;
  final bool isRewarded;
  final bool hasCompanion;

  bool loaded = false;
  bool displayed = false;
  bool started = false;
  bool completed = false;
  bool skipped = false;
  bool rewarded = false;
  bool closed = false;
  bool failed = false;
  bool playerReleased = false;
  bool dismissed = false;
  bool showEndCard = false;
  bool showManualCloseButton = false;
  VideoAdPostVideoPhase postVideoPhase = VideoAdPostVideoPhase.none;

  int loadedCount = 0;
  int displayedCount = 0;
  int startedCount = 0;
  int completedCount = 0;
  int skippedCount = 0;
  int rewardedCount = 0;
  int closedCount = 0;
  int failedCount = 0;

  /// Player still showing post-linear interactive content (mini-game, etc.).
  bool holdPostVideoForInteractiveContent = false;

  bool get playerVisible => !playerReleased && !dismissed;

  void markLoaded() {
    if (loaded) return;
    loaded = true;
    loadedCount++;
  }

  void markDisplayed() {
    if (displayed) return;
    displayed = true;
    displayedCount++;
  }

  void markStarted() {
    if (started) return;
    started = true;
    startedCount++;
  }

  void markFailed() {
    if (failed || closed) return;
    failed = true;
    failedCount++;
    closeSession(fromFailure: true);
  }

  void onLinearVideoComplete({bool holdForInteractiveContent = false}) {
    if (completed || skipped) return;
    completed = true;
    completedCount++;
    if (isRewarded) {
      markRewarded();
    }
    if (holdForInteractiveContent) {
      beginInteractivePostVideoContent();
      return;
    }
    _enterPostVideoIfReady(wasSkip: false);
  }

  void onLinearVideoSkipped() {
    if (skipped || completed) return;
    skipped = true;
    skippedCount++;
    _enterPostVideoIfReady(wasSkip: true);
  }

  void markRewarded() {
    if (!isRewarded || rewarded || skipped || !completed) return;
    rewarded = true;
    rewardedCount++;
  }

  /// Call when IMA/player begins interactive post-linear content.
  void beginInteractivePostVideoContent() {
    holdPostVideoForInteractiveContent = true;
    postVideoPhase = VideoAdPostVideoPhase.interactivePlayer;
    showEndCard = false;
    showManualCloseButton = false;
  }

  /// Call when interactive post-linear content finishes.
  void endInteractivePostVideoContent() {
    if (!holdPostVideoForInteractiveContent) return;
    holdPostVideoForInteractiveContent = false;
    if (completed || skipped) {
      _enterPostVideoIfReady(wasSkip: skipped);
    }
  }

  void _enterPostVideoIfReady({required bool wasSkip}) {
    if (closed || failed) return;
    if (holdPostVideoForInteractiveContent) {
      postVideoPhase = VideoAdPostVideoPhase.interactivePlayer;
      return;
    }

    if (autoClose) {
      closeSession();
      return;
    }

    if (hasCompanion) {
      showEndCard = true;
      showManualCloseButton = false;
      postVideoPhase = VideoAdPostVideoPhase.companionEndCard;
      releasePlayer();
      return;
    }

    showEndCard = false;
    showManualCloseButton = true;
    postVideoPhase = VideoAdPostVideoPhase.lastFrame;
  }

  void releasePlayer() {
    if (playerReleased) return;
    playerReleased = true;
  }

  /// Centralized close — idempotent.
  void closeSession({bool fromFailure = false}) {
    if (closed) return;
    closed = true;
    closedCount++;
    releasePlayer();
    showEndCard = false;
    showManualCloseButton = false;
    postVideoPhase = VideoAdPostVideoPhase.none;
    dismissed = true;
  }

  void manualClose() {
    closeSession();
  }
}
