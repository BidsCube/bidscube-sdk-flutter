import 'ad_position.dart';

/// Lenient vs strict validation for OpenRTB pod slot durations.
enum OpenRtbPodDurationValidationMode { lenient, strict }

/// Policy when a pod slot fails during playback.
enum OpenRtbPodSkipPolicy { skipCurrentAndContinue, failEntirePod }

extension OpenRtbPodDurationValidationModeExtension
    on OpenRtbPodDurationValidationMode {
  String toStableString() {
    switch (this) {
      case OpenRtbPodDurationValidationMode.lenient:
        return 'lenient';
      case OpenRtbPodDurationValidationMode.strict:
        return 'strict';
    }
  }

  static OpenRtbPodDurationValidationMode fromStableString(String? value) {
    switch (value) {
      case 'strict':
        return OpenRtbPodDurationValidationMode.strict;
      case 'lenient':
      default:
        return OpenRtbPodDurationValidationMode.lenient;
    }
  }
}

extension OpenRtbPodSkipPolicyExtension on OpenRtbPodSkipPolicy {
  String toStableString() {
    switch (this) {
      case OpenRtbPodSkipPolicy.skipCurrentAndContinue:
        return 'skipCurrentAndContinue';
      case OpenRtbPodSkipPolicy.failEntirePod:
        return 'failEntirePod';
    }
  }

  static OpenRtbPodSkipPolicy fromStableString(String? value) {
    switch (value) {
      case 'failEntirePod':
        return OpenRtbPodSkipPolicy.failEntirePod;
      case 'skipCurrentAndContinue':
      default:
        return OpenRtbPodSkipPolicy.skipCurrentAndContinue;
    }
  }
}

/// SDK Configuration for BidsCube Flutter SDK
class SDKConfig {
  /// Base URL for API requests
  final String baseURL;

  /// Enable console logging
  final bool enableLogging;

  /// Enable debug mode
  final bool enableDebugMode;

  /// Default ad timeout in milliseconds
  final int defaultAdTimeout;

  /// Default ad position
  final AdPosition defaultAdPosition;

  /// Enable test mode
  final bool enableTestMode;

  /// Enable OpenRTB pod metadata parsing for video responses.
  final bool openRtbPodMetadataEnabled;

  /// Duration validation mode for OpenRTB video pods.
  final OpenRtbPodDurationValidationMode videoPodDurationValidationMode;

  /// Skip policy when a pod slot fails.
  final OpenRtbPodSkipPolicy videoPodSkipPolicy;

  /// Continue the pod when an individual slot errors.
  final bool videoPodContinueOnSlotError;

  /// Show pod slot counter UI in native pod playback (when supported).
  final bool videoPodShowCounter;

  const SDKConfig({
    required this.baseURL,
    this.enableLogging = true,
    this.enableDebugMode = false,
    this.defaultAdTimeout = 30000,
    this.defaultAdPosition = AdPosition.unknown,
    this.enableTestMode = false,
    this.openRtbPodMetadataEnabled = true,
    this.videoPodDurationValidationMode =
        OpenRtbPodDurationValidationMode.lenient,
    this.videoPodSkipPolicy = OpenRtbPodSkipPolicy.skipCurrentAndContinue,
    this.videoPodContinueOnSlotError = true,
    this.videoPodShowCounter = true,
  });

  /// Create SDKConfig from Map
  factory SDKConfig.fromMap(Map<String, dynamic> map) {
    return SDKConfig(
      baseURL: map['baseURL'] ?? '',
      enableLogging: map['enableLogging'] ?? true,
      enableDebugMode: map['enableDebugMode'] ?? false,
      defaultAdTimeout: map['defaultAdTimeout'] ?? 30000,
      defaultAdPosition: AdPosition.values.firstWhere(
        (position) => position.value == map['defaultAdPosition'],
        orElse: () => AdPosition.unknown,
      ),
      enableTestMode: map['enableTestMode'] ?? false,
      openRtbPodMetadataEnabled: map['openRtbPodMetadataEnabled'] ?? true,
      videoPodDurationValidationMode:
          OpenRtbPodDurationValidationModeExtension.fromStableString(
            map['videoPodDurationValidationMode'] as String?,
          ),
      videoPodSkipPolicy: OpenRtbPodSkipPolicyExtension.fromStableString(
        map['videoPodSkipPolicy'] as String?,
      ),
      videoPodContinueOnSlotError: map['videoPodContinueOnSlotError'] ?? true,
      videoPodShowCounter: map['videoPodShowCounter'] ?? true,
    );
  }

