/// Ad positions supported by BidsCube SDK
enum AdPosition {
  unknown,

  aboveTheFold,

  dependOnTheScreenSize,

  belowTheFold,

  header,

  footer,

  sidebar,

  fullScreen,
}

/// Extension for AdPosition to get string representation
extension AdPositionExtension on AdPosition {
  /// Get string representation of ad position
  String get value {
    switch (this) {
      case AdPosition.unknown:
        return '0 - UNKNOWN';
      case AdPosition.aboveTheFold:
        return '1 - ABOVE THE FOLD';
      case AdPosition.dependOnTheScreenSize:
        return '2 - DEPEND ON THE SCREEN SIZE';
      case AdPosition.belowTheFold:
        return '3 - BELOW THE FOLD';
      case AdPosition.header:
        return '4 - HEADER';
      case AdPosition.footer:
        return '5 - FOOTER';
      case AdPosition.sidebar:
        return '6 - SIDEBAR';
      case AdPosition.fullScreen:
        return '7 - FULLSCREEN';
    }
  }
}
