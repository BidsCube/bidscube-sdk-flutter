import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:bidscube_sdk_flutter/src/core/ad_request_client.dart';

import 'openrtb_test_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const packageInfoChannel = MethodChannel(
      'dev.fluttercommunity.plus/package_info',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(packageInfoChannel, (methodCall) async {
          if (methodCall.method == 'getAll') {
            return {
              'appName': 'Test App',
              'packageName': 'com.bidscube.test',
              'version': '1.0.0',
              'buildNumber': '1',
            };
          }
          return null;
        });
  });

  const customBaseUrl = 'https://custom-ssp.example/sdk';

  group('AdRequestClient custom baseUrl', () {
    test('requestNativeAd uses instance baseUrl', () async {
      Uri? capturedUri;
      final client = AdRequestClient(
        baseUrl: customBaseUrl,
        client: MockClient((request) async {
          capturedUri = request.url;
          return http.Response('{"adm":"<div>native</div>"}', 200);
        }),
      );

      await client.requestNativeAd(placementId: 'native-placement');

      expect(capturedUri, isNotNull);
      expect(capturedUri!.origin + capturedUri!.path, customBaseUrl);
    });

    test('requestBannerAd uses instance baseUrl', () async {
      Uri? capturedUri;
      final client = AdRequestClient(
        baseUrl: customBaseUrl,
        client: MockClient((request) async {
          capturedUri = request.url;
          return http.Response('{"adm":"<div>banner</div>"}', 200);
        }),
      );

      await client.requestBannerAd(placementId: 'banner-placement');

      expect(capturedUri, isNotNull);
      expect(capturedUri!.origin + capturedUri!.path, customBaseUrl);
    });

    test('requestVideoAd uses instance baseUrl', () async {
      Uri? capturedUri;
      final client = AdRequestClient(
        baseUrl: customBaseUrl,
        client: MockClient((request) async {
          capturedUri = request.url;
          return http.Response(OpenRtbTestFixtures.rawVast, 200);
        }),
      );

      await client.requestVideoAd(placementId: 'video-placement');

      expect(capturedUri, isNotNull);
      expect(capturedUri!.origin + capturedUri!.path, customBaseUrl);
    });
  });
}
