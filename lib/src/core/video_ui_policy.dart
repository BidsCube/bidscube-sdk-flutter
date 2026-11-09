import 'ad_position.dart';

/// Whether video ads use a fullscreen surface.
///
/// Mirrors Android `VideoUiDefaults.FullscreenPolicy`.
enum VideoFullscreenPolicy {
  /// TV / Leanback / Apple TV → fullscreen. Phone: fullscreen only for
  /// [AdPosition.fullScreen] and [AdPosition.unknown].
  auto,

  /// Always fullscreen (phone and TV).
  forceFullscreen,

  /// Always windowed, including on TV (QA compare).
  forceWindowed,
}

/// Pure display policy used by the Flutter video player.
class VideoUiPolicy {
  const VideoUiPolicy._();

  static bool shouldShowFullscreen({
    required VideoFullscreenPolicy policy,
    required bool isTelevision,
    required AdPosition position,
  }) {
    switch (policy) {
      case VideoFullscreenPolicy.forceFullscreen:
        return true;
      case VideoFullscreenPolicy.forceWindowed:
        return false;
      case VideoFullscreenPolicy.auto:
        if (isTelevision) return true;
        return position == AdPosition.fullScreen ||
            position == AdPosition.unknown;
    }
  }

  /// Rewarded video never offers Skip, regardless of VAST `skipoffset`.
  static bool skipAllowed({required bool isRewarded}) => !isRewarded;
}