  /// Convert SDKConfig to Map
  Map<String, dynamic> toMap() {
    return {
      'baseURL': baseURL,
      'enableLogging': enableLogging,
      'enableDebugMode': enableDebugMode,
      'defaultAdTimeout': defaultAdTimeout,
      'defaultAdPosition': defaultAdPosition.value,
      'enableTestMode': enableTestMode,
      'openRtbPodMetadataEnabled': openRtbPodMetadataEnabled,
      'videoPodDurationValidationMode': videoPodDurationValidationMode
          .toStableString(),
      'videoPodSkipPolicy': videoPodSkipPolicy.toStableString(),
      'videoPodContinueOnSlotError': videoPodContinueOnSlotError,
      'videoPodShowCounter': videoPodShowCounter,
    };
  }

  /// Builder pattern for SDKConfig
  static SDKConfigBuilder builder() => SDKConfigBuilder();
}

/// Builder class for SDKConfig
class SDKConfigBuilder {
  String _baseURL = 'https://ssp-bcc-ads.com/sdk';
  bool _enableLogging = true;
  bool _enableDebugMode = false;
  int _defaultAdTimeout = 30000;
  AdPosition _defaultAdPosition = AdPosition.unknown;
  bool _enableTestMode = false;
  bool _openRtbPodMetadataEnabled = true;
  OpenRtbPodDurationValidationMode _videoPodDurationValidationMode =
      OpenRtbPodDurationValidationMode.lenient;
  OpenRtbPodSkipPolicy _videoPodSkipPolicy =
      OpenRtbPodSkipPolicy.skipCurrentAndContinue;
  bool _videoPodContinueOnSlotError = true;
  bool _videoPodShowCounter = true;

  /// Set base URL
  SDKConfigBuilder baseURL(String url) {
    _baseURL = url;
    return this;
  }

  /// Enable logging
  SDKConfigBuilder enableLogging(bool enable) {
    _enableLogging = enable;
    return this;
  }

  /// Enable debug mode
  SDKConfigBuilder enableDebugMode(bool enable) {
    _enableDebugMode = enable;
    return this;
  }

  /// Set default ad timeout
  SDKConfigBuilder defaultAdTimeout(int timeout) {
    _defaultAdTimeout = timeout;
    return this;
  }

  /// Set default ad position
  SDKConfigBuilder defaultAdPosition(AdPosition position) {
    _defaultAdPosition = position;
    return this;
  }

  /// Enable test mode
  SDKConfigBuilder enableTestMode(bool enable) {
    _enableTestMode = enable;
    return this;
  }

  SDKConfigBuilder openRtbPodMetadataEnabled(bool enabled) {
    _openRtbPodMetadataEnabled = enabled;
    return this;
  }

  SDKConfigBuilder videoPodDurationValidationMode(
    OpenRtbPodDurationValidationMode mode,
  ) {
    _videoPodDurationValidationMode = mode;
    return this;
  }

  SDKConfigBuilder videoPodSkipPolicy(OpenRtbPodSkipPolicy policy) {
    _videoPodSkipPolicy = policy;
    return this;
  }

  SDKConfigBuilder videoPodContinueOnSlotError(bool enabled) {
    _videoPodContinueOnSlotError = enabled;
    return this;
  }

  SDKConfigBuilder videoPodShowCounter(bool enabled) {
    _videoPodShowCounter = enabled;
    return this;
  }

  /// Build SDKConfig
  SDKConfig build() {
    return SDKConfig(
      baseURL: _baseURL,
      enableLogging: _enableLogging,
      enableDebugMode: _enableDebugMode,
      defaultAdTimeout: _defaultAdTimeout,
      defaultAdPosition: _defaultAdPosition,
      enableTestMode: _enableTestMode,
      openRtbPodMetadataEnabled: _openRtbPodMetadataEnabled,
      videoPodDurationValidationMode: _videoPodDurationValidationMode,
      videoPodSkipPolicy: _videoPodSkipPolicy,
      videoPodContinueOnSlotError: _videoPodContinueOnSlotError,
      videoPodShowCounter: _videoPodShowCounter,
    );
  }
}
