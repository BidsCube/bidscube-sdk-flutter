## 1.2.2

* Separate **Interstitial** vs **Rewarded** video: `BidscubeSDK.getInterstitialVideoAdView()`, `BidscubeSDK.getRewardedVideoAdView()`, `VideoAdFormat` enum; legacy `getVideoAdView()` remains an alias for interstitial.
* New callback `AdCallback.onUserRewarded`; default no-op on other lifecycle methods where appropriate.
* `MethodChannelBidscube`: single `MethodChannel` handler plus per-placement callback map; invokes `getInterstitialVideoAdView` / `getRewardedVideoAdView` with `videoAdFormat` in arguments.
* **iOS**: `FlutterAdDelegate` forwards native `AdCallback` events to Dart via `invokeMethod`; supports rewarded & interstitial video entry points aligned with native `BidscubeSDK`.
* **Android**: method-channel cases for interstitial/rewarded video and documented Dart callback names for future bridge.
* Flutter-only **IMA** path (`ImaVastVideoAdView`): completion/reward/skipped semantics (no duplicate complete; reward only on natural complete for rewarded).
* `requestVideoAd` tolerates JSON with `adm` or raw XML; fixed `onAdRenderOverride` argument order (`placementId`, `adm`, `position`).


## 1.2.1

* Version updated for pub.dev compliance
* Fixed bugs

## 1.2.0

* Fix for Android build
* Added onAdRenderOverride callback to notify when an ad is rendered with position override
* Improved error handling and logging for ad loading and rendering
* Updated dependencies to latest versions
* Minor documentation updates and code cleanup

## 1.1.0

* Major API cleanup and doc updates for publishing to pub.dev
* Fixed missing type imports (AdPosition, etc.) for platform builds
* Updated pubspec fields for pub.dev compliance and metadata
* Optimized builder pattern for SDKConfig (default URLs, etc.)
* Expanded README with usage, configuration, testApp details
* Removed example/, created testApp/ for better cross-platform demos
* Miscellaneous bugfixes, compliance improvements, and code cleanup

## 0.1.1

* Dependency updates to latest versions (Flutter, Dart, and all plugins)
* Improved documentation coverage for public API
* Added a complete example in example/main.dart
* Fixed static analysis and lint warnings
* Added library directives to fix dangling doc comments
* Fixed unused variable and whitespace widget issues
* Improved consent management callback handling in testapp
* Various bugfixes and code cleanup for pub.dev compliance

## 0.1.0

* Initial release of BidsCube Flutter SDK
* Multi-platform support (Android, iOS, Web, Desktop)
* Image, Video, and Native ad support
* Multiple ad positions with dynamic styling
* VAST video ad support with IMA SDK integration
* Responsive native ads with flexible layouts
* Position override functionality for testing
* Comprehensive error handling and logging
* Production-ready SDKLogger implementation
* Unified API across all platforms
* Real-time position changes with visual feedback

## 0.0.1

* TODO: Describe initial release.
