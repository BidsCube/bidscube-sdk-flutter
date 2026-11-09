import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Detects Android TV / Fire TV / Apple TV for video display policy.
///
/// Leanback UI mode is represented by system features (`android.software.leanback`,
/// `android.hardware.type.television`). Apple TV is `AppleTV*` in `utsname.machine`
/// or a model string containing "Apple TV".
class TelevisionDetector {
  TelevisionDetector._();

  static bool? _cached;
  static DeviceInfoPlugin _plugin = DeviceInfoPlugin();

  /// Test hook.
  @visibleForTesting
  static void debugReset({DeviceInfoPlugin? plugin}) {
    _cached = null;
    if (plugin != null) _plugin = plugin;
  }

  static Future<bool> isTelevision() async {
    final cached = _cached;
    if (cached != null) return cached;
    final detected = await _detect();
    _cached = detected;
    return detected;
  }

  static Future<bool> _detect() async {
    if (kIsWeb) return false;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final info = await _plugin.androidInfo;
        return detectFromSignals(
          systemFeatures: info.systemFeatures,
          manufacturer: info.manufacturer,
          model: info.model,
        );
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final info = await _plugin.iosInfo;
        return detectFromSignals(
          iosMachine: info.utsname.machine,
          iosModel: info.model,
        );
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  @visibleForTesting
  static bool detectFromSignals({
    List<String> systemFeatures = const [],
    String manufacturer = '',
    String model = '',
    String iosMachine = '',
    String iosModel = '',
  }) {
    const tvFeatures = {
      'android.software.leanback',
      'android.hardware.type.television',
      'amazon.hardware.fire_tv',
    };
    for (final feature in systemFeatures) {
      if (tvFeatures.contains(feature)) return true;
    }
    if (manufacturer.trim().toLowerCase() == 'amazon' &&
        model.trim().toUpperCase().startsWith('AFT')) {
      return true;
    }
    final machine = iosMachine.toLowerCase();
    final ios = iosModel.toLowerCase();
    if (machine.startsWith('appletv') || ios.contains('apple tv')) {
      return true;
    }
    return false;
  }
}
