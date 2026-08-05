/// BidsCube Flutter SDK
///
/// A Flutter SDK for displaying banner/image, video, and native ads on mobile.
///
/// Officially documented mobile targets: Android and iOS.
/// Flutter-only mode is the recommended production path for Android.
/// Web/Desktop are not official production targets in v1.2.8.
///
/// Banner/image creatives are exposed through [BidscubeSDK.getBannerAdView].
library;

// Core SDK
export 'src/bidscube_sdk.dart';
export 'src/core/ad_position.dart';
export 'src/core/ad_type.dart';
export 'src/core/sdk_config.dart';
export 'src/core/callbacks.dart';
export 'src/core/logger.dart';
export 'src/core/position_style.dart';
export 'src/core/video_ad_format.dart';

// Ad Views
export 'src/views/webview_image_ad_view.dart';
export 'src/views/banner_ad_view.dart';
export 'src/views/ima_vast_video_ad_view.dart';
export 'src/views/video_end_card_view.dart';
export 'src/views/flutter_native_ad_view.dart';

// Platform Channels
export 'src/platform/bidscube_platform.dart';
export 'src/platform/method_channel_bidscube.dart';
export 'src/platform/flutter_only_bidscube.dart';

// Core utilities
export 'src/core/constants.dart';
export 'src/core/vast_parser.dart';
export 'src/core/ad_request_client.dart';
export 'src/core/url_builder.dart';
