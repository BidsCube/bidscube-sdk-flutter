import 'vast_ad_sequence_parser.dart';

/// Finds and parses OpenRTB video objects from JSON envelopes.
class OpenRtbVideoObjectParser {
  OpenRtbVideoObjectParser._();

  static Map<String, dynamic>? findVideoObject(Map<String, dynamic> root) {
    for (final key in ['openrtb', 'openRtb']) {
      final container = dictionaryValue(root[key]);
      final video = dictionaryValue(container?['video']);
      if (video != null) {
        return video;
      }
    }
    return dictionaryValue(root['video']);
  }

  static int? intValue(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.isFinite ? value.toInt() : null;
    }
    if (value is num) {
      return value.isFinite ? value.toInt() : null;
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
      }
      if (trimmed.contains(':')) {
        return VastAdSequenceParser.parseVastDurationToSeconds(trimmed);
      }
      final asInt = int.tryParse(trimmed);
      if (asInt != null) {
        return asInt;
      }
      final asDouble = double.tryParse(trimmed);
      if (asDouble != null && asDouble.isFinite) {
        return asDouble.toInt();
      }
    }
    return null;
  }

  static double? doubleValue(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is double) {
      return value.isFinite ? value : null;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is num) {
      return value.isFinite ? value.toDouble() : null;
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
      }
      final parsed = double.tryParse(trimmed);
      return parsed != null && parsed.isFinite ? parsed : null;
    }
    return null;
  }

  static String? stringValue(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (value is int) {
      return value.toString();
    }
    if (value is double) {
      return value.toString();
    }
    if (value is num) {
      return value.toString();
    }
    return null;
  }

  static List<int> intArrayValue(dynamic value) {
    if (value is List) {
      return value.map(intValue).whereType<int>().toList(growable: false);
    }
    final single = intValue(value);
    if (single != null) {
      return [single];
    }
    return const [];
  }

  static Map<String, dynamic>? dictionaryValue(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }
}
