
import 'package:bidscube_sdk_flutter/bidscube_sdk_flutter.dart';

class TestAdCallback implements AdCallback {
  final Function(String) _addLog;

  TestAdCallback(this._addLog);

  @override
  void onAdLoading(String placementId) {
    _addLog('Ad loading: $placementId');
  }

  @override
  void onAdLoaded(String placementId) {
    _addLog('Ad loaded: $placementId');
  }

  @override
  void onAdDisplayed(String placementId) {
    _addLog('Ad displayed: $placementId');
  }

  @override
  void onAdFailed(String placementId, int errorCode, String errorMessage) {
    _addLog('Ad failed: $placementId - $errorMessage (Code: $errorCode)');
  }

  @override
  void onAdClicked(String placementId) {
    _addLog('Ad clicked: $placementId');
  }

  @override
  void onAdClosed(String placementId) {
    _addLog('Ad closed: $placementId');
  }

  @override
  void onVideoAdStarted(String placementId) {
    _addLog('Video ad started: $placementId');
  }

  @override
  void onVideoAdCompleted(String placementId) {
    _addLog('Video ad completed: $placementId');
  }

  @override
  void onVideoAdSkipped(String placementId) {
    _addLog('Video ad skipped: $placementId');
  }
}
