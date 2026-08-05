import 'dart:convert';

import 'package:http/http.dart' as http;

import '../openrtb/vast_ad_sequence_parser.dart';
import '../openrtb/video_ad_payload_resolver.dart';
import 'adm_markup_extractor.dart';
import 'ad_position.dart';
import 'logger.dart';
import 'sdk_config.dart';
import 'url_builder.dart';

/// Result of a video ad HTTP request + payload resolution.
class VideoAdLoadResult {
  const VideoAdLoadResult._({
    required this.statusCode,
    this.payload,
    this.errorCode,
    this.errorMessage,
    this.responseBody,
  });

  final int statusCode;
  final ResolvedVideoAdPayload? payload;
  final String? errorCode;
  final String? errorMessage;
  final String? responseBody;

  bool get isSuccess =>
      errorCode == null &&
      payload != null &&
      VideoAdRequestLoader.hasPlayablePayload(payload!);

  factory VideoAdLoadResult.success({
    required int statusCode,
    required ResolvedVideoAdPayload payload,
    String? responseBody,
  }) {
    return VideoAdLoadResult._(
      statusCode: statusCode,
      payload: payload,
      responseBody: responseBody,
    );
  }

  factory VideoAdLoadResult.failure({
    required int statusCode,
    required String errorCode,
    required String errorMessage,
    String? responseBody,
  }) {
    return VideoAdLoadResult._(
      statusCode: statusCode,
      errorCode: errorCode,
      errorMessage: errorMessage,
      responseBody: responseBody,
    );
  }
}

