import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class AppLogger {
  static const bool _isDebugMode = kDebugMode;
  
  static void log(LogLevel level, String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (!_isDebugMode && level == LogLevel.debug) return;
    
    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase();
    final tagStr = tag != null ? '[$tag] ' : '';
    final logMessage = '$timestamp $levelStr $tagStr$message';
    
    switch (level) {
      case LogLevel.debug:
        debugPrint(logMessage);
        break;
      case LogLevel.info:
        debugPrint(logMessage);
        break;
      case LogLevel.warning:
        debugPrint('⚠️ $logMessage');
        break;
      case LogLevel.error:
        debugPrint('❌ $logMessage');
        if (error != null) {
          debugPrint('Error: $error');
        }
        if (stackTrace != null) {
          debugPrint('Stack trace: $stackTrace');
        }
        break;
    }
  }
  
  static void debug(String message, {String? tag}) {
    log(LogLevel.debug, message, tag: tag);
  }
  
  static void info(String message, {String? tag}) {
    log(LogLevel.info, message, tag: tag);
  }
  
  static void warning(String message, {String? tag}) {
    log(LogLevel.warning, message, tag: tag);
  }
  
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }
}
