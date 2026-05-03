# OWASP Security Implementation Guide

This document outlines the OWASP security measures implemented in the Myazz E-Commerce application.

## Table of Contents
1. [Input Sanitization](#input-sanitization)
2. [Input Validation](#input-validation)
3. [Rate Limiting](#rate-limiting)
4. [API Key Management](#api-key-management)
5. [SQL Injection Prevention](#sql-injection-prevention)
6. [XSS Prevention](#xss-prevention)
7. [Security Headers](#security-headers)
8. [Security Middleware](#security-middleware)

## Input Sanitization

All user inputs are sanitized using the `InputSanitizer` class (`lib/core/security/input_sanitizer.dart`).

### Implemented Sanitization:
- **String sanitization**: Removes HTML tags, script patterns, SQL injection patterns
- **Email sanitization**: Trims, lowercases, removes dangerous content
- **Search query sanitization**: Limits length, removes dangerous patterns
- **URL sanitization**: Only allows http/https protocols, prevents JavaScript protocol
- **Numeric sanitization**: Removes non-numeric characters except decimal point and minus sign

### Usage Example:
```dart
final sanitizedName = InputSanitizer.sanitizeString(nameController.text, maxLength: 100);
final sanitizedEmail = InputSanitizer.sanitizeEmail(emailController.text);
final sanitizedSearch = InputSanitizer.sanitizeSearchQuery(searchQuery);
```

### Applied In:
- ✅ Login Screen
- ✅ Register Screen
- ✅ Forgot Password Screen
- ✅ Reset Password Screen
- ✅ Profile Screen
- ✅ Cart/Order Screen
- ✅ Support Screen
- ✅ Admin Product Management
- ✅ Search Functionality

## Input Validation

All user inputs are validated using the `InputValidator` class (`lib/core/security/input_validator.dart`).

### Implemented Validation:
- **Email validation**: RFC-compliant email format validation
- **Password validation**: 
  - Minimum 8 characters
  - At least 1 uppercase letter
  - At least 1 lowercase letter
  - At least 1 number
  - At least 1 special character
- **Name validation**: Letters and spaces only, 2-100 characters
- **Phone validation**: 10-15 digits
- **Search query validation**: 2-200 characters, blocks SQL injection patterns
- **URL validation**: Valid URL format, blocks JavaScript protocol
- **Numeric validation**: Configurable min/max values

### Usage Example:
```dart
final emailError = InputValidator.isValidEmail(email);
final passwordError = InputValidator.validatePassword(password);
final nameError = InputValidator.validateFullName(name);
```

### Applied In:
- ✅ All Authentication Screens
- ✅ Profile Screen
- ✅ Cart/Order Screen
- ✅ Support/Contact Forms

## Rate Limiting

Rate limiting is implemented using the `RateLimiter` class (`lib/core/security/rate_limiter.dart`) to prevent abuse and brute force attacks.

### Pre-configured Rate Limiters:
| Limiter | Max Requests | Window | Purpose |
|---------|-------------|---------|---------|
| `RateLimiters.auth` | 5 | 15 minutes | Login/Register attempts |
| `RateLimiters.passwordReset` | 3 | 1 hour | Password reset requests |
| `RateLimiters.search` | 30 | 1 minute | Search queries |
| `RateLimiters.api` | 100 | 1 minute | General API calls |
| `RateLimiters.contact` | 5 | 1 hour | Contact form submissions |
| `RateLimiters.cart` | 50 | 1 minute | Cart operations |

### Usage Example:
```dart
if (!RateLimiters.auth.isAllowed(email)) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Too many attempts. Please try again later.')),
  );
  return;
}
```

### Applied In:
- ✅ Authentication (login, register, password reset)
- ✅ Search functionality
- ✅ Contact/Support forms
- ✅ API Service (all endpoints)
- ✅ Order placement
- ✅ Profile updates
- ✅ Admin operations

## API Key Management

API keys are managed securely using environment variables.

### Implementation:
1. **Environment File**: `.env` file stores credentials (gitignored)
2. **Example File**: `.env.example` provides template
3. **Loading**: `flutter_dotenv` package loads variables at startup
4. **Access**: Credentials accessed via `dotenv.env['KEY_NAME']`

### Files:
- `.env` - Actual credentials (DO NOT COMMIT)
- `.env.example` - Template with placeholder values
- `pubspec.yaml` - Includes `.env` in assets

### Usage:
```dart
await dotenv.load(fileName: ".env");

await Supabase.initialize(
  url: dotenv.env['SUPABASE_URL'] ?? '',
  anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
);
```

### Applied In:
- ✅ Supabase initialization in `main.dart`
- ✅ All API service calls

## SQL Injection Prevention

SQL injection is prevented through multiple layers:

### 1. Parameterized Queries (Supabase)
The Supabase Flutter SDK automatically uses parameterized queries:
```dart
// Safe - parameters are bound, not concatenated
await _supabase.from('orders').insert({
  'user_id': userId,
  'name': sanitizedName,
});
```

### 2. Input Sanitization
All user inputs are sanitized to remove SQL injection patterns:
- `DROP TABLE`
- `DELETE FROM`
- `UNION SELECT`
- Single quotes, semicolons
- Comment sequences (`--`)

### 3. Input Validation
Input validation blocks suspicious patterns before they reach the database.

### Applied In:
- ✅ All database queries via Supabase SDK
- ✅ Search functionality
- ✅ Order creation
- ✅ Admin operations

## XSS Prevention

Cross-Site Scripting (XSS) is prevented through multiple measures:

### 1. Input Sanitization
All inputs are sanitized to remove:
- `<script>` tags and content
- Event handlers (`onclick`, `onerror`, etc.)
- `javascript:` protocol
- `data:text/html` URIs
- `<iframe>`, `<object>`, `<embed>` tags

### 2. HTML Escaping
The `InputSanitizer.escapeHtml()` method escapes special characters:
```dart
static String escapeHtml(String input) {
  return input
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}
```

### 3. Flutter's Built-in Protection
Flutter's widget system automatically escapes text content.

### Applied In:
- ✅ All text input fields
- ✅ Search functionality
- ✅ Support forms
- ✅ Admin product management

## Security Headers

Security headers are provided for HTTP requests via `SecurityHeaders` class (`lib/core/security/security_middleware.dart`):

### Implemented Headers:
- `X-Content-Type-Options: nosniff` - Prevents MIME type sniffing
- `X-Frame-Options: DENY` - Prevents clickjacking
- `X-XSS-Protection: 1; mode=block` - Enables XSS filtering
- `Referrer-Policy: strict-origin-when-cross-origin` - Controls referrer information
- `Content-Security-Policy` - Restricts resource loading

### Usage:
```dart
final headers = SecurityHeaders.getStandardHeaders();
```

## Security Middleware

The `SecurityMiddleware` class provides centralized security controls:

### Features:
1. **Request Validation**: Checks for suspicious patterns in requests
2. **Path Traversal Detection**: Blocks `../` and similar patterns
3. **Null Byte Detection**: Prevents buffer overflow attempts
4. **Map Sanitization**: Recursively sanitizes nested data structures

### Security Audit Logging:
Logs security events for monitoring:
```dart
SecurityAudit.log(
  event: 'Suspicious activity detected',
  severity: 'HIGH',
  userId: userId,
  details: 'Multiple failed login attempts',
);
```

### Secure Storage Helpers:
- `maskSensitiveData()`: Masks sensitive data for logging
- `maskEmail()`: Masks email addresses
- `validateFileUpload()`: Validates file uploads for security

## Security Checklist

### Authentication & Authorization:
- ✅ Password strength requirements enforced
- ✅ Rate limiting on all auth endpoints
- ✅ Input sanitization on all auth forms
- ✅ Session management via Supabase Auth
- ✅ Role-based access control (admin vs customer)

### Data Protection:
- ✅ All user inputs sanitized
- ✅ All user inputs validated
- ✅ API keys in environment variables
- ✅ No sensitive data in logs (masked)
- ✅ Parameterized queries (SQL injection prevention)

### Communication Security:
- ✅ HTTPS enforced for all API calls
- ✅ Security headers defined
- ✅ Rate limiting on all endpoints

### File Upload Security:
- ✅ File extension validation
- ✅ File size limits
- ✅ Double extension detection

### Frontend Security:
- ✅ XSS prevention via input sanitization
- ✅ HTML escaping utilities
- ✅ Content Security Policy support

## Testing Security

To test the security implementation:

1. **Rate Limiting**: Try rapid successive requests to auth endpoints
2. **Input Validation**: Submit invalid emails, weak passwords
3. **XSS Prevention**: Try injecting `<script>alert('xss')</script>` in forms
4. **SQL Injection**: Try entering `'; DROP TABLE users; --` in search
5. **Path Traversal**: Try accessing `../../../etc/passwd` in file operations

All attempts should be blocked by the security measures.

## Security Contacts

If you discover a security vulnerability, please contact:
- Email: myazzalgérie@gmail.com
- WhatsApp: +213 542 455 634

## References

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)
- [OWASP Input Validation Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Input_Validation_Cheat_Sheet.html)
- [Supabase Security](https://supabase.com/docs/guides/database/secure-data)
