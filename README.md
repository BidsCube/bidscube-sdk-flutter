# BidsCube Flutter SDK

A comprehensive Flutter SDK for displaying image, video, and native ads across all platforms (Android, iOS, Web, Desktop). The SDK provides a unified API for ad management with platform-specific optimizations.

## Features

- **Multi-platform Support**: Android, iOS
- **Image, Video, and Native ad support**
- **OpenRTB 2.6-style podded video response parsing** (Flutter-only mode; response-side only)
- **Multiple ad positions** (header, footer, sidebar, fullscreen, above/below the fold)
- **Dynamic position-based styling** with visual feedback
- **VAST video ad support** with IMA SDK integration
- **Banner ad management**
- **Responsive native ads** with flexible Flutter widgets
- **Position override functionality** for testing
- **Comprehensive error handling** and timeout management
- **Production-ready logging** with SDKLogger
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

This package is **released from GitHub** (tags + [Releases](https://github.com/bidscube/bidscube-sdk-flutter/releases)), not from pub.dev. Pin a version with a `git` dependency:

```yaml
dependencies:
  bidscube_sdk_flutter:
    git:
      url: https://github.com/bidscube/bidscube-sdk-flutter.git
      ref: v1.2.3 # use the tag you want
```

- **Private clone URL / SSH**: set `url` to a form your CI and developers can clone (for example `git@github.com:bidscube/bidscube-sdk-flutter.git` with deploy keys or SSH agent).
- **`ref`**: use a **tag** (recommended, e.g. `v1.2.2`) or a commit SHA for an exact snapshot.

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
    .baseURL('https://ssp-bcc-ads.com/sdk')
    .enableLogging(true)
    .enableDebugMode(true)
    .defaultAdTimeout(30000)
    .defaultAdPosition(AdPosition.header)
    .enableTestMode(true)
    .build();

// Initialize the SDK
await BidscubeSDK.initialize(config: config);
```

### OpenRTB podded video responses

The Flutter SDK supports OpenRTB 2.6-style podded video response parsing in Flutter-only mode.
This is not a full OpenRTB bid-request client.
The SDK still uses the existing legacy GET ad request flow.
Supported response shapes: root adm, bids[], seatbid[].bid[], openrtb.video/openRtb.video/root video.
Supported pod modes: structured, dynamic, hybrid.

Configure pod parsing on [SDKConfig](lib/src/core/sdk_config.dart):

```dart
final config = SDKConfig.builder()
    .openRtbPodMetadataEnabled(true)
    .videoPodDurationValidationMode(OpenRtbPodDurationValidationMode.lenient)
    .videoPodSkipPolicy(OpenRtbPodSkipPolicy.skipCurrentAndContinue)
    .videoPodContinueOnSlotError(true)
    .videoPodShowCounter(true)
    .build();
```

**Platform notes**

- **Flutter-only mode** resolves OpenRTB podded responses in Dart via `VideoAdPayloadResolver`.
- **iOS native mode** forwards the OpenRTB pod config keys to the native `bidscubeSdk` pod (requires `bidscubeSdk` **1.2.5+** with `openRtbPodMetadataEnabled`, `videoPodDurationValidationMode`, `videoPodSkipPolicy`, etc.). Ensure `v1.2.5` is available to CocoaPods (trunk or your private spec repo) before using native iOS mode with OpenRTB config.
- **Android native mode is not complete yet** because the current Flutter Android bridge still uses placeholders for native video, banner, and native ad views. OpenRTB pod parsing is available in **Flutter-only mode** only on Android until the real native bridge is implemented.

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
  void onAdFailed(String placementId, String errorCode, String errorMessage) {
    print('Ad failed: $placementId - $errorMessage (Code: $errorCode)');
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

## Custom rendering with onAdRenderOverride

If you want full control over how an ad is rendered in your app (for example to use your own native components, custom WebView handling, or a different layout), use the `onAdRenderOverride` callback on your `AdCallback` implementation.

How it works

- When you pass an `AdCallback` to `getBannerAdView`, `getVideoAdView`, or `getNativeAdView`, the SDK will check whether the callback's `onAdRenderOverride` is non-null.
- If `onAdRenderOverride` is provided, the SDK will perform the ad request and call your `onAdRenderOverride(placementId, adm, position)` handler with the server response.
  - `adm` is the ad markup or data: it may be an HTML snippet, a VAST XML (for video), or a JSON-encoded object for native ads. If the server doesn't provide a specific `adm` field the SDK will pass a JSON-encoded fallback with the full response.
- When `onAdRenderOverride` is used, the SDK returns a placeholder widget (a SizedBox) instead of mounting the SDK-built view — you are expected to render the ad yourself inside your app UI.

Recommended usage pattern

1. Implement an `AdCallback` and set the `onAdRenderOverride` handler. In the handler parse the `adm` and create a Widget to display the ad.
2. Insert that widget into your widget tree (for example by storing it in state and calling `setState`) at the desired location.
3. The SDK still calls lifecycle methods (`onAdLoading`, `onAdLoaded`, `onAdDisplayed`, `onAdFailed`) so you can track ad state as before.

Example: render HTML/creative in a WebView

```dart
class ClientAdWidget extends StatefulWidget {
  final String placementId;
  ClientAdWidget(this.placementId);
  @override
  State createState() => _ClientAdWidgetState();
}

class _ClientAdWidgetState extends State<ClientAdWidget> {
  String? _html;

  @override
  Widget build(BuildContext context) {
    if (_html == null) return SizedBox(width: 320, height: 240);
    return SizedBox(
      width: 320,
      height: 240,
      child: WebViewWidget(controller: WebViewController()..loadHtmlString(_html!)),
    );
  }

  void updateHtml(String html) => setState(() => _html = html);
}

// When you register the callback (example in a State object):
final clientAdWidgetKey = GlobalKey<_ClientAdWidgetState>();
final clientWidget = ClientAdWidget('20212');

final callback = MyAdCallback();
callback.onAdRenderOverride = (placementId, adm, position) {
  // adm may already be full HTML; if it's JSON-encoded, extract the HTML from adm
  final html = adm; // or parse adm to extract HTML fragment
  clientAdWidgetKey.currentState?.updateHtml(html);
};

// Add the clientWidget (with key) into your UI; then call:
await BidscubeSDK.getBannerAdView('20212', callback: callback);
```

Example: parse native JSON and build a Flutter widget

```dart
callback.onAdRenderOverride = (placementId, adm, position) {
  // adm may be JSON; try to decode
  try {
    final data = json.decode(adm) as Map<String, dynamic>;
    // Extract fields (title, image, cta, etc.) and create widget
    final title = data['title'] ?? '';
    final imageUrl = data['imageUrl'] ?? '';
    setState(() {
      _clientAdWidget = GestureDetector(
        onTap: () => _onAdClicked(placementId),
        child: Column(children: [Text(title), Image.network(imageUrl), /* cta */]),
      );
    });
  } catch (e) {
    // Fallback: treat adm as plain string and log
    print('Failed to parse adm: $e');
  }
};
```

Notes and tips

- The SDK will call your lifecycle methods (onAdLoading/onAdLoaded/onAdDisplayed/onAdFailed) so you can show placeholders or retry UI while the network request is in progress.
- For VAST video ADM you typically receive XML — you can either feed it to a VAST/IMA player or implement your own video player. The SDK's IMA integration is used only when the SDK renders the view itself; when you override rendering you are responsible for playing/pausing and tracking video events.
- If your `onAdRenderOverride` throws an error, the SDK will log the exception and continue; consider adding try/catch around parsing and rendering logic to avoid losing lifecycle notifications.
- When using custom rendering, make sure to call `BidscubeSDK.setAdCallback(placementId, callback)` if you need SDK-level registration for later events (optional — passing callback directly to `get*AdView` is usually sufficient).

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

## Advanced Features

### Dynamic Position-Based Styling

The SDK automatically applies different visual styles based on the ad position received from the server:

- **Above The Fold**: Blue styling with rounded corners
- **Below The Fold**: Green styling with medium corners
- **Header**: Orange styling with small corners
- **Footer**: Purple styling with small corners
- **Sidebar**: Teal styling with medium corners
- **Full Screen**: Red styling with large corners and strong shadow
- **Depend On Screen Size**: Amber styling with medium corners

### Position Override for Testing

You can override the server-determined position for testing purposes:

```dart
// Enable position override
final config = SDKConfig.builder()
    .enableTestMode(true)
    .build();

// The ad view will use the specified position instead of server response
final adView = await BidscubeSDK.getImageAdView(
  'your_placement_id',
  position: AdPosition.fullScreen, // Override position
  callback: MyAdCallback(),
);
```

### Responsive Native Ads

Native ads automatically adapt to different screen sizes using flexible Flutter widgets:

- **Small screens** (< 300px): Compact layout
- **Medium screens** (300-500px): Balanced layout
- **Large screens** (> 500px): Full layout with all elements

### Comprehensive Logging

The SDK provides detailed logging through `SDKLogger`:

```dart
// Enable detailed logging
final config = SDKConfig.builder()
    .enableLogging(true)
    .enableDebugMode(true)
    .build();

// Logs include:
// - Request URLs and parameters
// - Response status codes and content
// - Position changes from server
// - Error details and stack traces
```

## Test Placement IDs

| Placement ID | Ad Type | Description                      |
| ------------ | ------- | -------------------------------- |
| `20212`      | Banner  | Test banner ad                   |
| `20213`      | Video   | Test video ad with VAST response |
| `20214`      | Native  | Test native ad                   |

## Running the Test App

1. **Navigate to testapp directory**:

   ```bash
   cd testapp
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
    .baseURL('https://ssp-bcc-ads.com/sdk')  // API endpoint
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
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

### Version 0.1.0

- Initial release
- Multi-platform support (Android, iOS, Web, Desktop)
- Image, Video, and Native ad support
- Multiple ad positions with dynamic styling
- VAST video ad support with IMA SDK integration
- Responsive native ads with flexible layouts
- Position override functionality for testing
- Comprehensive error handling and logging
- Production-ready SDKLogger implementation
- Unified API across all platforms
- Real-time position changes with visual feedback

---

**BidsCube Flutter SDK** - Making mobile advertising simple and effective across all platforms.
