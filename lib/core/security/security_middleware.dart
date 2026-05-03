// OWASP Security Middleware
// Provides centralized security controls for the application

import 'package:flutter/foundation.dart';
import 'input_sanitizer.dart';

/// Security headers for HTTP requests (when using custom HTTP clients)
class SecurityHeaders {
  /// Get standard security headers for API requests
  static Map<String, String> getStandardHeaders() {
    return {
      'X-Content-Type-Options': 'nosniff',
      'X-Frame-Options': 'DENY',
      'X-XSS-Protection': '1; mode=block',
      'Referrer-Policy': 'strict-origin-when-cross-origin',
      'Content-Security-Policy': "default-src 'self'",
    };
  }
}

/// Security middleware for request/response validation
class SecurityMiddleware {
  /// Validates that a request is safe before sending
  static bool validateRequest({
    required String endpoint,
    Map<String, dynamic>? params,
    String? body,
  }) {
    // Check for null bytes (potential buffer overflow attempts)
    if (body != null && body.contains('\x00')) {
      debugPrint('Security: Null bytes detected in request body');
      return false;
    }
    
    // Check URL length (prevent URL-based attacks)
    if (endpoint.length > 2048) {
      debugPrint('Security: URL too long');
      return false;
    }
    
    // Validate parameters
    if (params != null) {
      for (final entry in params.entries) {
        final value = entry.value.toString();
        
        // Check for suspicious patterns
        if (_containsSuspiciousPatterns(value)) {
          debugPrint('Security: Suspicious pattern in parameter: ${entry.key}');
          return false;
        }
      }
    }
    
    return true;
  }
  
  /// Check if string contains suspicious patterns
  static bool _containsSuspiciousPatterns(String value) {
    final suspiciousPatterns = [
      '../',           // Path traversal
      '..\\',          // Windows path traversal
      '%2e%2e%2f',     // URL encoded path traversal
      '\x00',          // Null bytes
      '<script',       // Script injection
      'javascript:',   // JavaScript protocol
      'data:text/html', // Data URI
    ];
    
    final lowerValue = value.toLowerCase();
    for (final pattern in suspiciousPatterns) {
      if (lowerValue.contains(pattern)) {
        return true;
      }
    }
    return false;
  }
  
  /// Sanitize all values in a map
  static Map<String, dynamic> sanitizeMap(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};
    
    for (final entry in data.entries) {
      final value = entry.value;
      
      if (value is String) {
        // Sanitize string values
        sanitized[entry.key] = InputSanitizer.sanitizeString(value);
      } else if (value is Map<String, dynamic>) {
        // Recursively sanitize nested maps
        sanitized[entry.key] = sanitizeMap(value);
      } else if (value is List) {
        // Sanitize list items
        sanitized[entry.key] = _sanitizeList(value);
      } else {
        // Keep other types as-is
        sanitized[entry.key] = value;
      }
    }
    
    return sanitized;
  }
  
  /// Sanitize list items
  static List<dynamic> _sanitizeList(List<dynamic> list) {
    return list.map((item) {
      if (item is String) {
        return InputSanitizer.sanitizeString(item);
      } else if (item is Map<String, dynamic>) {
        return sanitizeMap(item);
      }
      return item;
    }).toList();
  }
}

/// Security audit logging
class SecurityAudit {
  static final List<SecurityEvent> _events = [];
  static const int _maxEvents = 1000;
  
  /// Log a security event
  static void log({
    required String event,
    required String severity,
    String? userId,
    String? details,
  }) {
    final securityEvent = SecurityEvent(
      timestamp: DateTime.now(),
      event: event,
      severity: severity,
      userId: userId,
      details: details,
    );
    
    _events.add(securityEvent);
    
    // Keep only recent events to prevent memory issues
    if (_events.length > _maxEvents) {
      _events.removeAt(0);
    }
    
    // Log to console in debug mode
    if (kDebugMode) {
      debugPrint('[SECURITY] $severity: $event${details != null ? ' - $details' : ''}');
    }
  }
  
  /// Get all security events
  static List<SecurityEvent> getEvents() {
    return List.unmodifiable(_events);
  }
  
  /// Get events by severity
  static List<SecurityEvent> getEventsBySeverity(String severity) {
    return _events.where((e) => e.severity == severity).toList();
  }
  
