/// Semantic video placement format passed to native / Flutter renderer.
enum VideoAdFormat {
  interstitial,
  rewarded,
}

extension VideoAdFormatExtension on VideoAdFormat {
  String get value {
    switch (this) {
      case VideoAdFormat.interstitial:
        return 'interstitial';
      case VideoAdFormat.rewarded:
        return 'rewarded';
    }
  }

  /// Parse from MethodChannel / query string (`null`/unknown → interstitial).
  static VideoAdFormat fromValue(String? value) {
    switch (value) {
      case 'rewarded':
        return VideoAdFormat.rewarded;
      case 'interstitial':
      default:
        return VideoAdFormat.interstitial;
    }
  }
}
