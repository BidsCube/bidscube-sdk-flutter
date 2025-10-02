# BidsCube Flutter SDK

A comprehensive Flutter SDK for displaying image, video, and native ads across all platforms (Android, iOS, Web, Desktop). The SDK provides a unified API for ad management with platform-specific optimizations.

## Features

- **Multi-platform Support**: Android, iOS, Web, macOS, Linux, Windows
- **Image, Video, and Native ad support**
- **Multiple ad positions** (header, footer, sidebar, fullscreen)
- **VAST video ad support** with platform-specific implementations
- **Banner ad management**
- **Error handling and timeout management**
- **Production-ready** with comprehensive logging
- **Unified API** across all platforms

## Requirements

- Flutter 3.8.1+
- Dart 3.0+
- Platform-specific requirements:
  - **Android**: API level 21+ (Android 5.0+)
  - **iOS**: iOS 13.0+
  - **Web**: Modern browsers with JavaScript support
  - **Desktop**: Platform-specific development tools

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  bidscube_sdk_flutter: ^0.1.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

### 1. Initialize the SDK

```dart
import 'package:bidscube_sdk_flutter/bidscube_sdk_flutter.dart';

// Configure the SDK
final config = SDKConfig.builder()
    .baseURL('https://api.bidscube.com')
    .enableLogging(true)
    .enableDebugMode(true)
    .defaultAdTimeout(30000)
    .defaultAdPosition(AdPosition.header)
    .enableTestMode(true)
    .build();

// Initialize the SDK
await BidscubeSDK.initialize(config: config);
```

### 2. Create Ad Views

```dart
// Image Ad
final imageAdView = await BidscubeSDK.getImageAdView(
  'your_image_placement_id',
  callback: MyAdCallback(),
);

// Video Ad
final videoAdView = await BidscubeSDK.getVideoAdView(
  'your_video_placement_id',
  callback: MyAdCallback(),
);

// Native Ad
final nativeAdView = await BidscubeSDK.getNativeAdView(
  'your_native_placement_id',
  callback: MyAdCallback(),
);

// Banner Ad
final bannerAdView = await BidscubeSDK.getBannerAdView(
  'your_banner_placement_id',
  callback: MyAdCallback(),
);
```

### 3. Implement Ad Callbacks

```dart
class MyAdCallback implements AdCallback {
  @override
  void onAdLoading(String placementId) {
    print('Ad loading: $placementId');
  }

  @override
  void onAdLoaded(String placementId) {
    print('Ad loaded: $placementId');
  }

  @override
  void onAdDisplayed(String placementId) {
    print('Ad displayed: $placementId');
  }

  @override
  void onAdFailed(String placementId, int errorCode, String errorMessage) {
    print('Ad failed: $placementId - $errorMessage');
  }

  @override
  void onAdClicked(String placementId) {
    print('Ad clicked: $placementId');
  }

  @override
  void onAdClosed(String placementId) {
    print('Ad closed: $placementId');
  }

  @override
  void onVideoAdStarted(String placementId) {
    print('Video ad started: $placementId');
  }

  @override
  void onVideoAdCompleted(String placementId) {
    print('Video ad completed: $placementId');
  }

  @override
  void onVideoAdSkipped(String placementId) {
    print('Video ad skipped: $placementId');
  }
}
```

## Usage Examples

### Image Ads

```dart
final imageAdView = await BidscubeSDK.getImageAdView(
  'your_image_placement_id',
  callback: MyAdCallback(),
);

// Add to your widget tree
Container(
  width: 320,
  height: 240,
  child: imageAdView,
)
```

### Video Ads

```dart
final videoAdView = await BidscubeSDK.getVideoAdView(
  'your_video_placement_id',
  callback: MyAdCallback(),
);

// Add to your widget tree
Container(
  width: 320,
  height: 240,
  child: videoAdView,
)
```

### Native Ads

```dart
final nativeAdView = await BidscubeSDK.getNativeAdView(
  'your_native_placement_id',
  callback: MyAdCallback(),
);

// Add to your widget tree
Container(
  width: 320,
  height: 300,
  child: nativeAdView,
)
```

## Test Placement IDs

| Placement ID  | Ad Type | Description                      |
| ------------- | ------- | -------------------------------- |
| `19483`       | Video   | Test video ad with VAST response |
| `test_image`  | Image   | Test image ad                    |
| `test_native` | Native  | Test native ad                   |
| `test_banner` | Banner  | Test banner ad                   |

## Running the Test App

1. **Navigate to testApp directory**:

   ```bash
   cd testApp
   ```

2. **Get dependencies**:

   ```bash
   flutter pub get
   ```

3. **Run on your preferred platform**:

   ```bash
   # Android
   flutter run -d android

   # iOS
   flutter run -d ios

   # Web
   flutter run -d web

   # macOS
   flutter run -d macos

   # Linux
   flutter run -d linux

   # Windows
   flutter run -d windows
   ```

## Configuration Options

### SDK Configuration

```dart
final config = SDKConfig.builder()
    .baseURL('https://api.bidscube.com')     // API endpoint
    .enableLogging(true)                     // Enable console logging
    .enableDebugMode(true)                   // Enable debug mode
    .defaultAdTimeout(30000)                 // Timeout in milliseconds
    .defaultAdPosition(AdPosition.header)    // Default ad position
    .enableTestMode(true)                    // Enable test mode
    .build();
```

## Troubleshooting

### Common Issues

1. **Ad not loading**:

   - Check network connectivity
   - Verify placement ID is correct
   - Check console logs for error messages

2. **Video ads not playing**:

   - Ensure platform-specific video support
   - Check VAST response format
   - Verify video URL is accessible

3. **Build errors**:
   - Ensure Flutter 3.8.1+ is installed
   - Check platform-specific requirements
   - Verify all dependencies are properly configured

### Debug Mode

Enable debug mode for detailed logging:

```dart
final config = SDKConfig.builder()
    .enableDebugMode(true)
    .build();
```

## Building the Package

To build the package for production:

```bash
# Run tests
flutter test

# Analyze code
flutter analyze

# Build for all platforms
flutter build apk --release
flutter build ios --release
flutter build web --release
flutter build macos --release
flutter build linux --release
flutter build windows --release
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

### Version 0.1.0

- Initial release
- Multi-platform support (Android, iOS, Web, Desktop)
- Image, Video, and Native ad support
- Multiple ad positions
- Comprehensive error handling
- Production-ready logging
- Unified API across all platforms

---

**BidsCube Flutter SDK** - Making mobile advertising simple and effective across all platforms.
