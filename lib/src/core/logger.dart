/// Logger for BidsCube SDK
class SDKLogger {
  static bool _isEnabled = true;
  static bool _isDebugMode = false;

  /// Enable or disable logging
  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Enable or disable debug mode
  static void setDebugMode(bool enabled) {
    _isDebugMode = enabled;
  }

  /// Log info message
  static void info(String message) {
    if (_isEnabled) {
      print('[BidsCube SDK] INFO: $message');
    }
  }

  /// Log debug message
  static void debug(String message) {
    if (_isEnabled && _isDebugMode) {
      print('[BidsCube SDK] DEBUG: $message');
    }
  }

  /// Log warning message
  static void warning(String message) {
    if (_isEnabled) {
      print('[BidsCube SDK] WARNING: $message');
    }
  }

  /// Log error message
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_isEnabled) {
      print('[BidsCube SDK] ERROR: $message');
      if (error != null) {
        print('[BidsCube SDK] Error details: $error');
      }
      if (stackTrace != null) {
        print('[BidsCube SDK] Stack trace: $stackTrace');
      }
    }
  }
}
