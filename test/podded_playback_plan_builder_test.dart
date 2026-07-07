import 'package:flutter_test/flutter_test.dart';
import 'package:bidscube_sdk_flutter/bidscube_sdk_flutter.dart';
import 'package:bidscube_sdk_flutter/src/openrtb/openrtb_pod_models.dart';
import 'package:bidscube_sdk_flutter/src/openrtb/openrtb_podded_response_normalizer.dart';
import 'package:bidscube_sdk_flutter/src/openrtb/podded_playback_plan_builder.dart';

import 'openrtb_test_fixtures.dart';

void main() {
  group('PoddedPlaybackPlanBuilder', () {
    test('structured pod sorts by slotinpod', () {
      final normalized = OpenRtbPoddedResponseNormalizer.normalize(
        OpenRtbTestFixtures.structuredPodJson(),
      );
      final plan = PoddedPlaybackPlanBuilder.build(
        normalized!,
        OpenRtbTestFixtures.defaultConfig(),
      );
      expect(plan, isNotNull);
      expect(plan!.slots.length, 2);
      expect(plan.slots[0].slotInPod, 1);
      expect(plan.slots[1].slotInPod, 2);
      expect(plan.slots[0].durationSeconds, 15);
      expect(plan.slots[1].durationSeconds, 30);
    });

    test('dynamic pod respects poddur and skips oversized slot', () {
      final normalized = OpenRtbPoddedResponseNormalizer.normalize(
        OpenRtbTestFixtures.dynamicPodJson(),
      );
      expect(normalized!.podContext.type, OpenRtbPodType.dynamic);
      final plan = PoddedPlaybackPlanBuilder.build(
        normalized,
        OpenRtbTestFixtures.defaultConfig(),
      );
      final durations = plan!.slots
          .map((s) => s.durationSeconds)
          .whereType<int>();
      expect(durations.contains(45), isFalse);
      expect(
        durations.fold<int>(0, (sum, value) => sum + value),
        lessThanOrEqualTo(30),
      );
    });

    test('hybrid pod keeps fixed slots then fills budget', () {
      final normalized = OpenRtbPoddedResponseNormalizer.normalize(
        OpenRtbTestFixtures.hybridPodJson(),
      );
      expect(normalized!.podContext.type, OpenRtbPodType.hybrid);
      final plan = PoddedPlaybackPlanBuilder.build(
        normalized,
        OpenRtbTestFixtures.defaultConfig(),
      );
      expect(plan!.slots.first.slotInPod, 1);
      final total = plan.slots
          .map((s) => s.durationSeconds)
          .whereType<int>()
          .fold<int>(0, (sum, value) => sum + value);
      expect(total, lessThanOrEqualTo(40));
    });

    test('single adm multi-ad vast does not copy slotinpod to all ads', () {
      final normalized = OpenRtbPoddedResponseNormalizer.normalize(
        OpenRtbTestFixtures.singleAdmMultiAdVastJson(slotInPod: 1),
      );
      final plan = PoddedPlaybackPlanBuilder.build(
        normalized!,
        OpenRtbTestFixtures.defaultConfig(),
      );
      expect(plan!.slots.length, 2);
      expect(plan.slots.every((slot) => slot.slotInPod == null), isTrue);
      expect(plan.slots[0].durationSeconds, 15);
      expect(plan.slots[1].durationSeconds, 20);
    });

    test('strict validation can fail structured plan', () {
      final json = {
        'openrtb': {
          'video': {
            'podid': 'pod-strict',
            'rqddurs': [15],
          },
        },
        'bids': [
          {
            'adm': OpenRtbTestFixtures.vastDocument([
              OpenRtbTestFixtures.vastAd(sequence: 1, durationSeconds: 30),
            ]),
            'slotinpod': 1,
            'duration': 30,
          },
          {
            'adm': OpenRtbTestFixtures.vastDocument([
              OpenRtbTestFixtures.vastAd(sequence: 2, durationSeconds: 40),
            ]),
            'slotinpod': 2,
            'duration': 40,
          },
        ],
      };
      final normalized = OpenRtbPoddedResponseNormalizer.normalize(json);
      final plan = PoddedPlaybackPlanBuilder.build(
        normalized!,
        OpenRtbTestFixtures.defaultConfig(
          validation: OpenRtbPodDurationValidationMode.strict,
        ),
      );
      expect(plan, isNull);
    });

    test('uses vast sequence sorting when slotinpod is absent', () {
      final json = {
        'openrtb': {
          'video': {'podid': 'seq-sort'},
        },
        'bids': [
          {
            'adm': OpenRtbTestFixtures.vastDocument([
              OpenRtbTestFixtures.vastAd(
                sequence: 2,
                durationSeconds: 20,
                id: 'b',
              ),
            ]),
          },
          {
            'adm': OpenRtbTestFixtures.vastDocument([
              OpenRtbTestFixtures.vastAd(
                sequence: 1,
                durationSeconds: 15,
                id: 'a',
              ),
            ]),
          },
        ],
      };
      final normalized = OpenRtbPoddedResponseNormalizer.normalize(json);
      final plan = PoddedPlaybackPlanBuilder.build(
        normalized!,
        OpenRtbTestFixtures.defaultConfig(),
      );
      expect(plan!.slots.first.durationSeconds, 15);
      expect(plan.slots.last.durationSeconds, 20);
    });
  });
}
