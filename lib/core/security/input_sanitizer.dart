/// OWASP-compliant input sanitization utilities
/// Prevents XSS, injection attacks, and other security vulnerabilities
class InputSanitizer {
  /// Sanitize string input by removing potentially dangerous characters
  /// - Removes HTML tags
  /// - Removes script tags
  /// - Removes event handlers
  /// - Limits length
  static String sanitizeString(String input, {int maxLength = 1000}) {
    if (input.isEmpty) return input;
    
    // Trim whitespace
    String sanitized = input.trim();
    
    // Limit length
    if (sanitized.length > maxLength) {
      sanitized = sanitized.substring(0, maxLength);
    }
    
    // Remove HTML tags
    sanitized = _removeHtmlTags(sanitized);
    
    // Remove dangerous JavaScript patterns
    sanitized = _removeScriptPatterns(sanitized);
    
    // Remove SQL injection patterns
    sanitized = _removeSqlPatterns(sanitized);
    
    return sanitized;
  }
  
  /// Sanitize email input
  static String sanitizeEmail(String email) {
    if (email.isEmpty) return email;
    
    String sanitized = email.trim().toLowerCase();
    
    // Remove any HTML or script content
    sanitized = _removeHtmlTags(sanitized);
    sanitized = _removeScriptPatterns(sanitized);
    
    // Limit email length to prevent DoS
    if (sanitized.length > 254) {
      sanitized = sanitized.substring(0, 254);
    }
    
    return sanitized;
  }
  
  /// Sanitize search queries
  static String sanitizeSearchQuery(String query) {
    if (query.isEmpty) return query;
    
    String sanitized = query.trim();
    
    // Limit search query length
    if (sanitized.length > 200) {
      sanitized = sanitized.substring(0, 200);
    }
    
    // Remove HTML tags
    sanitized = _removeHtmlTags(sanitized);
    
    // Remove script patterns
    sanitized = _removeScriptPatterns(sanitized);
    
    return sanitized;
  }
  
  /// Sanitize URLs to prevent open redirect attacks
  static String? sanitizeUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    
    String sanitized = url.trim();
    
    // Only allow http and https protocols
    if (!sanitized.startsWith('http://') && !sanitized.startsWith('https://')) {
      return null;
    }
    
    // Remove JavaScript protocol
    if (sanitized.toLowerCase().startsWith('javascript:')) {
      return null;
    }
    
    // Limit URL length
    if (sanitized.length > 2048) {
      return null;
    }
    
    return sanitized;
  }
  
  /// Sanitize numeric input
  static String sanitizeNumeric(String input) {
    if (input.isEmpty) return input;
    
    // Remove all non-numeric characters except decimal point and minus sign
    String sanitized = input.replaceAll(RegExp(r'[^\d.-]'), '');
    
    // Limit length
    if (sanitized.length > 50) {
      sanitized = sanitized.substring(0, 50);
    }
    
    return sanitized;
  }
  
  /// Remove HTML tags from string
  static String _removeHtmlTags(String input) {
    // Remove HTML tags using regex
    return input.replaceAll(RegExp(r'<[^>]*>'), '');
  }
  
  /// Remove dangerous JavaScript/script patterns
  static String _removeScriptPatterns(String input) {
    String sanitized = input;
    
    // Remove script tags and content
    sanitized = sanitized.replaceAll(RegExp(r'<script\b[^>]*>([\s\S]*?)<\/script>', caseSensitive: false), '');
    
    // Remove event handlers (onclick, onerror, etc.)
    sanitized = sanitized.replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), '');
    
    // Remove javascript: protocol
    sanitized = sanitized.replaceAll(RegExp(r'javascript:', caseSensitive: false), '');
    
    // Remove data URIs that could execute scripts
    sanitized = sanitized.replaceAll(RegExp(r'data:text/html', caseSensitive: false), '');
    
    return sanitized;
  }
  
  /// Remove common SQL injection patterns
  static String _removeSqlPatterns(String input) {
    String sanitized = input;
    
    // Remove common SQL injection patterns
    final sqlPatterns = [
      r"' OR '1'='1",
      r'" OR "1"="1',
      r"1'='1'",
      r'1="1"',
      r"DROP TABLE",
      r"DELETE FROM",
      r"INSERT INTO",
      r"UPDATE",
      r"UNION SELECT",
      r"--",
      r";",
      r"xp_",
      r"exec(",
    ];
    
    for (final pattern in sqlPatterns) {
      sanitized = sanitized.replaceAll(RegExp(pattern, caseSensitive: false), '');
    }
    
    return sanitized;
  }
  
  /// Escape special characters for safe display
  static String escapeHtml(String input) {
    if (input.isEmpty) return input;
    
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}