/// Shared video ad HTTP fetch + VAST/JSON payload resolution.
class VideoAdRequestLoader {
  VideoAdRequestLoader({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static bool hasPlayablePayload(ResolvedVideoAdPayload payload) {
    final playable =
        payload.adsResponse ?? payload.vastXml ?? payload.adTagUrl;
    return playable != null && playable.trim().isNotEmpty;
  }

  Future<VideoAdLoadResult> loadFromUrl({
    required String apiURL,
    required SDKConfig config,
    Map<String, String>? headers,
  }) async {
    final timeout = Duration(milliseconds: config.defaultAdTimeout);
    final uri = Uri.parse(apiURL);

    SDKLogger.info('Video ad HTTP GET: $apiURL');

    late http.Response response;
    try {
      response = await _client
          .get(uri, headers: headers)
          .timeout(timeout);
    } catch (e) {
      SDKLogger.error('Video ad HTTP request failed', e);
      return VideoAdLoadResult.failure(
        statusCode: -1,
        errorCode: 'NETWORK_ERROR',
        errorMessage: e.toString(),
      );
    }

    final body = response.body;
    SDKLogger.info(
      'Video ad HTTP ${response.statusCode}, bodyLength=${body.length}',
    );

    if (response.statusCode == 204 ||
        (response.statusCode == 200 && body.trim().isEmpty)) {
      return VideoAdLoadResult.failure(
        statusCode: response.statusCode,
        errorCode: 'NO_FILL',
        errorMessage: 'No ad available for this placement',
        responseBody: body,
      );
    }

    if (response.statusCode != 200) {
      final serverMessage = _extractServerErrorMessage(body);
      return VideoAdLoadResult.failure(
        statusCode: response.statusCode,
        errorCode: 'HTTP_${response.statusCode}',
        errorMessage: serverMessage ??
            'Ad server returned HTTP ${response.statusCode}',
        responseBody: body,
      );
    }

    final payload = resolveContent(body: body, config: config);
    if (payload != null && hasPlayablePayload(payload)) {
      return VideoAdLoadResult.success(
        statusCode: response.statusCode,
        payload: payload,
        responseBody: body,
      );
    }

    final serverMessage = _extractServerErrorMessage(body);
    return VideoAdLoadResult.failure(
      statusCode: response.statusCode,
      errorCode: 'NO_PLAYABLE_PAYLOAD',
      errorMessage: serverMessage ??
          'No playable VAST payload received from server',
      responseBody: body,
    );
  }

  /// Resolve inline content, JSON envelopes, escaped ADM, and ad tag URLs.
  static ResolvedVideoAdPayload? resolveContent({
    required String body,
    required SDKConfig config,
  }) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final direct = VideoAdPayloadResolver.resolve(
      content: trimmed,
      config: config,
    );
    if (direct != null && hasPlayablePayload(direct)) {
      return direct;
    }

    if (trimmed.startsWith('{')) {
      final fromJson = _resolveJsonEnvelope(trimmed, config);
      if (fromJson != null && hasPlayablePayload(fromJson)) {
        return fromJson;
      }
    }

    final extracted = AdmMarkupExtractor.extractRenderMarkup(trimmed);
    if (extracted.isNotEmpty && extracted != trimmed) {
      final fromExtracted = VideoAdPayloadResolver.resolve(
        content: extracted,
        config: config,
      );
      if (fromExtracted != null && hasPlayablePayload(fromExtracted)) {
        return fromExtracted;
      }
      return _payloadFromMarkup(extracted, position: AdPosition.unknown);
    }

    return _payloadFromMarkup(trimmed, position: AdPosition.unknown);
  }

  static ResolvedVideoAdPayload? _resolveJsonEnvelope(
    String jsonBody,
    SDKConfig config,
  ) {
    try {
      final decoded = json.decode(jsonBody);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      if (_extractServerErrorMessage(jsonBody) != null &&
          !_jsonHasUsableAdm(decoded)) {
        return null;
      }

      final position = _positionFromJson(decoded);
      final adm = AdmMarkupExtractor.admFromResponse(decoded);
      if (adm.isEmpty) {
        return null;
      }

      final fromAdm = VideoAdPayloadResolver.resolve(
        content: adm,
        config: config,
      );
      if (fromAdm != null && hasPlayablePayload(fromAdm)) {
        if (fromAdm.position == AdPosition.unknown &&
            position != AdPosition.unknown) {
          return ResolvedVideoAdPayload(
            playbackPlan: fromAdm.playbackPlan,
            adsResponse: fromAdm.adsResponse,
            adTagUrl: fromAdm.adTagUrl,
            vastXml: fromAdm.vastXml,
            position: position,
          );
        }
        return fromAdm;
      }

      return _payloadFromMarkup(adm, position: position);
    } catch (e) {
      SDKLogger.debug('JSON envelope parse failed: $e');
      return null;
    }
  }

  static ResolvedVideoAdPayload? _payloadFromMarkup(
    String markup, {
    required AdPosition position,
  }) {
    final trimmed = markup.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    if (VastAdSequenceParser.isAdTagUrl(trimmed)) {
      return ResolvedVideoAdPayload(adTagUrl: trimmed, position: position);
    }

    if (VastAdSequenceParser.contentLikelyContainsVast(trimmed)) {
      return ResolvedVideoAdPayload(
        adsResponse: trimmed,
        vastXml: trimmed,
        position: position,
      );
    }

    return null;
  }

  static bool _jsonHasUsableAdm(Map<String, dynamic> json) {
    final adm = AdmMarkupExtractor.admFromResponse(json);
    return adm.trim().isNotEmpty;
  }

  static AdPosition _positionFromJson(Map<String, dynamic> json) {
    final positionValue = json['position'];
    if (positionValue is num) {
      return AdPositionExtension.fromValue(positionValue.toInt());
    }
    return AdPosition.unknown;
  }

  static String? _extractServerErrorMessage(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty || !trimmed.startsWith('{')) {
      return null;
    }

    try {
      final decoded = json.decode(trimmed);
      if (decoded is! Map) {
        return null;
      }

      final map = Map<String, dynamic>.from(decoded);
      final status = map['status']?.toString().toLowerCase();
      final message = map['message']?.toString().trim();
      final error = map['error']?.toString().trim();

      if (message != null && message.isNotEmpty) {
        if (status == 'error' || error != null) {
          return message;
        }
      }
      if (error != null && error.isNotEmpty) {
        return error;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static Future<Map<String, String>> defaultHeaders() async {
    final userAgent = await URLBuilder.buildBrowserUserAgent();
    return {'User-Agent': userAgent, 'Accept': '*/*'};
  }
}
