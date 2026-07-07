import '../core/logger.dart';
import 'openrtb_pod_models.dart';
import 'vast_ad_sequence_parser.dart';

/// Composes multiple inline VAST slots into one VAST document for IMA.
class VastPodComposer {
  VastPodComposer._();

  static String? compose(List<VideoPlaybackSlot> slots) {
    if (slots.isEmpty) {
      return null;
    }
    if (slots.length == 1) {
      final single = slots.first.vastXml ?? slots.first.adm;
      return VastAdSequenceParser.wrapInVastDocumentIfNeeded(single);
    }

    final urlSlots = slots.where((s) => s.adTagUrl != null).toList();
    final xmlSlots = slots.where((s) => s.vastXml != null).toList();

    if (urlSlots.isNotEmpty && xmlSlots.isNotEmpty) {
      SDKLogger.warning(
        'Mixed URL/XML pod composition unsupported; using first URL slot only',
      );
      return urlSlots.first.adTagUrl;
    }

    if (urlSlots.isNotEmpty) {
      SDKLogger.warning(
        'Multiple URL pod slots unsupported; using first URL slot only',
      );
      return urlSlots.first.adTagUrl;
    }

    final adNodes = <String>[];
    for (var index = 0; index < xmlSlots.length; index++) {
      final slot = xmlSlots[index];
      final vastXml = slot.vastXml;
      if (vastXml == null) {
        continue;
      }
      final nodes = VastAdSequenceParser.extractAdNodes(vastXml);
      if (nodes.isEmpty) {
        SDKLogger.warning('No <Ad> node in slot $index; skipping');
        continue;
      }
      for (final node in nodes) {
        final sequence = slot.slotInPod ?? (index + 1);
        adNodes.add(VastAdSequenceParser.assignSequence(node, sequence));
      }
    }

    if (adNodes.isEmpty) {
      SDKLogger.warning(
        'VAST pod composition failed; falling back to first slot',
      );
      return xmlSlots.first.vastXml ?? xmlSlots.first.adm;
    }

    return '<VAST version="3.0">\n${adNodes.join('\n')}\n</VAST>';
  }
}
