import '../core/logger.dart';
import 'openrtb_pod_models.dart';
import 'openrtb_video_object_parser.dart';
import 'vast_ad_sequence_parser.dart';

/// Normalizes OpenRTB-like JSON responses into pod markup models.
class OpenRtbPoddedResponseNormalizer {
  OpenRtbPoddedResponseNormalizer._();

  static bool isOpenRtbLike(Map<String, dynamic> root) {
    if (OpenRtbVideoObjectParser.findVideoObject(root) != null) {
      return true;
    }
    if (root['bids'] is List) {
      return true;
    }
    if (root['seatbid'] is List) {
      return true;
    }
    return false;
  }

  static OpenRtbPoddedResponse? normalize(Map<String, dynamic> root) {
    final videoObject = OpenRtbVideoObjectParser.findVideoObject(root);
    var markups = _collectMarkups(root, videoObject);

    if (markups.isEmpty) {
      final rootAdm = _usableAdm(root['adm']);
      if (rootAdm != null) {
        markups = [
          _makeMarkup(
            adm: rootAdm,
            bid: root,
            ext: null,
            videoObject: videoObject,
            order: 0,
          ),
        ];
      }
    }

    markups = markups.where((m) => _isUsableAdm(m.adm)).toList(growable: false);
    if (markups.isEmpty) {
      SDKLogger.debug('No usable ADM in OpenRTB-like response');
      return null;
    }

    markups = _dedupePodGroups(markups);
    final podContext = _buildPodContext(root, videoObject, markups);

    SDKLogger.info(
      'Parsed OpenRTB response: ${markups.length} bid(s), podId=${podContext.podId ?? 'nil'}',
    );
    return OpenRtbPoddedResponse(podContext: podContext, markups: markups);
  }

  static List<OpenRtbAdMarkup> _collectMarkups(
    Map<String, dynamic> root,
    Map<String, dynamic>? videoObject,
  ) {
    final results = <OpenRtbAdMarkup>[];
    var order = 0;

    final bids = root['bids'];
    if (bids is List) {
      SDKLogger.debug('Detected root bids[] shape');
      for (final item in bids) {
        final bid = OpenRtbVideoObjectParser.dictionaryValue(item);
        if (bid == null) {
          continue;
        }
        final adm = _usableAdm(bid['adm']);
        if (adm == null) {
          continue;
        }
        results.add(
          _makeMarkup(
            adm: adm,
            bid: bid,
            ext: null,
            videoObject: videoObject,
            order: order,
          ),
        );
        order++;
      }
    }

    final seatbid = root['seatbid'];
    if (seatbid is List) {
      SDKLogger.debug('Detected seatbid[].bid[] shape');
      for (final seatItem in seatbid) {
        final seat = OpenRtbVideoObjectParser.dictionaryValue(seatItem);
        final seatBids = seat?['bid'];
        if (seatBids is! List) {
          continue;
        }
        for (final bidItem in seatBids) {
          final bid = OpenRtbVideoObjectParser.dictionaryValue(bidItem);
          if (bid == null) {
            continue;
          }
          final adm = _usableAdm(bid['adm']);
          if (adm == null) {
            continue;
          }
          final ext = OpenRtbVideoObjectParser.dictionaryValue(bid['ext']);
          results.add(
            _makeMarkup(
              adm: adm,
              bid: bid,
              ext: ext,
              videoObject: videoObject,
              order: order,
            ),
          );
          order++;
        }
      }
    }

    return results;
  }

  static OpenRtbAdMarkup _makeMarkup({
    required String adm,
    required Map<String, dynamic> bid,
    required Map<String, dynamic>? ext,
    required Map<String, dynamic>? videoObject,
    required int order,
  }) {
    final mergedExt =
        ext ?? OpenRtbVideoObjectParser.dictionaryValue(bid['ext']);

    final slotInPod =
        OpenRtbVideoObjectParser.intValue(bid['slotinpod']) ??
        OpenRtbVideoObjectParser.intValue(bid['slotInPod']) ??
        OpenRtbVideoObjectParser.intValue(mergedExt?['slotinpod']) ??
        OpenRtbVideoObjectParser.intValue(mergedExt?['slotInPod']);

    final duration =
        OpenRtbVideoObjectParser.intValue(bid['duration']) ??
        OpenRtbVideoObjectParser.intValue(mergedExt?['duration']) ??
        (VastAdSequenceParser.contentLikelyContainsVast(adm)
            ? VastAdSequenceParser.firstLinearDurationSeconds(adm)
            : null);

    final podId =
        OpenRtbVideoObjectParser.stringValue(bid['podid']) ??
        OpenRtbVideoObjectParser.stringValue(bid['podId']) ??
        OpenRtbVideoObjectParser.stringValue(mergedExt?['podid']) ??
        OpenRtbVideoObjectParser.stringValue(videoObject?['podid']) ??
        OpenRtbVideoObjectParser.stringValue(videoObject?['podId']);

    final podSeq =
        OpenRtbVideoObjectParser.intValue(bid['podseq']) ??
        OpenRtbVideoObjectParser.intValue(bid['podSeq']) ??
        OpenRtbVideoObjectParser.intValue(mergedExt?['podseq']) ??
        OpenRtbVideoObjectParser.intValue(videoObject?['podseq']);

    final vastSequence = VastAdSequenceParser.contentLikelyContainsVast(adm)
        ? VastAdSequenceParser.firstAdSequence(adm)
        : null;

    final rawBid = Map<String, dynamic>.from(bid);
    if (mergedExt != null) {
      rawBid['ext'] = mergedExt;
    }

    return OpenRtbAdMarkup(
      adm: adm,
      adId: OpenRtbVideoObjectParser.stringValue(bid['id']),
      crid: OpenRtbVideoObjectParser.stringValue(bid['crid']),
      price: OpenRtbVideoObjectParser.doubleValue(bid['price']),
      podId: podId,
      podSeq: podSeq,
      slotInPod: slotInPod,
      durationSeconds: duration,
      vastSequence: vastSequence,
      rawBid: rawBid,
      responseOrder: order,
    );
  }

