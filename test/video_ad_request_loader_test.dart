import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:bidscube_sdk_flutter/bidscube_sdk_flutter.dart';
import 'package:bidscube_sdk_flutter/src/core/video_ad_request_loader.dart';

import 'openrtb_test_fixtures.dart';

class _StubHttpClient extends http.BaseClient {
  _StubHttpClient(this._response);

  final http.Response _response;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream.value(_response.bodyBytes),
      _response.statusCode,
      headers: _response.headers,
    );
  }
}

void main() {
  group('VideoAdRequestLoader.resolveContent', () {
    test('resolves unicode-escaped JSON adm from SSP', () {
      final body =
          '{"adm":"\\u003cVAST version=\\"3.0\\"\\u003e\\u003cAd id=\\"20\\"\\u003e'
          '\\u003cInLine\\u003e\\u003cAdTitle\\u003eTest\\u003c/AdTitle\\u003e'
          '\\u003cCreatives\\u003e\\u003cCreative\\u003e\\u003cLinear\\u003e'
          '\\u003cMediaFiles\\u003e\\u003cMediaFile\\u003e\\u003c![CDATA[https://example.com/v.mp4]]\\u003e'
          '\\u003c/MediaFile\\u003e\\u003c/MediaFiles\\u003e\\u003c/Linear\\u003e'
          '\\u003c/Creative\\u003e\\u003c/Creatives\\u003e\\u003c/InLine\\u003e\\u003c/Ad\\u003e\\u003c/VAST\\u003e","position":7}';

      final resolved = VideoAdRequestLoader.resolveContent(
        body: body,
        config: OpenRtbTestFixtures.defaultConfig(),
      );

      expect(resolved, isNotNull);
      expect(resolved!.vastXml, contains('<VAST'));
      expect(resolved.position, AdPosition.fullScreen);
    });

    test('resolves JSON adm with XML declaration prefix', () {
      final body =
          '{"adm":"\\u003c?xml version=\\"1.0\\" encoding=\\"UTF-8\\"?\\u003e\\u003cVAST version=\\"3.0\\"\\u003e\\u003cAd\\u003e\\u003cInLine\\u003e\\u003cCreatives\\u003e\\u003cCreative\\u003e\\u003cLinear\\u003e\\u003cMediaFiles\\u003e\\u003cMediaFile\\u003e\\u003c![CDATA[https://example.com/v.mp4]]\\u003e\\u003c/MediaFile\\u003e\\u003c/MediaFiles\\u003e\\u003c/Linear\\u003e\\u003c/Creative\\u003e\\u003c/Creatives\\u003e\\u003c/InLine\\u003e\\u003c/Ad\\u003e\\u003c/VAST\\u003e"}';

      final resolved = VideoAdRequestLoader.resolveContent(
        body: body,
        config: OpenRtbTestFixtures.defaultConfig(),
      );

      expect(resolved?.vastXml, contains('<VAST'));
    });

    test('resolves raw inline VAST', () {
      final resolved = VideoAdRequestLoader.resolveContent(
        body: OpenRtbTestFixtures.rawVast,
        config: OpenRtbTestFixtures.defaultConfig(),
      );
      expect(resolved?.vastXml, contains('<VAST'));
    });
  });

  group('VideoAdRequestLoader.loadFromUrl', () {
    test('maps HTTP 400 JSON error to HTTP_400 instead of empty VAST message', () async {
      final loader = VideoAdRequestLoader(
        client: _StubHttpClient(
          http.Response(
            '{"status":"Error","message":"Placement not found"}',
            400,
          ),
        ),
      );

      final result = await loader.loadFromUrl(
        apiURL: 'https://example.com/sdk?id=1',
        config: OpenRtbTestFixtures.defaultConfig(),
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, 'HTTP_400');
      expect(result.errorMessage, 'Placement not found');
    });

    test('maps empty 200 body to NO_FILL', () async {
      final loader = VideoAdRequestLoader(
        client: _StubHttpClient(http.Response('', 200)),
      );

      final result = await loader.loadFromUrl(
        apiURL: 'https://example.com/sdk?id=1',
        config: OpenRtbTestFixtures.defaultConfig(),
      );

      expect(result.errorCode, 'NO_FILL');
    });

    test('loads playable payload from HTTP 200 JSON adm', () async {
      final body = OpenRtbTestFixtures.jsonString(
        OpenRtbTestFixtures.legacyRootAdmJson(),
      );
      final loader = VideoAdRequestLoader(
        client: _StubHttpClient(http.Response(body, 200)),
      );

      final result = await loader.loadFromUrl(
        apiURL: 'https://example.com/sdk?id=1',
        config: OpenRtbTestFixtures.defaultConfig(),
      );

      expect(result.isSuccess, isTrue);
      expect(result.payload?.vastXml, contains('<VAST'));
    });
  });
}