  /// Clear all events
  static void clear() {
    _events.clear();
  }
}

/// Security event model
class SecurityEvent {
  final DateTime timestamp;
  final String event;
  final String severity;
  final String? userId;
  final String? details;
  
  SecurityEvent({
    required this.timestamp,
    required this.event,
    required this.severity,
    this.userId,
    this.details,
  });
  
  @override
  String toString() {
    return 'SecurityEvent(${timestamp.toIso8601String()}, $severity: $event)';
  }
}

/// Content Security Policy helper
class ContentSecurityPolicy {
  /// Build a CSP header value
  static String buildPolicy({
    List<String> defaultSrc = const ["'self'"],
    List<String> scriptSrc = const ["'self'"],
    List<String> styleSrc = const ["'self'", "'unsafe-inline'"],
    List<String> imgSrc = const ["'self'", "data:", "blob:"],
    List<String> connectSrc = const ["'self'"],
    List<String> fontSrc = const ["'self'"],
    List<String> objectSrc = const ["'none'"],
    List<String> mediaSrc = const ["'self'"],
    List<String> frameSrc = const ["'none'"],
  }) {
    final directives = <String>[];
    
    if (defaultSrc.isNotEmpty) directives.add("default-src ${defaultSrc.join(' ')}");
    if (scriptSrc.isNotEmpty) directives.add("script-src ${scriptSrc.join(' ')}");
    if (styleSrc.isNotEmpty) directives.add("style-src ${styleSrc.join(' ')}");
    if (imgSrc.isNotEmpty) directives.add("img-src ${imgSrc.join(' ')}");
    if (connectSrc.isNotEmpty) directives.add("connect-src ${connectSrc.join(' ')}");
    if (fontSrc.isNotEmpty) directives.add("font-src ${fontSrc.join(' ')}");
    if (objectSrc.isNotEmpty) directives.add("object-src ${objectSrc.join(' ')}");
    if (mediaSrc.isNotEmpty) directives.add("media-src ${mediaSrc.join(' ')}");
    if (frameSrc.isNotEmpty) directives.add("frame-src ${frameSrc.join(' ')}");
    
    return directives.join('; ');
  }
}

/// Secure storage helper for sensitive data
class SecureStorageHelper {
  /// Mask sensitive data for logging
  static String maskSensitiveData(String data, {int visibleChars = 4}) {
    if (data.length <= visibleChars * 2) {
      return '*' * data.length;
    }
    return '${data.substring(0, visibleChars)}${'*' * (data.length - visibleChars * 2)}${data.substring(data.length - visibleChars)}';
  }
  
  /// Mask email for display
  static String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return maskSensitiveData(email);
    
    final localPart = parts[0];
    final domain = parts[1];
    
    if (localPart.length <= 2) {
      return '${'*' * localPart.length}@$domain';
    }
    
    return '${localPart.substring(0, 2)}${'*' * (localPart.length - 2)}@$domain';
  }
  
  /// Validate file upload
  static bool validateFileUpload({
    required String fileName,
    required int fileSize,
    List<String> allowedExtensions = const ['.jpg', '.jpeg', '.png', '.gif', '.webp'],
    int maxSizeInBytes = 10 * 1024 * 1024, // 10MB
  }) {
    // Check file extension
    final extension = fileName.toLowerCase().contains('.')
        ? fileName.toLowerCase().substring(fileName.lastIndexOf('.'))
        : '';
    
    if (!allowedExtensions.contains(extension)) {
      debugPrint('Security: Invalid file extension: $extension');
      return false;
    }
    
    // Check file size
    if (fileSize > maxSizeInBytes) {
      debugPrint('Security: File too large: $fileSize bytes');
      return false;
    }
    
    // Check for double extensions (common attack vector)
    final extensionCount = '.'.allMatches(fileName).length;
    if (extensionCount > 1) {
      // Allow safe double extensions like .tar.gz
      final safeDoubleExtensions = ['.tar.gz', '.tar.bz2', '.tar.xz'];
      bool isSafe = false;
      for (final safeExt in safeDoubleExtensions) {
        if (fileName.toLowerCase().endsWith(safeExt)) {
          isSafe = true;
          break;
        }
      }
      if (!isSafe && extensionCount > 1) {
        debugPrint('Security: Suspicious double extension in: $fileName');
        return false;
      }
    }
    
    return true;
  }
}
