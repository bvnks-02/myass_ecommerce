/// OWASP-compliant input validation utilities
/// Validates user inputs on both frontend and backend
class InputValidator {
  /// Validate email format
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    
    // Simplified email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    
    return emailRegex.hasMatch(email) && email.length <= 254;
  }
  
  /// Validate password strength
  /// - At least 8 characters
  /// - At least 1 uppercase letter
  /// - At least 1 lowercase letter
  /// - At least 1 number
  /// - At least 1 special character
  static String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password is required';
    }
    
    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    
    if (password.length > 128) {
      return 'Password is too long (max 128 characters)';
    }
    
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain at least 1 uppercase letter';
    }
    
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must contain at least 1 lowercase letter';
    }
    
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must contain at least 1 number';
    }
    
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return 'Password must contain at least 1 special character';
    }
    
    return null; // Valid
  }
  
  /// Validate full name
  static String? validateFullName(String name) {
    if (name.isEmpty) {
      return 'Name is required';
    }
    
    if (name.length < 2) {
      return 'Name must be at least 2 characters long';
    }
    
    if (name.length > 100) {
      return 'Name is too long (max 100 characters)';
    }
    
    // Only allow letters and spaces
    final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
    if (!nameRegex.hasMatch(name)) {
      return 'Name contains invalid characters';
    }
    
    return null; // Valid
  }
  
  /// Validate search query
  static String? validateSearchQuery(String query) {
    if (query.isEmpty) {
      return null; // Empty search is allowed
    }
    
    if (query.length < 2) {
      return 'Search query must be at least 2 characters';
    }
    
    if (query.length > 200) {
      return 'Search query is too long (max 200 characters)';
    }
    
    // Prevent SQL injection patterns
    final dangerousPatterns = [
      "' OR '",
      '" OR "',
      'DROP',
      'DELETE',
      'UNION',
      'SELECT',
      'INSERT',
      'UPDATE',
      '--',
      ';',
    ];
    
    for (final pattern in dangerousPatterns) {
      if (query.toUpperCase().contains(pattern)) {
        return 'Search query contains invalid characters';
      }
    }
    
    return null; // Valid
  }
  
  /// Validate URL
  static String? validateUrl(String url) {
    if (url.isEmpty) {
      return 'URL is required';
    }
    
    if (url.length > 2048) {
      return 'URL is too long (max 2048 characters)';
    }
    
    // Check for valid URL format
    final urlRegex = RegExp(r'^https?:\/\/[^\s/$.?#].[^\s]*$');
    
    if (!urlRegex.hasMatch(url)) {
      return 'Invalid URL format';
    }
    
    // Prevent javascript: protocol
    if (url.toLowerCase().startsWith('javascript:')) {
      return 'Invalid URL protocol';
    }
    
    return null; // Valid
  }
  
  /// Validate numeric input (e.g., price, quantity)
  static String? validateNumeric(String input, {double? min, double? max}) {
    if (input.isEmpty) {
      return 'Value is required';
    }
    
    final number = double.tryParse(input);
    if (number == null) {
      return 'Invalid number format';
    }
    
    if (min != null && number < min) {
      return 'Value must be at least $min';
    }
    
    if (max != null && number > max) {
      return 'Value must be at most $max';
    }
    
    return null; // Valid
  }
  
  /// Validate phone number (basic format)
  static String? validatePhoneNumber(String phone) {
    if (phone.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove non-numeric characters
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleaned.length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    
    if (cleaned.length > 15) {
      return 'Phone number is too long';
    }
    
    return null; // Valid
  }
  
  /// Validate text input (generic)
  static String? validateText(String text, {
    int minLength = 1,
    int maxLength = 1000,
    bool allowEmpty = false,
  }) {
    if (!allowEmpty && text.isEmpty) {
      return 'This field is required';
    }
    
    if (text.isNotEmpty && text.length < minLength) {
      return 'Must be at least $minLength characters';
    }
    
    if (text.length > maxLength) {
      return 'Must be at most $maxLength characters';
    }
    
    return null; // Valid
  }
  
  /// Validate that input contains no script tags or dangerous patterns
  static bool isSafeInput(String input) {
    final dangerousPatterns = [
      RegExp(r'<script', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false),
      RegExp(r'data:text/html', caseSensitive: false),
      RegExp(r'<iframe', caseSensitive: false),
      RegExp(r'<object', caseSensitive: false),
      RegExp(r'<embed', caseSensitive: false),
    ];
    
    for (final pattern in dangerousPatterns) {
      if (pattern.hasMatch(input)) {
        return false;
      }
    }
    
    return true;
  }
}
