import 'logger.dart';
import 'ad_position.dart';

/// Base ad callback with default no-op methods.
/// Prefer **extending** this class (`extends AdCallback`) instead of implementing
/// it, so new optional handlers do not break your app when the SDK evolves.
abstract class AdCallback {
  /// Called when ad starts loading
  void onAdLoading(String placementId) {}

  /// Called when ad is loaded successfully
  void onAdLoaded(String placementId) {}

  /// Called when ad is displayed
  void onAdDisplayed(String placementId) {}

  /// Called when ad fails to load or display
  void onAdFailed(
    String placementId,
    String errorCode,
    String errorMessage,
  ) {}

  /// Called when ad is clicked
  void onAdClicked(String placementId) {}

  /// Called when ad is closed
  void onAdClosed(String placementId) {}

  /// Called when video ad starts playing
  void onVideoAdStarted(String placementId) {}

  /// Called when video ad completes successfully
  void onVideoAdCompleted(String placementId) {}

  /// Called when video ad is skipped / abandoned before completion
  void onVideoAdSkipped(String placementId) {}

  /// Called after a **rewarded** video is fully watched (never for interstitial).
  void onUserRewarded(String placementId) {}

  /// Host overrides rendering — leave null for default SDK widgets.
  void Function(String placementId, String adm, AdPosition position)?
      onAdRenderOverride;
}

/// Default implementation — logs lifecycle to [SDKLogger].
class DefaultAdCallback extends AdCallback {
  @override
  void onAdLoading(String placementId) {
    SDKLogger.info('Ad loading: $placementId');
  }

  @override
  void onAdLoaded(String placementId) {
    SDKLogger.info('Ad loaded: $placementId');
  }

  @override
  void onAdDisplayed(String placementId) {
    SDKLogger.info('Ad displayed: $placementId');
  }

  @override
  void onAdFailed(String placementId, String errorCode, String errorMessage) {
    SDKLogger.error(
      'Ad failed: $placementId - $errorMessage (Code: $errorCode)',
    );
  }

  @override
  void onAdClicked(String placementId) {
    SDKLogger.info('Ad clicked: $placementId');
  }

  @override
  void onAdClosed(String placementId) {
    SDKLogger.info('Ad closed: $placementId');
  }

  @override
  void onVideoAdStarted(String placementId) {
    SDKLogger.info('Video ad started: $placementId');
  }

  @override
  void onVideoAdCompleted(String placementId) {
    SDKLogger.info('Video ad completed: $placementId');
  }

  @override
  void onVideoAdSkipped(String placementId) {
    SDKLogger.info('Video ad skipped: $placementId');
  }

  @override
  void onUserRewarded(String placementId) {
    SDKLogger.info('User rewarded: $placementId');
  }
}
