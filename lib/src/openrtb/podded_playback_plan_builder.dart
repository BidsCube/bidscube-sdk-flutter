import '../core/logger.dart';
import '../core/sdk_config.dart';
import 'openrtb_pod_models.dart';
import 'vast_ad_sequence_parser.dart';

/// Builds ordered playback plans from normalized OpenRTB pod responses.
class PoddedPlaybackPlanBuilder {
  PoddedPlaybackPlanBuilder._();

  static VideoPlaybackPlan? build(
    OpenRtbPoddedResponse response,
    SDKConfig? config,
  ) {
    final validationMode =
        config?.videoPodDurationValidationMode ??
        OpenRtbPodDurationValidationMode.lenient;
    final sorted = _sortMarkups(response.markups);
    var podType = response.podContext.type;

    SDKLogger.info(
      'Building playback plan: podType=$podType, markups=${sorted.length}',
    );

    var candidates = sorted.expand(_makeCandidates).toList(growable: false);
    if (candidates.isEmpty) {
      SDKLogger.warning('No playable candidates after markup inspection');
      return null;
    }

    if (candidates.length > 1 && podType == OpenRtbPodType.single) {
      podType = OpenRtbPodType.structured;
      candidates = _sortCandidates(candidates);
      SDKLogger.debug(
        'Expanded multi-ad markup into ${candidates.length} candidates',
      );
    }

    switch (podType) {
      case OpenRtbPodType.single:
        candidates = candidates.take(1).toList(growable: false);
      case OpenRtbPodType.unknown:
        candidates = _sortCandidates(candidates);
      case OpenRtbPodType.structured:
        candidates = _applyStructuredSelection(
          candidates,
          response.podContext,
          validationMode,
        );
      case OpenRtbPodType.dynamic:
        candidates = _applyDynamicSelection(
          candidates,
          response.podContext,
          validationMode,
        );
      case OpenRtbPodType.hybrid:
        candidates = _applyHybridSelection(
          candidates,
          response.podContext,
          validationMode,
        );
    }

    if (candidates.isEmpty) {
      if (validationMode == OpenRtbPodDurationValidationMode.strict) {
        SDKLogger.warning('Strict validation removed all pod slots');
      }
      return null;
    }

    if (response.podContext.maxSeq != null &&
        candidates.length > response.podContext.maxSeq!) {
      SDKLogger.debug('Trimming to maxseq=${response.podContext.maxSeq}');
      candidates = candidates
          .take(response.podContext.maxSeq!)
          .toList(growable: false);
    }

    final slots = candidates
        .asMap()
        .entries
        .map(
          (entry) => VideoPlaybackSlot(
            adm: entry.value.adm,
            adTagUrl: entry.value.adTagUrl,
            vastXml: entry.value.vastXml,
            slotIndex: entry.key,
            slotInPod: entry.value.slotInPod,
            durationSeconds: entry.value.durationSeconds,
          ),
        )
        .toList(growable: false);

    SDKLogger.info('Selected ${slots.length} playback slot(s)');

    final context = OpenRtbPodContext(
      podId: response.podContext.podId,
      podSeq: response.podContext.podSeq,
      podDurSeconds: response.podContext.podDurSeconds,
      rqddursSeconds: response.podContext.rqddursSeconds,
      maxSeq: response.podContext.maxSeq,
      minCpmPerSec: response.podContext.minCpmPerSec,
      type: podType,
    );

    return VideoPlaybackPlan(podContext: context, slots: slots);
  }

  static List<OpenRtbAdMarkup> _sortMarkups(List<OpenRtbAdMarkup> markups) {
    final indexed = markups.asMap().entries.toList();
    indexed.sort((lhs, rhs) {
      final leftSlot = lhs.value.slotInPod ?? 0x7fffffff;
      final rightSlot = rhs.value.slotInPod ?? 0x7fffffff;
      if (leftSlot != rightSlot) {
        return leftSlot.compareTo(rightSlot);
      }
      final leftSeq = lhs.value.vastSequence ?? 0x7fffffff;
      final rightSeq = rhs.value.vastSequence ?? 0x7fffffff;
      if (leftSeq != rightSeq) {
        return leftSeq.compareTo(rightSeq);
      }
      return lhs.value.responseOrder.compareTo(rhs.value.responseOrder);
    });
    return indexed.map((e) => e.value).toList(growable: false);
  }

  static List<_Candidate> _makeCandidates(OpenRtbAdMarkup markup) {
    final trimmed = markup.adm.trim();
    if (trimmed.isEmpty) {
      return const [];
    }

    if (VastAdSequenceParser.isAdTagUrl(trimmed)) {
      return [
        _Candidate(
          adm: trimmed,
          adTagUrl: trimmed,
          vastXml: null,
          slotInPod: markup.slotInPod,
          vastSequence: markup.vastSequence,
          durationSeconds: markup.durationSeconds,
          responseOrder: markup.responseOrder,
        ),
      ];
    }

    if (VastAdSequenceParser.contentLikelyContainsVast(trimmed)) {
      final adNodes = VastAdSequenceParser.extractAdNodes(trimmed);
      if (adNodes.length > 1) {
        SDKLogger.debug(
          'Single ADM contains ${adNodes.length} VAST ads; using VAST sequence fallback',
        );
        return adNodes
            .asMap()
            .entries
            .map((entry) {
              final node = entry.value;
              return _Candidate(
                adm: node,
                adTagUrl: null,
                vastXml: node,
                slotInPod: null,
                vastSequence:
                    VastAdSequenceParser.firstAdSequence(node) ??
                    (entry.key + 1),
                durationSeconds:
                    VastAdSequenceParser.firstLinearDurationSeconds(node),
                responseOrder: markup.responseOrder + entry.key,
              );
            })
            .toList(growable: false);
      }

      return [
        _Candidate(
          adm: trimmed,
          adTagUrl: null,
          vastXml: trimmed,
          slotInPod: markup.slotInPod,
          vastSequence:
              markup.vastSequence ??
              VastAdSequenceParser.firstAdSequence(trimmed),
          durationSeconds:
              markup.durationSeconds ??
              VastAdSequenceParser.firstLinearDurationSeconds(trimmed),
          responseOrder: markup.responseOrder,
        ),
      ];
    }

    return const [];
  }

