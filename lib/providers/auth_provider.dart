import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  User? _user;
  bool _isLoading = false;
  String? _userRole;

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

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
      // Fetch the role immediately so isAdmin is available before navigation
      await refreshRole();
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An error occurred during sign in.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password, {String? fullName}) async {
    _isLoading = true;
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
      }
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An error occurred during registration.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> signInWithGoogle() async {
    // Note: This requires proper configuration in Google Cloud and Supabase
    await _supabase.auth.signInWithOAuth(OAuthProvider.google);
  }

  Future<void> signInWithFacebook() async {
    // Note: This requires proper configuration in Facebook and Supabase
    await _supabase.auth.signInWithOAuth(OAuthProvider.facebook);
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<void> refreshRole() async {
    if (_user == null) return;
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('role')
          .eq('id', _user!.id)
          .single();
      
      _userRole = response['role'];
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching user role: $e');
    }
  }
}
