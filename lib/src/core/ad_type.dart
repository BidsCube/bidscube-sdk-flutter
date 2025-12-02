/// Ad types supported by BidsCube SDK
enum AdType {
  /// Image banner ads
  image,

  /// Video ads (VAST, VPAID)
  video,

  /// Native ads
  native,

  /// Banner ads
  banner,
}

/// Extension for AdType to get string representation
extension AdTypeExtension on AdType {
  /// Get string representation of ad type
  String get value {
    switch (this) {
      case AdType.image:
        return 'image';
      case AdType.video:
        return 'video';
      case AdType.native:
        return 'native';
      case AdType.banner:
        return 'banner';
    }
  }
}
