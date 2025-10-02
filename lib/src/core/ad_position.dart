/// Ad positions supported by BidsCube SDK
enum AdPosition {
  /// Top of screen
  header,
  
  /// Bottom of screen
  footer,
  
  /// Side panel
  sidebar,
  
  /// Full screen overlay
  fullScreen,
  
  /// Above content fold
  aboveTheFold,
  
  /// Below content fold
  belowTheFold,
  
  /// Default position
  unknown,
}

/// Extension for AdPosition to get string representation
extension AdPositionExtension on AdPosition {
  /// Get string representation of ad position
  String get value {
    switch (this) {
      case AdPosition.header:
        return 'header';
      case AdPosition.footer:
        return 'footer';
      case AdPosition.sidebar:
        return 'sidebar';
      case AdPosition.fullScreen:
        return 'fullscreen';
      case AdPosition.aboveTheFold:
        return 'above_the_fold';
      case AdPosition.belowTheFold:
        return 'below_the_fold';
      case AdPosition.unknown:
        return 'unknown';
    }
  }
}
