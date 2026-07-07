/// Internal OpenRTB pod models for response-side parsing.
library;

enum OpenRtbPodType { single, structured, dynamic, hybrid, unknown }

class OpenRtbPodContext {
  const OpenRtbPodContext({
    this.podId,
    this.podSeq,
    this.podDurSeconds,
    this.rqddursSeconds = const [],
    this.maxSeq,
    this.minCpmPerSec,
    this.type = OpenRtbPodType.unknown,
  });

  final String? podId;
  final int? podSeq;
  final int? podDurSeconds;
  final List<int> rqddursSeconds;
  final int? maxSeq;
  final double? minCpmPerSec;
  final OpenRtbPodType type;
}

class OpenRtbAdMarkup {
  const OpenRtbAdMarkup({
    required this.adm,
    this.adId,
    this.crid,
    this.price,
    this.podId,
    this.podSeq,
    this.slotInPod,
    this.durationSeconds,
    this.vastSequence,
    this.rawBid = const {},
    this.responseOrder = 0,
  });

  final String adm;
  final String? adId;
  final String? crid;
  final double? price;
  final String? podId;
  final int? podSeq;
  final int? slotInPod;
  final int? durationSeconds;
  final int? vastSequence;
  final Map<String, dynamic> rawBid;
  final int responseOrder;
}

class OpenRtbPoddedResponse {
  const OpenRtbPoddedResponse({
    required this.podContext,
    required this.markups,
  });

  final OpenRtbPodContext podContext;
  final List<OpenRtbAdMarkup> markups;
}

class VideoPlaybackSlot {
  const VideoPlaybackSlot({
    required this.adm,
    this.adTagUrl,
    this.vastXml,
    required this.slotIndex,
    this.slotInPod,
    this.durationSeconds,
  });

  final String adm;
  final String? adTagUrl;
  final String? vastXml;
  final int slotIndex;
  final int? slotInPod;
  final int? durationSeconds;
}

class VideoPlaybackPlan {
  const VideoPlaybackPlan({this.podContext, required this.slots});

  final OpenRtbPodContext? podContext;
  final List<VideoPlaybackSlot> slots;

  bool get isPlayable => slots.isNotEmpty;
}
