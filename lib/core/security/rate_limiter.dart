/// OWASP-compliant rate limiter
/// Prevents API abuse, brute force attacks, and DoS
class RateLimiter {
  final Map<String, _RateLimitEntry> _requests = {};
  final int maxRequests;
  final Duration window;
  
  RateLimiter({
    this.maxRequests = 10,
    this.window = const Duration(minutes: 1),
  });
  
  /// Check if a request is allowed for the given identifier
  /// Returns true if allowed, false if rate limit exceeded
  bool isAllowed(String identifier) {
    final now = DateTime.now();
    final entry = _requests[identifier];
    
    // Clean up old entries periodically
    _cleanup();
    
    if (entry == null) {
      // First request
      _requests[identifier] = _RateLimitEntry(
        count: 1,
        windowStart: now,
      );
      return true;
    }
    
    // Check if window has expired
    if (now.difference(entry.windowStart) >= window) {
      // Reset for new window
      _requests[identifier] = _RateLimitEntry(
        count: 1,
        windowStart: now,
      );
      return true;
    }
    
    // Check if limit exceeded
    if (entry.count >= maxRequests) {
      return false;
    }
    
    // Increment counter
    entry.count++;
    return true;
  }
  
  /// Get remaining requests for identifier
  int getRemainingRequests(String identifier) {
    final entry = _requests[identifier];
    if (entry == null) return maxRequests;
    
    final now = DateTime.now();
    if (now.difference(entry.windowStart) >= window) {
      return maxRequests;
    }
    
    return maxRequests - entry.count;
  }
  
  /// Get time until window resets
  Duration? getTimeUntilReset(String identifier) {
    final entry = _requests[identifier];
    if (entry == null) return null;
    
    final now = DateTime.now();
    final elapsed = now.difference(entry.windowStart);
    final remaining = window - elapsed;
    
    return remaining.isNegative ? Duration.zero : remaining;
  }
  
  /// Reset rate limit for identifier (use with caution)
  void reset(String identifier) {
    _requests.remove(identifier);
  }
  
  /// Clean up expired entries
  void _cleanup() {
    final now = DateTime.now();
    _requests.removeWhere(
      (key, entry) => now.difference(entry.windowStart) >= window,
    );
  }
  
  /// Clear all rate limits (use for testing only)
  void clearAll() {
    _requests.clear();
  }
}

class _RateLimitEntry {
  int count;
  DateTime windowStart;
  
  _RateLimitEntry({
    required this.count,
    required this.windowStart,
  });
}

/// Pre-configured rate limiters for different operations
class RateLimiters {
  /// Rate limiter for authentication attempts (login, register)
  static final auth = RateLimiter(
    maxRequests: 5,
    window: const Duration(minutes: 15),
  );
  
  /// Rate limiter for password reset
  static final passwordReset = RateLimiter(
    maxRequests: 3,
    window: const Duration(hours: 1),
  );
  
  /// Rate limiter for search queries
  static final search = RateLimiter(
    maxRequests: 30,
    window: const Duration(minutes: 1),
  );
  
  /// Rate limiter for API calls in general
  static final api = RateLimiter(
    maxRequests: 100,
    window: const Duration(minutes: 1),
  );
  
  /// Rate limiter for support/contact form submissions
  static final contact = RateLimiter(
    maxRequests: 5,
    window: const Duration(hours: 1),
  );
  
  /// Rate limiter for cart operations
  static final cart = RateLimiter(
    maxRequests: 50,
    window: const Duration(minutes: 1),
  );
}
