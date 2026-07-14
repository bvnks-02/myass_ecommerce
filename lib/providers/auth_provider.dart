import 'dart:typed_data';
import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint, kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/security/rate_limiter.dart';
import '../core/utils/logger.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  User? _user;
  bool _isLoading = false;
  String? _userRole;
  String? _errorMessage;

  // ----- Lot 2: profile dashboard fields (from public.user_profiles) -----
  double? _height;
  double? _weight;
  String? _avatarUrl;
  String? _addressLine1;
  String? _addressLine2;
  String? _city;
  String? _postalCode;
  bool _billingSameAsShipping = true;
  String? _billingAddressLine1;
  String? _billingAddressLine2;
  String? _billingCity;
  String? _billingPostalCode;

  double? get height => _height;
  double? get weight => _weight;
  String? get avatarUrl => _avatarUrl;
  String? get addressLine1 => _addressLine1;
  String? get addressLine2 => _addressLine2;
  String? get city => _city;
  String? get postalCode => _postalCode;
  bool get billingSameAsShipping => _billingSameAsShipping;
  String? get billingAddressLine1 => _billingAddressLine1;
  String? get billingAddressLine2 => _billingAddressLine2;
  String? get billingCity => _billingCity;
  String? get billingPostalCode => _billingPostalCode;

  AuthProvider() {
    _user = _supabase.auth.currentUser;
    _supabase.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      if (_user != null) {
        refreshRole();
      } else {
        _userRole = null;
      }
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get userRole => _userRole;
  bool get isAdmin {
    // Check by email (backup) + check by role from database
    final userEmail = _user?.email?.toLowerCase().trim();
    if (userEmail == 'belaggounamina2@gmail.com') return true;
    return _userRole?.toLowerCase() == 'admin';
  }
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    // Rate limiting check (backend-side)
    if (!RateLimiters.auth.isAllowed(email)) {
      _errorMessage = 'Too many sign-in attempts. Please try again later.';
      _isLoading = false;
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      debugPrint('=== SIGN IN START ===');
      debugPrint('Email: $email');
      final response = await _supabase.auth.signInWithPassword(email: email, password: password);
      
      debugPrint('Sign in response user: ${response.user?.email}');
      debugPrint('Sign in response session: ${response.session != null}');
      
      // Update _user immediately from response
      if (response.user != null) {
        _user = response.user;
        debugPrint('Updated _user: ${_user?.email}');
      }
      
      // Check if email is not confirmed
      if (response.user != null && response.session == null) {
        _errorMessage = 'Please confirm your email address. Check your inbox for the confirmation link.';
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // Fetch the role immediately so isAdmin is available before navigation
      debugPrint('Calling refreshRole after sign in...');
      await refreshRole();
      debugPrint('After refreshRole, userRole: $_userRole');
      debugPrint('After refreshRole, isAdmin: $isAdmin');
      debugPrint('=== SIGN IN END ===');
    } on AuthException catch (e) {
      debugPrint('AuthException: ${e.message}');
      // Reset user on auth error to prevent bypass
      _user = null;
      if (e.message.contains('Email not confirmed')) {
        _errorMessage = 'Please confirm your email address. Check your inbox for the confirmation link.';
      } else if (e.message.contains('Invalid login credentials')) {
        _errorMessage = 'Invalid email or password. Please try again.';
      } else if (e.message.contains('User not found')) {
        _errorMessage = 'No account found with this email. Please sign up.';
      } else {
        _errorMessage = e.message;
      }
    } catch (e) {
      _errorMessage = 'An error occurred during sign in. Please try again.';
      _user = null;
      debugPrint('Sign in error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password, {String? fullName}) async {
    // Rate limiting check (backend-side)
    if (!RateLimiters.auth.isAllowed(email)) {
      _errorMessage = 'Too many registration attempts. Please try again later.';
      _isLoading = false;
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
      );
      
      if (response.session != null) {
        _user = response.session?.user;
        await refreshRole();
      } else {
        // Email confirmation required
        _errorMessage = 'Please check your email to confirm your account.';
      }
    } on AuthException catch (e) {
      if (e.message.contains('User already registered')) {
        _errorMessage = 'An account with this email already exists. Please sign in.';
      } else if (e.message.contains('Password should be at least')) {
        _errorMessage = 'Password must be at least 6 characters long.';
      } else if (e.message.contains('Unable to validate email address')) {
        _errorMessage = 'Please enter a valid email address.';
      } else {
        _errorMessage = e.message;
      }
    } catch (e) {
      _errorMessage = 'An error occurred during registration. Please try again.';
      debugPrint('Sign up error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      _user = null;
      _userRole = null;
      _errorMessage = null;
      _clearProfileFields();
      notifyListeners();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  Future<void> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      debugPrint('Starting Google sign in...');
      final redirectTo = kIsWeb ? Uri.base.origin : 'com.example.myazz://login-callback/';
      debugPrint('OAuth redirectTo: $redirectTo');
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
        authScreenLaunchMode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      );
      debugPrint('Google OAuth initiated successfully');
    } on AuthException catch (e) {
      debugPrint('Google AuthException: ${e.message}');
      _errorMessage = 'Google sign in failed: ${e.message}';
    } catch (e) {
      debugPrint('Google sign in error: $e');
      _errorMessage = 'Google sign in failed. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithFacebook() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      debugPrint('Starting Facebook sign in...');
      final redirectTo = kIsWeb ? Uri.base.origin : 'com.example.myazz://login-callback/';
      debugPrint('OAuth redirectTo: $redirectTo');
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: redirectTo,
        authScreenLaunchMode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      );
      debugPrint('Facebook OAuth initiated successfully');
    } on AuthException catch (e) {
      debugPrint('Facebook AuthException: ${e.message}');
      if (e.message.contains('not enabled')) {
        _errorMessage = 'Facebook login is not configured. Please contact support.';
      } else if (e.message.contains('redirect')) {
        _errorMessage = 'Redirect URL not configured. Please check Supabase settings.';
      } else {
        _errorMessage = 'Facebook sign in failed: ${e.message}';
      }
    } catch (e) {
      debugPrint('Facebook sign in error: $e');
      _errorMessage = 'Facebook sign in failed. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    // Rate limiting check (backend-side)
    if (!RateLimiters.passwordReset.isAllowed(email)) {
      _errorMessage = 'Too many password reset attempts. Please try again later.';
      _isLoading = false;
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      // Use web URL for web, deep link for mobile
      final redirectUrl = kIsWeb
          ? '${Uri.base.origin}/#/reset_password'
          : 'com.example.myazz://reset_password/';
      
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: redirectUrl,
      );
      _errorMessage = null;
    } on AuthException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to send reset email. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePassword(String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      _errorMessage = null;
    } on AuthException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to update password. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshRole() async {
    if (_user == null) return;
    try {
      AppLogger.debug('Fetching role for user ID: ${_user!.id}',
          tag: 'AuthProvider');

      // maybeSingle() returns null (instead of throwing) when no row exists,
      // which is exactly the first-OAuth-sign-in case.
      final response = await _supabase
          .from('user_profiles')
          .select('role, email')
          .eq('id', _user!.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));

      if (response == null) {
        // No profile yet (e.g. first Google sign-in where the DB trigger did
        // not run). Create one defensively so role lookups and the profile
        // dashboard work immediately.
        AppLogger.info(
            'No profile row found, creating one for first sign-in',
            tag: 'AuthProvider');
        await _ensureProfileExists();
        _userRole = 'customer';
      } else {
        _userRole = response['role'] ?? 'customer';
      }
      AppLogger.debug('Resolved role: $_userRole', tag: 'AuthProvider');
      notifyListeners();
    } catch (e, s) {
      AppLogger.error('Error fetching user role',
          tag: 'AuthProvider', error: e, stackTrace: s);
      // Default to customer on any error so the UI still renders.
      _userRole ??= 'customer';
      notifyListeners();
    }
  }

  /// Ensures a public.user_profiles row exists for the current user.
  /// Idempotent: safe to call on every sign-in. Covers first-time OAuth
  /// (Google) users in case the auth trigger did not create the row.
  Future<void> _ensureProfileExists() async {
    if (_user == null) return;
    try {
      await _supabase.from('user_profiles').upsert(
        {
          'id': _user!.id,
          'email': _user!.email,
          'full_name': _user!.userMetadata?['full_name'] ??
              _user!.userMetadata?['name'],
        },
        onConflict: 'id',
        ignoreDuplicates: true,
      );
    } catch (e, s) {
      AppLogger.error('Failed to ensure profile exists',
          tag: 'AuthProvider', error: e, stackTrace: s);
    }
  }

  Future<bool> checkIsAdmin() async {
    if (_user == null) return false;

    try {
      await refreshRole();
      return isAdmin;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  // ----- Lot 2: profile dashboard load / save -----

  /// Loads the extended profile fields (height, weight, addresses, avatar)
  /// from public.user_profiles into the provider so screens can read them.
  Future<void> loadProfile() async {
    if (_user == null) return;
    try {
      final data = await _supabase
          .from('user_profiles')
          .select(
              'height, weight, avatar_url, address_line1, address_line2, city, postal_code, billing_same_as_shipping, billing_address_line1, billing_address_line2, billing_city, billing_postal_code')
          .eq('id', _user!.id)
          .maybeSingle();

      if (data != null) {
        _height = (data['height'] as num?)?.toDouble();
        _weight = (data['weight'] as num?)?.toDouble();
        _avatarUrl = data['avatar_url'] as String?;
        _addressLine1 = data['address_line1'] as String?;
        _addressLine2 = data['address_line2'] as String?;
        _city = data['city'] as String?;
        _postalCode = data['postal_code'] as String?;
        _billingSameAsShipping =
            (data['billing_same_as_shipping'] as bool?) ?? true;
        _billingAddressLine1 = data['billing_address_line1'] as String?;
        _billingAddressLine2 = data['billing_address_line2'] as String?;
        _billingCity = data['billing_city'] as String?;
        _billingPostalCode = data['billing_postal_code'] as String?;
        notifyListeners();
      }
    } catch (e, s) {
      AppLogger.error('Failed to load profile details',
          tag: 'AuthProvider', error: e, stackTrace: s);
    }
  }

  /// Persists the extended profile fields to public.user_profiles.
  /// Values are expected to be already sanitized/validated by the caller.
  /// Returns true on success.
  Future<bool> saveProfileDetails({
    double? height,
    double? weight,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? postalCode,
    required bool billingSameAsShipping,
    String? billingAddressLine1,
    String? billingAddressLine2,
    String? billingCity,
    String? billingPostalCode,
    String? avatarUrl,
  }) async {
    if (_user == null) return false;
    try {
      final payload = <String, dynamic>{
        'id': _user!.id,
        'email': _user!.email,
        'height': height,
        'weight': weight,
        'address_line1': addressLine1,
        'address_line2': addressLine2,
        'city': city,
        'postal_code': postalCode,
        'billing_same_as_shipping': billingSameAsShipping,
        // When billing mirrors shipping, store the shipping values so the
        // billing address is always self-contained for order fulfilment.
        'billing_address_line1':
            billingSameAsShipping ? addressLine1 : billingAddressLine1,
        'billing_address_line2':
            billingSameAsShipping ? addressLine2 : billingAddressLine2,
        'billing_city': billingSameAsShipping ? city : billingCity,
        'billing_postal_code':
            billingSameAsShipping ? postalCode : billingPostalCode,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (avatarUrl != null) payload['avatar_url'] = avatarUrl;

      await _supabase.from('user_profiles').upsert(payload);

      // Update local state and notify.
      _height = height;
      _weight = weight;
      _addressLine1 = addressLine1;
      _addressLine2 = addressLine2;
      _city = city;
      _postalCode = postalCode;
      _billingSameAsShipping = billingSameAsShipping;
      _billingAddressLine1 = payload['billing_address_line1'] as String?;
      _billingAddressLine2 = payload['billing_address_line2'] as String?;
      _billingCity = payload['billing_city'] as String?;
      _billingPostalCode = payload['billing_postal_code'] as String?;
      if (avatarUrl != null) _avatarUrl = avatarUrl;
      notifyListeners();
      return true;
    } catch (e, s) {
      AppLogger.error('Failed to save profile details',
          tag: 'AuthProvider', error: e, stackTrace: s);
      _errorMessage = 'Impossible d\'enregistrer le profil. Réessayez.';
      notifyListeners();
      return false;
    }
  }

  /// Uploads a new avatar to the `avatars` bucket under `{uid}/`, deletes the
  /// previous avatar file (cleanup), persists the new public URL, and returns it.
  Future<String?> updateAvatar(Uint8List bytes, String fileExtension) async {
    if (_user == null) return null;
    final storage = _supabase.storage.from('avatars');
    final ext = fileExtension.replaceAll('.', '').toLowerCase();
    final safeExt = (ext == 'png' || ext == 'jpg' || ext == 'jpeg' || ext == 'webp')
        ? ext
        : 'jpg';
    final newPath =
        '${_user!.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.$safeExt';
    final previousUrl = _avatarUrl;
    try {
      await storage.uploadBinary(
        newPath,
        bytes,
        fileOptions: FileOptions(
          upsert: true,
          contentType: 'image/${safeExt == 'jpg' ? 'jpeg' : safeExt}',
        ),
      );
      final publicUrl = storage.getPublicUrl(newPath);

      // Persist the new URL immediately so the avatar is saved independently
      // of the address form.
      await _supabase.from('user_profiles').upsert({
        'id': _user!.id,
        'email': _user!.email,
        'avatar_url': publicUrl,
      });

      // Cleanup: remove the previous avatar object (best-effort).
      final previousPath = _storagePathFromPublicUrl(previousUrl);
      if (previousPath != null && previousPath != newPath) {
        try {
          await storage.remove([previousPath]);
        } catch (e) {
          AppLogger.warning('Old avatar cleanup failed: $e',
              tag: 'AuthProvider');
        }
      }

      _avatarUrl = publicUrl;
      notifyListeners();
      return publicUrl;
    } catch (e, s) {
      AppLogger.error('Avatar upload failed',
          tag: 'AuthProvider', error: e, stackTrace: s);
      return null;
    }
  }

  void _clearProfileFields() {
    _height = null;
    _weight = null;
    _avatarUrl = null;
    _addressLine1 = null;
    _addressLine2 = null;
    _city = null;
    _postalCode = null;
    _billingSameAsShipping = true;
    _billingAddressLine1 = null;
    _billingAddressLine2 = null;
    _billingCity = null;
    _billingPostalCode = null;
  }

  /// Extracts the in-bucket object path (`{uid}/file.ext`) from a public URL.
  String? _storagePathFromPublicUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    const marker = '/avatars/';
    final idx = url.indexOf(marker);
    if (idx == -1) return null;
    var path = url.substring(idx + marker.length);
    final q = path.indexOf('?');
    if (q != -1) path = path.substring(0, q);
    return path.isEmpty ? null : path;
  }

}
