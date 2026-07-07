import 'dart:convert';

import '../core/ad_position.dart';
import '../core/logger.dart';
import '../core/sdk_config.dart';
import 'openrtb_podded_response_normalizer.dart';
import 'podded_playback_plan_builder.dart';
import 'openrtb_pod_models.dart';
import 'openrtb_video_object_parser.dart';
import 'vast_ad_sequence_parser.dart';
import 'vast_pod_composer.dart';

/// Resolves video ad payloads from legacy JSON, OpenRTB pods, or raw VAST.
class ResolvedVideoAdPayload {
  const ResolvedVideoAdPayload({
    this.playbackPlan,
    this.adsResponse,
    this.adTagUrl,
    this.vastXml,
    this.position = AdPosition.unknown,
  });

  final VideoPlaybackPlan? playbackPlan;
  final String? adsResponse;
  final String? adTagUrl;
  final String? vastXml;
  final AdPosition position;
}

class VideoAdPayloadResolver {
  VideoAdPayloadResolver._();

  static ResolvedVideoAdPayload? resolve({
    required String content,
    SDKConfig? config,
  }) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    if (trimmed.startsWith('{')) {
      try {
        final decoded = json.decode(trimmed);
        if (decoded is Map<String, dynamic>) {
          return _resolveJson(decoded, config);
        }
      } catch (_) {
        // Fall through to raw VAST handling.
      }
    }

    if (VastAdSequenceParser.contentLikelyContainsVast(trimmed)) {
      SDKLogger.debug('Resolved raw VAST XML payload');
      return ResolvedVideoAdPayload(adsResponse: trimmed, vastXml: trimmed);
    }

    return null;
  }

  static ResolvedVideoAdPayload? _resolveJson(
    Map<String, dynamic> json,
    SDKConfig? config,
  ) {
    final position = _parsePosition(json);

    final openRtbEnabled = config?.openRtbPodMetadataEnabled ?? true;
    if (openRtbEnabled && OpenRtbPoddedResponseNormalizer.isOpenRtbLike(json)) {
      final podded = OpenRtbPoddedResponseNormalizer.normalize(json);
      if (podded != null) {
        final plan = PoddedPlaybackPlanBuilder.build(podded, config);
        if (plan != null && plan.isPlayable) {
          SDKLogger.info(
            'Resolved OpenRTB podded playback plan with ${plan.slots.length} slot(s)',
          );
          return _resolvePlan(plan, position);
        }
      }
    }

    final legacy = _resolveLegacyJson(json, position);
    if (legacy != null) {
      SDKLogger.debug('Resolved legacy JSON ADM/VAST payload');
      return legacy;
    }

    return null;
  }

  static ResolvedVideoAdPayload? _resolvePlan(
    VideoPlaybackPlan plan,
    AdPosition position,
  ) {
    final first = plan.slots.first;

    if (plan.slots.length == 1) {
      if (first.adTagUrl != null) {
        return ResolvedVideoAdPayload(
          playbackPlan: plan,
          adTagUrl: first.adTagUrl,
          vastXml: first.vastXml,
          position: position,
        );
      }
      if (first.vastXml != null) {
        return ResolvedVideoAdPayload(
          playbackPlan: plan,
          adsResponse: first.vastXml,
          vastXml: first.vastXml,
          position: position,
        );
      }
      return null;
    }

    final composed = VastPodComposer.compose(plan.slots);
    if (composed != null) {
      if (VastAdSequenceParser.isAdTagUrl(composed)) {
        return ResolvedVideoAdPayload(
          playbackPlan: plan,
          adTagUrl: composed,
          position: position,
        );
      }
      return ResolvedVideoAdPayload(
        playbackPlan: plan,
        adsResponse: composed,
        vastXml: composed,
        position: position,
      );
    }

    SDKLogger.warning('Pod composition failed; falling back to first slot');
    return _resolvePlan(
      VideoPlaybackPlan(podContext: plan.podContext, slots: [first]),
      position,
    );
  }

  static ResolvedVideoAdPayload? _resolveLegacyJson(
    Map<String, dynamic> json,
    AdPosition position,
  ) {
    final adm = OpenRtbVideoObjectParser.stringValue(json['adm']);
    if (adm == null) {
      return null;
    }

    if (VastAdSequenceParser.isAdTagUrl(adm)) {
      return ResolvedVideoAdPayload(adTagUrl: adm, position: position);
    }

    if (VastAdSequenceParser.contentLikelyContainsVast(adm)) {
      return ResolvedVideoAdPayload(
        adsResponse: adm,
        vastXml: adm,
        position: position,
      );
    }

    return null;
  }

  static AdPosition _parsePosition(Map<String, dynamic> json) {
    final positionValue = OpenRtbVideoObjectParser.intValue(json['position']);
    if (positionValue == null) {
      return AdPosition.unknown;
    }
    return AdPositionExtension.fromValue(positionValue);
  }
}
