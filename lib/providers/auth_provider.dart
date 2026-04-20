import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  User? _user;
  bool _isLoading = false;
  String? _userRole;
  String? _errorMessage;

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
  bool get isAdmin => _userRole == 'admin';
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _supabase.auth.signInWithPassword(email: email, password: password);
      
      // Check if email is not confirmed
      if (response.user != null && response.session == null) {
        _errorMessage = 'Please confirm your email address. Check your inbox for the confirmation link.';
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // Fetch the role immediately so isAdmin is available before navigation
      await refreshRole();
    } on AuthException catch (e) {
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
      debugPrint('Sign in error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password, {String? fullName}) async {
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
      notifyListeners();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  Future<void> signInWithGoogle() async {
    // Note: This requires proper configuration in Google Cloud and Supabase
    try {
      await _supabase.auth.signInWithOAuth(OAuthProvider.google);
    } catch (e) {
      _errorMessage = 'Google sign in failed. Please try again.';
      notifyListeners();
    }
  }

  Future<void> signInWithFacebook() async {
    // Note: This requires proper configuration in Facebook and Supabase
    try {
      await _supabase.auth.signInWithOAuth(OAuthProvider.facebook);
    } catch (e) {
      _errorMessage = 'Facebook sign in failed. Please try again.';
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _supabase.auth.resetPasswordForEmail(email);
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

  Future<void> refreshRole() async {
    if (_user == null) return;
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('role')
          .eq('id', _user!.id)
          .single()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint('Role fetch timeout, defaulting to customer');
              return {'role': 'customer'};
            },
          );
      
      _userRole = response['role'] ?? 'customer';
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching user role: $e');
      _userRole = 'customer'; // Default to customer on error
      notifyListeners();
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
}
