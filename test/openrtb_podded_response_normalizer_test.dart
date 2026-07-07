import 'package:flutter_test/flutter_test.dart';
import 'package:bidscube_sdk_flutter/src/openrtb/openrtb_pod_models.dart';
import 'package:bidscube_sdk_flutter/src/openrtb/openrtb_podded_response_normalizer.dart';

import 'openrtb_test_fixtures.dart';

void main() {
  group('OpenRtbPoddedResponseNormalizer', () {
    test('parses structured pod from openrtb.video and bids[]', () {
      final normalized = OpenRtbPoddedResponseNormalizer.normalize(
        OpenRtbTestFixtures.structuredPodJson(),
      );
      expect(normalized, isNotNull);
      expect(normalized!.podContext.type, OpenRtbPodType.hybrid);
      expect(normalized.markups.length, 2);
    });

    test('parses seatbid[].bid[].ext shape', () {
      final normalized = OpenRtbPoddedResponseNormalizer.normalize(
        OpenRtbTestFixtures.seatbidJson(),
      );
      expect(normalized, isNotNull);
      expect(normalized!.markups.single.slotInPod, 1);
      expect(normalized.markups.single.durationSeconds, 15);
    });

    test('supports openRtb.video fallback', () {
      final json = {
        'openRtb': {
          'video': {'podid': 'camel-case'},
        },
        'bids': [
          {'adm': OpenRtbTestFixtures.rawVast, 'slotinpod': 1, 'duration': 15},
        ],
      };
      final normalized = OpenRtbPoddedResponseNormalizer.normalize(json);
      expect(normalized?.podContext.podId, 'camel-case');
    });

    test('supports root video fallback', () {
      final json = {
        'video': {
          'podid': 'root-video',
          'rqdDurs': [15],
        },
        'bids': [
          {'adm': OpenRtbTestFixtures.rawVast, 'duration': 15},
        ],
      };
      final normalized = OpenRtbPoddedResponseNormalizer.normalize(json);
      expect(normalized?.podContext.rqddursSeconds, [15]);
    });

    test('selects first sorted pod group when multiple pod ids exist', () {
      final normalized = OpenRtbPoddedResponseNormalizer.normalize(
        OpenRtbTestFixtures.multiPodSeatbidJson(),
      );
      expect(normalized, isNotNull);
      expect(normalized!.markups.every((m) => m.podId == 'pod-a'), isTrue);
    });

    test('returns null for invalid OpenRTB-like payloads', () {
      expect(OpenRtbPoddedResponseNormalizer.normalize({'bids': []}), isNull);
    });

    test('root adm shape with openrtb video metadata is supported', () {
      final normalized = OpenRtbPoddedResponseNormalizer.normalize({
        'adm': OpenRtbTestFixtures.rawVast,
        'position': 1,
        'openrtb': {
          'video': {
            'podid': 'pod-1',
            'poddur': 60,
            'rqddurs': [15, 30],
            'maxseq': 3,
          },
        },
      });
      expect(normalized, isNotNull);
      expect(normalized!.markups.length, 1);
    });
  });
}
