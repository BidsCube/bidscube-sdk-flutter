import 'package:http/http.dart' as http;

import 'logger.dart';
import 'vast_parser.dart';

/// Fires VAST companion tracking pixels (view + click).
class CompanionTracking {
  CompanionTracking({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final Set<String> _firedViewUrls = {};

  Future<void> fireViewTracking(VastCompanionCreative? companion) async {
    if (companion == null) return;
    for (final url in companion.viewTrackingUrls) {
      if (!_firedViewUrls.add(url)) continue;
      await _fire(url, label: 'companion view');
    }
  }

  Future<void> fireClickTracking(VastCompanionCreative? companion) async {
    if (companion == null) return;
    for (final url in companion.clickTrackingUrls) {
      await _fire(url, label: 'companion click');
    }
  }

  Future<void> _fire(String url, {required String label}) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await _client.get(uri).timeout(const Duration(seconds: 10));
      SDKLogger.info('Companion tracking ($label): $url');
    } catch (e) {
      SDKLogger.warning('Companion tracking failed ($label): $url — $e');
    }
  }
}
