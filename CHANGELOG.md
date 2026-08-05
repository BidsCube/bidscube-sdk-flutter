## 1.2.9

* Fix unused import in `ImaVastVideoAdView` so `flutter analyze --no-fatal-infos` passes in CI.

## 1.2.8

* **`SDKConfig.autoClose`**: optional fullscreen video auto-close after complete/skip (default `false`); when false, show VAST Companion end card or last frame with manual close.
* **VAST Companion end cards**: Static, HTML, and IFrame resources with click/view tracking; priority HTML → IFrame → Static.
* **`VideoAdRequestLoader`**: unified video HTTP fetch + payload resolution with timeout, JSON/`adm` fallbacks, and clearer error codes (`NO_FILL`, `HTTP_4xx`, `NO_PLAYABLE_PAYLOAD`).
* **Default skip offset**: 15 seconds when VAST has no `skipoffset`; explicit VAST value still wins.
* **Fullscreen layout**: video player expands to viewport and is centered for `AdPosition.fullScreen`.
* **Lifecycle**: centralized ad session close; skip without reward; interactive post-video (mini-game) hold until session ends.

## 1.2.7

* **`SDKConfig.userId`**: optional publisher app user identifier set at SDK initialization; forwarded on every ad request as the `user_id` query parameter (banner, video, native).
* **Ad request logging**: logs `user_id` and the full ad request URL when building requests.
* **`SDKLogger`**: respects `enableLogging` / `enableDebugMode` from `SDKConfig` during initialization.
* **Flutter-only VAST skip**: improved custom skip control for inline VAST/IMA playback — pointer interception on the overlay, forced skip when IMA does not emit `skipped`, and dismiss state cleanup.

## 1.2.6

* **Banner adm normalization** via new `AdmMarkupExtractor`: unwraps JSON/`document.write` envelopes and strips embedded `{ "adm": "..." }` text nodes from live banner markup before WebView rendering.
* `WebViewImageAdView` and `AdRequestClient.onAdReceived` now use normalized adm for default rendering and `onAdRenderOverride`.
* README aligned with v1.2.5+ public API, platform requirements, and Flutter-only Android guidance.

## 1.2.5

* **OpenRTB 2.6-style podded video response parsing** (response-side only; legacy GET ad requests unchanged).
* New `SDKConfig` pod options: `openRtbPodMetadataEnabled`, `videoPodDurationValidationMode`, `videoPodSkipPolicy`, `videoPodContinueOnSlotError`, `videoPodShowCounter` (forwarded to native SDKs for pod UI where supported; Flutter-only may not show a dedicated counter yet).
* Dart OpenRTB layer: normalizer, playback plan builder, VAST pod composer, and `VideoAdPayloadResolver` integrated into `ImaVastVideoAdView` and `AdRequestClient`.
* Supported response shapes: root `adm`, `bids[]`, `seatbid[].bid[]`, `openrtb.video` / `openRtb.video` / root `video`; pod modes: structured, dynamic, hybrid.
* `AdRequestClient` now passes custom `baseURL` to all ad request methods.
* iOS native bridge forwards OpenRTB pod config to `bidscubeSdk ~> 1.2.5`.
* Android: restored core library desugaring (`minSdk` 24) for `interactive_media_ads`; native Android bridge remains placeholder (use Flutter-only mode for OpenRTB on Android).
* CI/archive: ignore generated Flutter plugin registrant files and `.flutter-plugins-dependencies`.

## 1.2.4

* Patch release; CI fix for generated Flutter plugin registrant files.

## 1.2.3

* Flutter-only VAST: parse Companion preview, skip offset, and click-through from VAST; show designed end card when preview is present.
* When VAST has no Companion preview, interstitial closes after complete/skip (no fallback end card).
* Custom skip control (top-right), `onDismiss` callback, and `vastXmlOverride` for QA fixtures.
* Added `pointer_interceptor` dependency for overlay controls above IMA platform views.

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
