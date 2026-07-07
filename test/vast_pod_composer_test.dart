import 'package:flutter_test/flutter_test.dart';
import 'package:bidscube_sdk_flutter/src/openrtb/openrtb_pod_models.dart';
import 'package:bidscube_sdk_flutter/src/openrtb/vast_ad_sequence_parser.dart';
import 'package:bidscube_sdk_flutter/src/openrtb/vast_pod_composer.dart';

import 'openrtb_test_fixtures.dart';

void main() {
  group('VastPodComposer', () {
    test('returns single slot unchanged', () {
      final vast = OpenRtbTestFixtures.rawVast;
      final composed = VastPodComposer.compose([
        VideoPlaybackSlot(
          adm: vast,
          vastXml: vast,
          slotIndex: 0,
          durationSeconds: 15,
        ),
      ]);
      expect(composed, contains('<VAST'));
      expect(composed, contains('<Ad'));
    });

    test('composes multiple inline slots into one VAST document', () {
      final slot1 = OpenRtbTestFixtures.vastDocument([
        OpenRtbTestFixtures.vastAd(sequence: 1, durationSeconds: 15, id: 'a'),
      ]);
      final slot2 = OpenRtbTestFixtures.vastDocument([
        OpenRtbTestFixtures.vastAd(sequence: 2, durationSeconds: 30, id: 'b'),
      ]);

      final composed = VastPodComposer.compose([
        VideoPlaybackSlot(
          adm: slot1,
          vastXml: slot1,
          slotIndex: 0,
          slotInPod: 1,
          durationSeconds: 15,
        ),
        VideoPlaybackSlot(
          adm: slot2,
          vastXml: slot2,
          slotIndex: 1,
          slotInPod: 2,
          durationSeconds: 30,
        ),
      ]);

      expect(composed, isNotNull);
      expect(composed!.startsWith('<VAST version="3.0">'), isTrue);
      expect(VastAdSequenceParser.extractAdNodes(composed).length, 2);
      expect(composed.contains('<VAST version="3.0"><VAST'), isFalse);
    });

    test('does not concatenate full VAST documents as nested roots', () {
      final slot1 = OpenRtbTestFixtures.vastDocument([
        OpenRtbTestFixtures.vastAd(sequence: 1, durationSeconds: 15),
      ]);
      final slot2 = OpenRtbTestFixtures.vastDocument([
        OpenRtbTestFixtures.vastAd(sequence: 2, durationSeconds: 20),
      ]);
      final composed = VastPodComposer.compose([
        VideoPlaybackSlot(adm: slot1, vastXml: slot1, slotIndex: 0),
        VideoPlaybackSlot(adm: slot2, vastXml: slot2, slotIndex: 1),
      ]);
      expect(composed, isNotNull);
      expect(
        RegExp(r'<VAST', caseSensitive: false).allMatches(composed!).length,
        1,
      );
    });

    test('mixed URL and XML slots return first URL', () {
      final vast = OpenRtbTestFixtures.rawVast;
      final composed = VastPodComposer.compose([
        VideoPlaybackSlot(
          adm: 'https://example.com/vast.xml',
          adTagUrl: 'https://example.com/vast.xml',
          slotIndex: 0,
        ),
        VideoPlaybackSlot(adm: vast, vastXml: vast, slotIndex: 1),
      ]);
      expect(composed, 'https://example.com/vast.xml');
    });
  });
}
