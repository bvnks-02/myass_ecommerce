// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../theme/app_theme.dart';
import '../../../../core/security/input_sanitizer.dart';
import '../../../../core/security/input_validator.dart';
import '../../../../core/security/rate_limiter.dart';
import '../../../../core/widgets/app_snackbar.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    debugPrint('Login button tapped');
    // Unfocus to dismiss keyboard on mobile - this prevents tap blocking
    FocusScope.of(context).unfocus();
    // Small delay to ensure keyboard is dismissed before proceeding
    await Future.delayed(const Duration(milliseconds: 100));
    // Sanitize inputs
    final email = InputSanitizer.sanitizeEmail(_emailController.text);
    final password = InputSanitizer.sanitizeString(_passwordController.text);

    // Validate inputs
    if (!InputValidator.isValidEmail(email)) {
      AppSnackBar.warning(context, 'Please enter a valid email address');
      return;
    }

    if (email.isEmpty || password.isEmpty) {
      AppSnackBar.warning(context, 'Please enter your email and password');
      return;
    }

    // Rate limiting check
    if (!RateLimiters.auth.isAllowed(email)) {
      AppSnackBar.warning(
          context, 'Too many attempts. Please try again later.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signIn(email, password);

      // Check if login actually succeeded
      if (!authProvider.isAuthenticated) {
        debugPrint('Login failed - not authenticated');
        if (mounted) {
          AppSnackBar.error(
              context, 'Invalid email or password. Please try again.');
        }
        return;
      }

      // Force refresh role and wait for it
      debugPrint('Login completed, refreshing role...');
      await authProvider.refreshRole();

      debugPrint('After signIn - userRole: ${authProvider.userRole}');
      debugPrint('After signIn - isAdmin: ${authProvider.isAdmin}');

      if (mounted) {
        if (authProvider.isAdmin) {
          debugPrint('Navigating to /admin');
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          debugPrint('Navigating to /home');
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString().replaceAll('Exception: ', '');
        AppSnackBar.error(context, message);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSocialLogin(Future<void> Function() signInMethod) async {
    setState(() => _isLoading = true);
    StreamSubscription<AuthState>? sub;
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await signInMethod();

      // If the provider has an immediate error (e.g. provider not enabled), stop here
      if (authProvider.hasError && mounted) {
        AppSnackBar.error(context, authProvider.errorMessage!);
        return;
      }

      // Wait for the OAuth callback to fire a signedIn event
      final completer = Completer<AuthState>();
      sub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        if (data.event == AuthChangeEvent.signedIn && data.session != null) {
          if (!completer.isCompleted) completer.complete(data);
        }
      });
      await completer.future.timeout(const Duration(minutes: 2));

      if (mounted) {
        await authProvider.refreshRole();
        if (authProvider.isAdmin) {
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } on TimeoutException catch (_) {
      if (mounted) {
        AppSnackBar.error(context, 'Login timed out. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Social login failed. Please try again.');
      }
    } finally {
      sub?.cancel();
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.blackColor,
      body: Stack(
        children: [
          // Background Gradient Orbs
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.02),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Skip Button Row
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: TextButton(
                      onPressed: () {
                        debugPrint('Skip button tapped');
                        Navigator.pushReplacementNamed(context, '/home');
                      },
                      child: const Text(
                        'Skip',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ),
                  ),
                ),
                // Main Content
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 450),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 10),
                              // Logo
                              Center(
                                child: Hero(
                                  tag: 'logo',
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white.withOpacity(0.1),
                                          width: 1),
                                      image: const DecorationImage(
                                        image: AssetImage(
                                            'assets/images/logo.jpeg'),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Welcome Back',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Sign in to continue shopping',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 25),

                              // Glassmorphic Email Field
                              _buildGlassTextField(
                                controller: _emailController,
                                hintText: 'E-mail',
                                prefixIcon: Icons.email_outlined,
                              ),
                              const SizedBox(height: 12),

                              // Glassmorphic Password Field
                              _buildGlassTextField(
                                controller: _passwordController,
                                hintText: 'Password',
                                prefixIcon: Icons.lock_outline,
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.white.withOpacity(0.4),
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() =>
                                      _obscurePassword = !_obscurePassword),
                                ),
                              ),

                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const ForgotPasswordScreen()),
                                    );
                                  },
                                  child: Text(
                                    'Forgot password?',
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.4),
                                        fontSize: 13),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),

                              // Premium Login Button
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _isLoading ? null : _login,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    decoration: BoxDecoration(
                                      color: _isLoading
                                          ? Colors.white.withOpacity(0.7)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                  color: Colors.black,
                                                  strokeWidth: 2),
                                            ),
                                          )
                                        : const Text(
                                            'Sign In',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.black),
                                          ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 25),
                               !Platform.isIOS
                                  ? Row(
                                children: [
                                  Expanded(
                                      child: Divider(
                                          color:
                                              Colors.white.withOpacity(0.1))),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Text(
                                      'Or continue with',
                                      style: TextStyle(
                                          color: Colors.white.withOpacity(0.3),
                                          fontSize: 12),
                                    ),
                                  ),
                                  Expanded(
                                      child: Divider(
                                          color:
                                              Colors.white.withOpacity(0.1))),
                                ],
                              ):const SizedBox(),
                                !Platform.isIOS
                                  ?const SizedBox(height: 20)
                                  : const SizedBox(),

                              // Social Login Buttons
                              !Platform.isIOS
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        _socialButton(
                                          label: 'Google',
                                          onTap: () => _handleSocialLogin(
                                            () => Provider.of<AuthProvider>(
                                                    context,
                                                    listen: false)
                                                .signInWithGoogle(),
                                          ),
                                        ),
                                        const SizedBox(width: 24),
                                        _socialButton(
                                          label: 'Facebook',
                                          onTap: () => _handleSocialLogin(
                                            () => Provider.of<AuthProvider>(
                                                    context,
                                                    listen: false)
                                                .signInWithFacebook(),
                                          ),
                                        ),
                                      ],
                                    )
                                  : const SizedBox(),

                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "New here? ",
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.5)),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      debugPrint('Sign Up button tapped');
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const RegisterScreen()),
                                      );
                                    },
                                    child: const Text(
                                      'Create an account',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Icon(prefixIcon,
                color: Colors.white.withOpacity(0.4), size: 20),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  Widget _socialButton({required String label, required VoidCallback onTap}) {
    final bool isGoogle = label == 'Google';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: SvgPicture.asset(
            isGoogle ? 'assets/icons/google.svg' : 'assets/icons/facebook.svg',
            height: isGoogle ? 32 : 38,
            placeholderBuilder: (context) => Icon(
              isGoogle ? Icons.g_mobiledata : Icons.facebook,
              color:
                  isGoogle ? const Color(0xFF4285F4) : const Color(0xFF1877F2),
              size: 38,
            ),
          ),
        ),
      ),
    );
  }
}
