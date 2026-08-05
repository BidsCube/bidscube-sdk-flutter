# BidsCube Flutter SDK

A Flutter SDK for displaying banner/image, video, and native ads on mobile. The SDK provides a unified Dart API with Flutter-only rendering and an optional iOS native bridge.

## Platform Support

**Officially documented mobile targets: Android and iOS.**

- **Flutter-only mode** is the recommended production path for **Android**.
- **iOS native mode** is available through the native `bidscubeSdk ~> 1.2.5` pod.
- **Android native mode** is not production-ready yet because the Kotlin bridge still returns placeholders for native ad views.
- **Web/Desktop** are not officially documented as supported production targets in this SDK version.

In the Flutter SDK, banner/image ad rendering is exposed through `getBannerAdView()`.

## Features

- **Banner/image, video, and native ad support**
- **OpenRTB 2.6-style podded video response parsing** (response-side only; not a full OpenRTB bid-request client)
- **Multiple ad positions** (header, footer, sidebar, fullscreen, above/below the fold)
- **Dynamic position-based styling** with visual feedback
- **VAST video ad support** with IMA SDK integration
- **Interstitial and rewarded video** APIs
- **Responsive native ads** with flexible Flutter widgets
- **Custom rendering** via `onAdRenderOverride`
- **Position override functionality** for testing
- **Comprehensive error handling** and timeout management
- **Production-ready logging** with `SDKLogger`

## Requirements

- Flutter `>= 3.19.0`
- Dart `>= 3.8.1 < 4.0.0`
- **Android**: minSdk **24**
- **iOS**: **14.0+** for this Flutter plugin (`ios/bidscube_sdk_flutter.podspec`)

> The underlying native iOS SDK may support iOS 13.0, but this Flutter plugin podspec currently declares iOS 14.0.

## Installation

