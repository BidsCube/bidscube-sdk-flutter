import 'dart:convert';
import 'dart:io';
import 'package:bidscube_sdk_flutter/bidscube_sdk_flutter.dart';
import 'package:http/http.dart' as http;

/// HTTP client for making ad requests without native dependencies
/// HTTP client for making ad requests without native dependencies
class AdRequestClient {
  static const Duration _defaultTimeout = Duration(seconds: 30);

  /// The base URL for ad requests.
  final String baseUrl;

  /// The timeout duration for ad requests.
  final Duration timeout;
  final Map<String, String> _defaultHeaders;

  /// Creates an [AdRequestClient].
  ///
  /// [baseUrl] sets the base URL for ad requests. Defaults to [Constants.baseURL].
  /// [timeout] sets the request timeout. Defaults to 30 seconds.
  /// [defaultHeaders] sets default headers for all requests.
  AdRequestClient({
    String? baseUrl,
    Duration? timeout,
    Map<String, String>? defaultHeaders,
  }) : baseUrl = baseUrl ?? Constants.baseURL,
       timeout = timeout ?? _defaultTimeout,
       _defaultHeaders = defaultHeaders ?? {};

  /// Request image ad
  Future<Map<String, dynamic>?> requestImageAd({
    required String placementId,
    Map<String, String>? additionalHeaders,
  }) async {
    try {
      final headers = {
        'X-Placement-ID': placementId,
        'X-Ad-Type': 'image',
        ...additionalHeaders ?? {},
      };

      SDKLogger.info('Requesting image ad: $placementId');

      final response = await _makeRequest(
        endpoint: '/ads/image',
        method: 'GET',
        headers: headers,
      );

      SDKLogger.info('Image ad response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw AdRequestException(
          'Failed to load image ad: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      SDKLogger.error('Image ad request failed', e);
      rethrow;
    }
  }

  /// Request video ad (VAST)
  Future<String?> requestVideoAd({
    required String placementId,
    Map<String, String>? additionalHeaders,
  }) async {
    try {
      final headers = {
        'X-Placement-ID': placementId,
        'X-Ad-Type': 'video',
        'Accept': 'application/xml',
        ...additionalHeaders ?? {},
      };

      SDKLogger.info('Requesting video ad: $placementId');

      final response = await _makeRequest(
        endpoint: '/ads/vast',
        method: 'GET',
        headers: headers,
      );

      SDKLogger.info('Video ad response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw AdRequestException(
          'Failed to load video ad: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      SDKLogger.error('Video ad request failed', e);
      rethrow;
    }
  }

  /// Request native ad
  Future<Map<String, dynamic>?> requestNativeAd({
    required String placementId,
    Map<String, String>? additionalHeaders,
  }) async {
    try {
      final headers = {
        'X-Placement-ID': placementId,
        'X-Ad-Type': 'native',
        ...additionalHeaders ?? {},
      };

      SDKLogger.info('Requesting native ad: $placementId');

      final response = await _makeRequest(
        endpoint: '/ads/native',
        method: 'GET',
        headers: headers,
      );

      SDKLogger.info('Native ad response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw AdRequestException(
          'Failed to load native ad: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      SDKLogger.error('Native ad request failed', e);
      rethrow;
    }
  }

  /// Request banner ad
  Future<Map<String, dynamic>?> requestBannerAd({
    required String placementId,
    Map<String, String>? additionalHeaders,
  }) async {
    try {
      final headers = {
        'X-Placement-ID': placementId,
        'X-Ad-Type': 'banner',
        ...additionalHeaders ?? {},
      };

      SDKLogger.info('Requesting banner ad: $placementId');

      final response = await _makeRequest(
        endpoint: '/ads/banner',
        method: 'GET',
        headers: headers,
      );

      SDKLogger.info('Banner ad response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw AdRequestException(
          'Failed to load banner ad: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      SDKLogger.error('Banner ad request failed', e);
      rethrow;
    }
  }

  /// Track ad events
  Future<void> trackAdEvent({
    required String placementId,
    required String event,
    String? eventData,
    Map<String, String>? additionalHeaders,
  }) async {
    try {
      await _makeRequest(
        endpoint: '/ads/track',
        method: 'POST',
        headers: {
          'X-Placement-ID': placementId,
          'X-Event': event,
          'Content-Type': 'application/json',
          ...additionalHeaders ?? {},
        },
        body: json.encode({
          'event': event,
          'placementId': placementId,
          'data': eventData,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      SDKLogger.error('Ad event tracking failed', e);
      // Don't rethrow for tracking failures
    }
  }

  /// Make HTTP request
  Future<http.Response> _makeRequest({
    required String endpoint,
    required String method,
    Map<String, String>? headers,
    String? body,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final requestHeaders = {
      'Content-Type': 'application/json',
      'User-Agent': _getUserAgent(),
      ..._defaultHeaders,
      ...headers ?? {},
    };

    SDKLogger.info('Making $method request to $uri');

    try {
      http.Response response;
      if (method == 'GET') {
        response = await http
            .get(uri, headers: requestHeaders)
            .timeout(timeout);
      } else if (method == 'POST') {
        response = await http
            .post(uri, headers: requestHeaders, body: body)
            .timeout(timeout);
      } else if (method == 'PUT') {
        response = await http
            .put(uri, headers: requestHeaders, body: body)
            .timeout(timeout);
      } else if (method == 'DELETE') {
        response = await http
            .delete(uri, headers: requestHeaders)
            .timeout(timeout);
      } else {
        throw Exception('Unsupported HTTP method: $method');
      }

      SDKLogger.info('Response: ${response.statusCode}');
      return response;
    } on SocketException catch (e) {
      throw AdRequestException('Network error: ${e.message}', 0);
    } on HttpException catch (e) {
      throw AdRequestException('HTTP error: ${e.message}', 0);
    } on FormatException catch (e) {
      throw AdRequestException('Format error: ${e.message}', 0);
    } catch (e) {
      throw AdRequestException('Unexpected error: $e', 0);
    }
  }

  /// Get user agent string
  String _getUserAgent() {
    return 'BidsCube-Flutter-SDK/1.0.0 (${Platform.operatingSystem})';
  }

  /// Get device information for ad targeting
  Map<String, String> getDeviceInfo() {
    return {
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'locale': Platform.localeName,
    };
  }
}

class AdRequestException implements Exception {
  final String message;
  final int statusCode;

  AdRequestException(this.message, this.statusCode);

  @override
  String toString() => 'AdRequestException: $message (Status: $statusCode)';
}

class AdRequestConfig {
  final Duration timeout;
  final Map<String, String> defaultHeaders;
  final bool enableLogging;
  final bool enableRetry;
  final int maxRetries;

  const AdRequestConfig({
    this.timeout = const Duration(seconds: 30),
    this.defaultHeaders = const {},
    this.enableLogging = true,
    this.enableRetry = true,
    this.maxRetries = 3,
  });

  factory AdRequestConfig.defaultConfig() {
    return const AdRequestConfig();
  }

  factory AdRequestConfig.testConfig() {
    return const AdRequestConfig(enableLogging: true);
  }
}