  static OpenRtbPodContext _buildPodContext(
    Map<String, dynamic> root,
    Map<String, dynamic>? videoObject,
    List<OpenRtbAdMarkup> markups,
  ) {
    final video = videoObject ?? const <String, dynamic>{};
    final podId =
        OpenRtbVideoObjectParser.stringValue(video['podid']) ??
        OpenRtbVideoObjectParser.stringValue(video['podId']) ??
        markups.map((m) => m.podId).whereType<String>().firstOrNull;

    final podSeq =
        OpenRtbVideoObjectParser.intValue(video['podseq']) ??
        OpenRtbVideoObjectParser.intValue(video['podSeq']) ??
        markups.map((m) => m.podSeq).whereType<int>().firstOrNull;

    final podDur =
        OpenRtbVideoObjectParser.intValue(video['poddur']) ??
        OpenRtbVideoObjectParser.intValue(video['podDur']);

    final rqddursPrimary = OpenRtbVideoObjectParser.intArrayValue(
      video['rqddurs'],
    );
    final rqddurs = rqddursPrimary.isEmpty
        ? OpenRtbVideoObjectParser.intArrayValue(video['rqdDurs'])
        : rqddursPrimary;

    final maxSeq =
        OpenRtbVideoObjectParser.intValue(video['maxseq']) ??
        OpenRtbVideoObjectParser.intValue(video['maxSeq']);

    final minCpm =
        OpenRtbVideoObjectParser.doubleValue(video['mincpmpersec']) ??
        OpenRtbVideoObjectParser.doubleValue(video['minCpmPerSec']);

    final hasFixedStructure =
        maxSeq != null ||
        rqddurs.isNotEmpty ||
        markups.any((m) => m.slotInPod != null);
    final hasDynamicBudget = podDur != null;

    final OpenRtbPodType type;
    if (markups.length <= 1) {
      type = OpenRtbPodType.single;
    } else if (hasFixedStructure && hasDynamicBudget) {
      type = OpenRtbPodType.hybrid;
    } else if (hasDynamicBudget && !hasFixedStructure) {
      type = OpenRtbPodType.dynamic;
    } else if (hasFixedStructure) {
      type = OpenRtbPodType.structured;
    } else {
      type = OpenRtbPodType.unknown;
    }

    return OpenRtbPodContext(
      podId: podId,
      podSeq: podSeq,
      podDurSeconds: podDur,
      rqddursSeconds: rqddurs,
      maxSeq: maxSeq,
      minCpmPerSec: minCpm,
      type: type,
    );
  }

  static List<OpenRtbAdMarkup> _dedupePodGroups(List<OpenRtbAdMarkup> markups) {
    final grouped = <String, List<OpenRtbAdMarkup>>{};
    for (final markup in markups) {
      final key = markup.podId ?? '__default__';
      grouped.putIfAbsent(key, () => []).add(markup);
    }
    if (grouped.length <= 1) {
      return markups;
    }
    final selectedKey = grouped.keys.toList()..sort();
    SDKLogger.warning(
      'Multiple pod groups detected; using podId=${selectedKey.first}',
    );
    return grouped[selectedKey.first] ?? markups;
  }

  static String? _usableAdm(dynamic value) {
    final string = OpenRtbVideoObjectParser.stringValue(value);
    if (string == null) {
      return null;
    }
    return _isUsableAdm(string) ? string : null;
  }

  static bool _isUsableAdm(String adm) {
    final trimmed = adm.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    return VastAdSequenceParser.isAdTagUrl(trimmed) ||
        VastAdSequenceParser.contentLikelyContainsVast(trimmed);
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) {
      return null;
    }
    return iterator.current;
  }
}
