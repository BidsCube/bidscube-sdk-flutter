import 'package:xml/xml.dart';

/// Parses VAST ad sequence and duration metadata from inline XML.
class VastAdSequenceParser {
  VastAdSequenceParser._();

  static bool contentLikelyContainsVast(String content) {
    return RegExp(r'<VAST', caseSensitive: false).hasMatch(content);
  }

  static bool isAdTagUrl(String adm) {
    final trimmed = adm.trim();
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }

  static int? firstAdSequence(String vastXml) {
    final match = RegExp(
      r'<Ad[^>]*>',
      caseSensitive: false,
    ).firstMatch(vastXml);
    if (match == null) {
      return null;
    }
    return _sequenceFromAdTag(match.group(0)!);
  }

  static int? firstLinearDurationSeconds(String vastXml) {
    final match = RegExp(
      r'<Duration[^>]*>([\s\S]*?)</Duration>',
      caseSensitive: false,
    ).firstMatch(vastXml);
    if (match == null) {
      return null;
    }
    return parseVastDurationToSeconds(_cleanText(match.group(1)!));
  }

  static List<String> extractAdNodes(String vastXml) {
    try {
      final document = XmlDocument.parse(vastXml);
      return document
          .findAllElements('Ad')
          .map((node) => node.toXmlString())
          .toList(growable: false);
    } catch (_) {
      final matches = RegExp(
        r'<Ad[^>]*>[\s\S]*?</Ad>',
        caseSensitive: false,
      ).allMatches(vastXml);
      return matches.map((m) => m.group(0)!).toList(growable: false);
    }
  }

  static String wrapInVastDocumentIfNeeded(String content) {
    if (contentLikelyContainsVast(content)) {
      return content;
    }
    return '<VAST version="3.0">\n$content\n</VAST>';
  }

  static String assignSequence(String adNode, int sequence) {
    if (RegExp(
      r'sequence\s*=\s*"[^"]*"',
      caseSensitive: false,
    ).hasMatch(adNode)) {
      return adNode.replaceAll(
        RegExp(r'sequence\s*=\s*"[^"]*"', caseSensitive: false),
        'sequence="$sequence"',
      );
    }
    final adIndex = adNode.toLowerCase().indexOf('<ad');
    if (adIndex >= 0) {
      final insertAt = adIndex + 3;
      return '${adNode.substring(0, insertAt)} sequence="$sequence"${adNode.substring(insertAt)}';
    }
    return adNode;
  }

  static int? parseVastDurationToSeconds(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (trimmed.contains(':')) {
      final parts = trimmed.split(':');
      if (parts.length == 3) {
        final hours = int.tryParse(parts[0].trim()) ?? 0;
        final minutes = int.tryParse(parts[1].trim()) ?? 0;
        final secondsPart = parts[2].trim();
        final seconds = double.tryParse(secondsPart);
        if (seconds != null && seconds.isFinite) {
          return (hours * 3600 + minutes * 60 + seconds).round();
        }
      }
      return null;
    }
    final asDouble = double.tryParse(trimmed);
    if (asDouble != null && asDouble.isFinite) {
      return asDouble.round();
    }
    return int.tryParse(trimmed);
  }

  static int? _sequenceFromAdTag(String adTag) {
    final match = RegExp(
      r'sequence\s*=\s*"([^"]+)"',
      caseSensitive: false,
    ).firstMatch(adTag);
    if (match == null) {
      return null;
    }
    return int.tryParse(match.group(1)!.trim());
  }

  static String _cleanText(String raw) {
    var value = raw.trim();
    if (value.startsWith('<![CDATA[') && value.endsWith(']]>')) {
      value = value.substring(9, value.length - 3);
    }
    return value.trim();
  }
}