This package is **released from GitHub** (tags + [Releases](https://github.com/bidscube/bidscube-sdk-flutter/releases)), not from pub.dev. Pin a version with a `git` dependency:

```yaml
dependencies:
  bidscube_sdk_flutter:
    git:
      url: https://github.com/bidscube/bidscube-sdk-flutter.git
      ref: v1.2.9 # use the tag you want
```

- **Private clone URL / SSH**: set `url` to a form your CI and developers can clone (for example `git@github.com:bidscube/bidscube-sdk-flutter.git` with deploy keys or SSH agent).
- **`ref`**: use a **tag** (recommended, e.g. `v1.2.5`) or a commit SHA for an exact snapshot.

Then run:

```bash
flutter pub get
```

## Quick Start

### 1. Initialize the SDK

```dart
import 'package:bidscube_sdk_flutter/bidscube_sdk_flutter.dart';

final config = SDKConfig.builder()
    .baseURL('https://ssp-bcc-ads.com/sdk')
    .userId('your-app-user-id') // sent as `user_id` on every ad request
    .enableLogging(true)
    .enableDebugMode(true)
    .defaultAdTimeout(30000)
    .defaultAdPosition(AdPosition.header)
    .enableTestMode(true)
    .build();

// Recommended for Android production
await BidscubeSDK.initialize(
  config: config,
  useFlutterOnly: true,
);
```

### OpenRTB podded video responses

The Flutter SDK supports **OpenRTB 2.6-style podded video response parsing** (response-side only). This is **not** a full OpenRTB bid-request client. The SDK still uses the existing legacy GET ad request flow.

Supported response shapes: root `adm`, `bids[]`, `seatbid[].bid[]`, `openrtb.video` / `openRtb.video` / root `video`.

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

**Platform matrix**

| Mode | OpenRTB pod support |
|------|---------------------|
| **Flutter-only** | Implemented in Dart via `VideoAdPayloadResolver`; supported on Android/iOS Flutter-only video flow |
| **iOS native** | Config keys forwarded to native `bidscubeSdk ~> 1.2.5`; requires the native iOS SDK version with OpenRTB config APIs |
| **Android native** | Not production-ready; Kotlin bridge returns placeholder strings for native ad views — use `useFlutterOnly: true` |

`videoPodShowCounter` is forwarded to native SDKs and reserved for pod UI where supported. Flutter-only behavior may not display a dedicated pod counter yet.

### 2. Create Ad Views

Image/banner creatives are rendered through `getBannerAdView()`.

```dart
// Banner / image ad
final bannerAdView = await BidscubeSDK.getBannerAdView(
  'your_banner_placement_id',
  callback: MyAdCallback(),
);

// Interstitial video (historical alias: getVideoAdView)
final videoAdView = await BidscubeSDK.getInterstitialVideoAdView(
  'your_video_placement_id',
  callback: MyAdCallback(),
);

// Rewarded video
final rewardedAdView = await BidscubeSDK.getRewardedVideoAdView(
  'your_rewarded_placement_id',
  callback: MyAdCallback(),
);

// Native ad
final nativeAdView = await BidscubeSDK.getNativeAdView(
  'your_native_placement_id',
  callback: MyAdCallback(),
);
```

Public facade methods in `BidscubeSDK`:

- `getBannerAdView()`
- `getVideoAdView()` — historical alias for interstitial video
- `getInterstitialVideoAdView()`
- `getRewardedVideoAdView()`
- `getNativeAdView()`
- `requestAd()`

`getImageAdView()` is **not** exposed in the current Dart facade.

### 3. Implement Ad Callbacks

Prefer `extends AdCallback` instead of `implements AdCallback`, so future optional callback methods do not break the app.

```dart
class MyAdCallback extends AdCallback {
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

  @override
  void onUserRewarded(String placementId) {
    print('User rewarded: $placementId');
  }
}
```

## Custom rendering with onAdRenderOverride

If you want full control over how an ad is rendered in your app, set `onAdRenderOverride` on your `AdCallback`:

```dart
void Function(String placementId, String adm, AdPosition position)? onAdRenderOverride;
```

How it works:

- When you pass an `AdCallback` to `getBannerAdView`, `getInterstitialVideoAdView`, `getRewardedVideoAdView`, or `getNativeAdView`, the SDK checks whether `onAdRenderOverride` is non-null.
- If set, the SDK performs the ad request and calls `onAdRenderOverride(placementId, adm, position)`.
- `adm` may be HTML, raw VAST XML, root ADM, or full response JSON depending on the flow.
- For OpenRTB podded responses, do not assume `adm` contains all pod metadata. If custom rendering is used, preserve the raw JSON response where available.
- Default SDK rendering is recommended for OpenRTB podded video.
- When `onAdRenderOverride` is used, the SDK returns a placeholder `SizedBox` — you render the ad in your own widget tree.

Example: render HTML in a WebView

```dart
final callback = MyAdCallback();
callback.onAdRenderOverride = (placementId, adm, position) {
  final html = adm; // or parse adm to extract HTML
  clientAdWidgetKey.currentState?.updateHtml(html);
};

await BidscubeSDK.getBannerAdView('20212', callback: callback);
```

## Usage Examples

### Banner / Image Ads

```dart
final bannerAdView = await BidscubeSDK.getBannerAdView(
  'your_banner_placement_id',
  callback: MyAdCallback(),
);

Container(
  width: 320,
  height: 240,
  child: bannerAdView,
)
```

### Video Ads

```dart
final videoAdView = await BidscubeSDK.getInterstitialVideoAdView(
  'your_video_placement_id',
  callback: MyAdCallback(),
);

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

Container(
  width: 320,
  height: 300,
  child: nativeAdView,
)
```

## Advanced Features

### Dynamic Position-Based Styling

The SDK applies different visual styles based on the ad position from the server:

- **Above The Fold**: Blue styling with rounded corners
- **Below The Fold**: Green styling with medium corners
- **Header**: Orange styling with small corners
- **Footer**: Purple styling with small corners
- **Sidebar**: Teal styling with medium corners
- **Full Screen**: Red styling with large corners and strong shadow
- **Depend On Screen Size**: Amber styling with medium corners

### Position Override for Testing

```dart
final config = SDKConfig.builder()
    .enableTestMode(true)
    .build();

final adView = await BidscubeSDK.getBannerAdView(
  'your_placement_id',
  position: AdPosition.fullScreen,
  callback: MyAdCallback(),
);
```

## Test Placement IDs

| Placement ID | Ad Type | Description                      |
| ------------ | ------- | -------------------------------- |
| `20212`      | Banner  | Test banner ad                   |
| `20213`      | Video   | Test video ad with VAST response |
| `20214`      | Native  | Test native ad                   |

## Running Examples and QA

**Minimal package example** — use the bundled `example/` directory:

```bash
cd example
flutter pub get
flutter run -d android   # or -d ios
```

**Full manual QA** — use the separate sibling repository `bidscube-testapp-flutter` with a path dependency to `../bidscube-sdk-flutter`:

```bash
cd ../bidscube-testapp-flutter
flutter pub get
flutter run -d android   # or -d ios
```

Primary QA targets: **Android and iOS**. Web/Desktop are not official production QA targets for this SDK version unless separately validated.

## Configuration Options

```dart
final config = SDKConfig.builder()
    .baseURL('https://ssp-bcc-ads.com/sdk')
    .userId('your-app-user-id')
    .enableLogging(true)
    .enableDebugMode(true)
    .defaultAdTimeout(30000)
    .defaultAdPosition(AdPosition.header)
    .enableTestMode(true)
    .build();
```

## Troubleshooting

### Common Issues

1. **Ad not loading** — check network, placement ID, and `SDKLogger` output with `enableDebugMode(true)`.
2. **Video ads not playing** — use Flutter-only mode on Android; verify VAST format and video URL accessibility.
3. **Build errors** — ensure Flutter `>= 3.19.0`, Dart `>= 3.8.1`, Android minSdk 24, iOS 14.0+.

## Building the Package

```bash
flutter test
flutter analyze
flutter build apk --release   # Android
flutter build ios --release   # iOS
```

## Creating Clean Source Archives

Create clean archives from git, not by zipping a local working directory.

Do **not** include:

```
.git/
.dart_tool/
build/
android/.gradle/
android/local.properties
.flutter-plugins-dependencies
__MACOSX/
.DS_Store
._*
```

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for the full release history. Current version: **1.2.9**.