  static List<_Candidate> _applyStructuredSelection(
    List<_Candidate> candidates,
    OpenRtbPodContext context,
    OpenRtbPodDurationValidationMode mode,
  ) {
    if (context.rqddursSeconds.isEmpty) {
      return candidates;
    }
    return candidates
        .where((candidate) {
          final duration = candidate.durationSeconds;
          if (duration == null) {
            return mode == OpenRtbPodDurationValidationMode.lenient;
          }
          final matches = context.rqddursSeconds.contains(duration);
          if (!matches) {
            SDKLogger.warning(
              'Slot duration ${duration}s not in rqddurs ${context.rqddursSeconds}',
            );
          }
          return mode == OpenRtbPodDurationValidationMode.lenient
              ? true
              : matches;
        })
        .toList(growable: false);
  }

  static List<_Candidate> _applyDynamicSelection(
    List<_Candidate> candidates,
    OpenRtbPodContext context,
    OpenRtbPodDurationValidationMode mode,
  ) {
    final budget = context.podDurSeconds;
    if (budget == null) {
      return candidates;
    }

    var remaining = budget;
    final selected = <_Candidate>[];

    for (final candidate in candidates) {
      final duration = candidate.durationSeconds;
      if (duration == null) {
        if (mode == OpenRtbPodDurationValidationMode.lenient) {
          selected.add(candidate);
        }
        continue;
      }
      if (duration > budget) {
        SDKLogger.warning(
          'Skipping slot duration ${duration}s exceeding poddur ${budget}s',
        );
        continue;
      }
      if (duration <= remaining) {
        selected.add(candidate);
        remaining -= duration;
      } else if (mode == OpenRtbPodDurationValidationMode.lenient) {
        SDKLogger.debug(
          'Slot duration ${duration}s exceeds remaining budget ${remaining}s',
        );
      }
      if (remaining <= 0) {
        break;
      }
    }

    return selected;
  }

  static List<_Candidate> _applyHybridSelection(
    List<_Candidate> candidates,
    OpenRtbPodContext context,
    OpenRtbPodDurationValidationMode mode,
  ) {
    final fixed = candidates.where((c) => c.slotInPod != null).toList();
    final dynamicPool = candidates.where((c) => c.slotInPod == null).toList();
    var selected = List<_Candidate>.from(
      _applyStructuredSelection(fixed, context, mode),
    );

    final budget = context.podDurSeconds;
    if (budget == null) {
      return _sortCandidates([...selected, ...dynamicPool]);
    }

    final used = selected
        .map((c) => c.durationSeconds)
        .whereType<int>()
        .fold<int>(0, (sum, value) => sum + value);
    var remaining = budget - used;
    if (remaining < 0) {
      remaining = 0;
    }

    for (final candidate in dynamicPool) {
      final duration = candidate.durationSeconds;
      if (duration == null) {
        if (mode == OpenRtbPodDurationValidationMode.lenient) {
          selected.add(candidate);
        }
        continue;
      }
      if (duration <= remaining) {
        selected.add(candidate);
        remaining -= duration;
      }
      if (remaining <= 0) {
        break;
      }
    }

    return _sortCandidates(selected);
  }

  static List<_Candidate> _sortCandidates(List<_Candidate> candidates) {
    final indexed = candidates.asMap().entries.toList();
    indexed.sort((lhs, rhs) {
      final leftSlot = lhs.value.slotInPod ?? 0x7fffffff;
      final rightSlot = rhs.value.slotInPod ?? 0x7fffffff;
      if (leftSlot != rightSlot) {
        return leftSlot.compareTo(rightSlot);
      }
      final leftSeq = lhs.value.vastSequence ?? 0x7fffffff;
      final rightSeq = rhs.value.vastSequence ?? 0x7fffffff;
      if (leftSeq != rightSeq) {
        return leftSeq.compareTo(rightSeq);
      }
      return lhs.value.responseOrder.compareTo(rhs.value.responseOrder);
    });
    return indexed.map((e) => e.value).toList(growable: false);
  }
}

class _Candidate {
  const _Candidate({
    required this.adm,
    required this.adTagUrl,
    required this.vastXml,
    required this.slotInPod,
    required this.vastSequence,
    required this.durationSeconds,
    required this.responseOrder,
  });

  final String adm;
  final String? adTagUrl;
  final String? vastXml;
  final int? slotInPod;
  final int? vastSequence;
  final int? durationSeconds;
  final int responseOrder;
}
