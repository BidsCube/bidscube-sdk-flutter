import 'dart:convert';

import 'logger.dart';

/// Normalizes server `adm` payloads into renderable markup (HTML, URLs, etc.).
class AdmMarkupExtractor {
  /// Reads and normalizes `adm` from a parsed ad response map.
  static String admFromResponse(Map<String, dynamic> adData) {
    return normalizeAdm(adData['adm']);
  }

  /// Coerces dynamic `adm` values (String, Map, nested JSON) to render markup.
  static String normalizeAdm(dynamic value) {
    if (value == null) return '';
    if (value is Map<String, dynamic>) {
      if (value.containsKey('adm')) {
        return extractRenderMarkup(normalizeAdm(value['adm']));
      }
      return json.encode(value);
    }
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      if (map.containsKey('adm')) {
        return extractRenderMarkup(normalizeAdm(map['adm']));
      }
      return json.encode(map);
    }
    if (value is String) {
      return extractRenderMarkup(value);
    }
    return extractRenderMarkup(value.toString());
  }

  /// Unwraps JSON/`document.write` envelopes and returns creative markup only.
  static String extractRenderMarkup(String raw) {
    var content = raw.trim();
    if (content.isEmpty) return content;

    content = _unwrapJsonAdmEnvelope(content);

    if (content.contains('document.write(')) {
      content = _extractFromDocumentWrite(content);
    }

    content = _cleanupAdContent(content);
    content = _stripEmbeddedAdmJsonLiteral(content);

    return content;
  }

  static String _unwrapJsonAdmEnvelope(String content) {
    final trimmed = content.trim();
    if (!trimmed.startsWith('{') || !trimmed.contains('"adm"')) {
      return content;
    }

    try {
      final decoded = json.decode(trimmed);
      if (decoded is Map && decoded['adm'] != null) {
        final inner = decoded['adm'];
        if (inner is String) {
          return inner.trim();
        }
        return inner.toString();
      }
    } catch (_) {
      // Loose `{ "adm": ... }` envelopes (e.g. unquoted document.write) below.
    }

    final loose = RegExp(r'^\s*\{\s*"adm"\s*:\s*', dotAll: true).firstMatch(
      trimmed,
    );
    if (loose != null) {
      var inner = trimmed.substring(loose.end).trimRight();
      if (inner.endsWith('}')) {
        inner = inner.substring(0, inner.length - 1).trim();
      }
      SDKLogger.info('Unwrapped loose JSON adm envelope');
      return inner;
    }

    return content;
  }

  static String _extractFromDocumentWrite(String adm) {
    try {
      var content = adm.trim();

      if (content.startsWith('document.write(') && content.endsWith(');')) {
        content = content.substring(
          'document.write('.length,
          content.length - 2,
        );
        content = _unescapeHtml(content.trim());
        SDKLogger.info('Extracted HTML from document.write (unquoted)');
        return content;
      }

      final writeRegex = RegExp(
        r'document\.write\s*\(\s*['
        "\"'"
        r'](.+?)['
        "\"'"
        r']\s*\)\s*;?\s*$',
        dotAll: true,
      );
      final match = writeRegex.firstMatch(content);
      if (match != null) {
        content = _unescapeHtml(match.group(1) ?? content);
        SDKLogger.info('Extracted HTML from document.write (quoted)');
        return content;
      }

      return adm;
    } catch (e) {
      SDKLogger.error('Error extracting from document.write', e);
      return adm;
    }
  }

  static String _unescapeHtml(String content) {
    return content
        .replaceAll(r'\"', '"')
        .replaceAll(r"\'", "'")
        .replaceAll(r'\/', '/')
        .replaceAll(r'\\n', '\n')
        .replaceAll(r'\\t', '\t')
        .replaceAll(r'\\', '\\');
  }

  static String _cleanupAdContent(String content) {
    final urlBeforeScriptRegex = RegExp(
      r'(<span[^>]*>)(https?://[^\s<>"\\]+)(\\+)(<script)',
      caseSensitive: false,
    );

    return content.replaceAllMapped(urlBeforeScriptRegex, (match) {
      return '${match.group(1)}${match.group(4)}';
    });
  }

  /// Removes server-embedded JSON text nodes such as `{ "adm": "<html>..." }`
  /// that appear inside banner markup and render as visible text in WebView.
  static String _stripEmbeddedAdmJsonLiteral(String content) {
    var result = content;

    final embeddedJsonPrefix = RegExp(
      r'\{\s*"adm"\s*:\s*"',
      multiLine: true,
      caseSensitive: false,
    );
    result = result.replaceAll(embeddedJsonPrefix, '');

    final embeddedJsonSuffix = RegExp(
      r'"\s*\}\s*(?=<script\b)',
      caseSensitive: false,
      dotAll: true,
    );
    result = result.replaceAll(embeddedJsonSuffix, '');

    return result;
  }
}
