import 'package:flutter_test/flutter_test.dart';
import 'package:bidscube_sdk_flutter/bidscube_sdk_flutter.dart';
import 'package:bidscube_sdk_flutter/src/openrtb/vast_ad_sequence_parser.dart';
import 'package:bidscube_sdk_flutter/src/openrtb/video_ad_payload_resolver.dart';

import 'openrtb_test_fixtures.dart';

void main() {
  group('VideoAdPayloadResolver', () {
    test('raw VAST still works', () {
      final resolved = VideoAdPayloadResolver.resolve(
        content: OpenRtbTestFixtures.rawVast,
        config: OpenRtbTestFixtures.defaultConfig(),
      );
      expect(resolved, isNotNull);
      expect(resolved!.vastXml, contains('<VAST'));
    });

    test('root JSON adm still works', () {
      final resolved = VideoAdPayloadResolver.resolve(
        content: OpenRtbTestFixtures.jsonString(
          OpenRtbTestFixtures.legacyRootAdmJson(),
        ),
        config: OpenRtbTestFixtures.defaultConfig(),
      );
      expect(resolved, isNotNull);
      expect(resolved!.vastXml, contains('<VAST'));
      expect(resolved.position, AdPosition.sidebar);
    });

    test('root adm URL is handled safely', () {
      final resolved = VideoAdPayloadResolver.resolve(
        content: '{"adm":"https://example.com/vast.xml","position":1}',
        config: OpenRtbTestFixtures.defaultConfig(),
      );
      expect(resolved?.adTagUrl, 'https://example.com/vast.xml');
    });

    test('structured openrtb pod resolves composed VAST', () {
      final resolved = VideoAdPayloadResolver.resolve(
        content: OpenRtbTestFixtures.jsonString(
          OpenRtbTestFixtures.structuredPodJson(),
        ),
        config: OpenRtbTestFixtures.defaultConfig(),
      );
      expect(resolved, isNotNull);
      expect(resolved!.playbackPlan?.slots.length, 2);
      expect(resolved.adsResponse, contains('<VAST'));
    });

    test('invalid OpenRTB falls back to legacy root adm', () {
      final resolved = VideoAdPayloadResolver.resolve(
        content: OpenRtbTestFixtures.jsonString({
          'openrtb': {
            'video': {'podid': 'pod-only'},
          },
          'adm': OpenRtbTestFixtures.rawVast,
        }),
        config: OpenRtbTestFixtures.defaultConfig(),
      );
      expect(resolved?.vastXml, contains('<VAST'));
    });

    test('openRtbPodMetadataEnabled=false skips OpenRTB pod logic', () {
      final resolved = VideoAdPayloadResolver.resolve(
        content: OpenRtbTestFixtures.jsonString(
          OpenRtbTestFixtures.structuredPodJson(),
        ),
        config: OpenRtbTestFixtures.defaultConfig(openRtbEnabled: false),
      );
      expect(resolved, isNull);
    });

    test('openRtbPodMetadataEnabled=false still resolves legacy root adm', () {
      final resolved = VideoAdPayloadResolver.resolve(
        content: OpenRtbTestFixtures.jsonString(
          OpenRtbTestFixtures.legacyRootAdmJson(),
        ),
        config: OpenRtbTestFixtures.defaultConfig(openRtbEnabled: false),
      );
      expect(resolved, isNotNull);
      expect(resolved!.vastXml, contains('<VAST'));
    });

    test(
      'openRtbPodMetadataEnabled=false does not parse bids[] as OpenRTB pod',
      () {
        final resolved = VideoAdPayloadResolver.resolve(
          content: OpenRtbTestFixtures.jsonString({
            'openrtb': {
              'video': {'podid': 'pod-only'},
            },
            'bids': [
              {
                'adm': OpenRtbTestFixtures.rawVast,
                'slotinpod': 1,
                'duration': 15,
              },
            ],
          }),
          config: OpenRtbTestFixtures.defaultConfig(openRtbEnabled: false),
        );
        expect(resolved, isNull);
      },
    );

    test('single root adm multi-ad vast composes two Ad nodes', () {
      final resolved = VideoAdPayloadResolver.resolve(
        content: OpenRtbTestFixtures.jsonString(
          OpenRtbTestFixtures.singleAdmMultiAdVastJson(),
        ),
        config: OpenRtbTestFixtures.defaultConfig(),
      );
      expect(resolved, isNotNull);
      expect(resolved!.playbackPlan?.slots.length, 2);
      final composed = resolved.adsResponse ?? resolved.vastXml;
      expect(composed, isNotNull);
      expect(VastAdSequenceParser.extractAdNodes(composed!).length, 2);
    });

    test('returns null for unplayable content', () {
      expect(
        VideoAdPayloadResolver.resolve(
          content: 'not-json-or-vast',
          config: OpenRtbTestFixtures.defaultConfig(),
        ),
        isNull,
      );
    });
  });
}
