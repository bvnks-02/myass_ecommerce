// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/platform_utils.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../theme/app_theme.dart';
import '../../../../core/security/input_sanitizer.dart';
import '../../../../core/security/input_validator.dart';
import '../../../../core/security/rate_limiter.dart';
import '../../../../core/widgets/app_snackbar.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _register() async {
    // Sanitize inputs
    final name = InputSanitizer.sanitizeString(_nameController.text);
    final email = InputSanitizer.sanitizeEmail(_emailController.text);
    // Do not sanitize passwords — destructive stripping breaks valid passwords.
    final password = _passwordController.text;

    // Validate inputs
    final nameError = InputValidator.validateFullName(name);
    if (nameError != null) {
      AppSnackBar.warning(context, nameError);
      return;
    }

    if (!InputValidator.isValidEmail(email)) {
      AppSnackBar.warning(context, 'Veuillez saisir une adresse e-mail valide.');
      return;
    }

    final passwordError = InputValidator.validatePassword(password);
    if (passwordError != null) {
      AppSnackBar.warning(context, passwordError);
      return;
    }

    // Rate limiting check
    if (!RateLimiters.auth.isAllowed(email)) {
      AppSnackBar.warning(
          context, 'Trop de tentatives. Veuillez réessayer plus tard.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signUp(
        email,
        password,
        fullName: name,
      );
      if (mounted) {
        if (authProvider.hasError) {
          AppSnackBar.warning(
            context,
            authProvider.errorMessage ?? 'Inscription échouée.',
          );
          if (!authProvider.isAuthenticated) {
            // Soft success path: email confirmation required (message in errorMessage)
            if ((authProvider.errorMessage ?? '')
                .toLowerCase()
                .contains('email')) {
              Navigator.pop(context);
            }
          }
          return;
        }
        AppSnackBar.success(context, 'Bienvenue ! Votre compte a été créé.');
        if (authProvider.isAuthenticated) {
          if (authProvider.isAdmin) {
            Navigator.pushReplacementNamed(context, '/admin');
          } else {
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          Navigator.pop(context);
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

      // Wait for OAuth signedIn; navigation is owned by MyApp in main.dart.
      final completer = Completer<AuthState>();
      sub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        if (data.event == AuthChangeEvent.signedIn && data.session != null) {
          if (!completer.isCompleted) completer.complete(data);
        }
      });
      await completer.future.timeout(const Duration(minutes: 2));
      if (mounted) {
        await authProvider.refreshRole();
      }
    } on TimeoutException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Délai de connexion dépassé. Veuillez réessayer.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Social login failed: ${e.toString()}')),
        );
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
            top: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.02),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 450),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Créer un compte',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Inscrivez-vous pour commencer',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 40),

                            // Glassmorphic Name Field
                            _buildGlassTextField(
                              controller: _nameController,
                              hintText: 'Nom complet',
                              prefixIcon: Icons.person_outline,
                            ),
                            const SizedBox(height: 16),

                            // Glassmorphic Email Field
                            _buildGlassTextField(
                              controller: _emailController,
                              hintText: 'E-mail',
                              prefixIcon: Icons.email_outlined,
                            ),
                            const SizedBox(height: 16),

                            // Glassmorphic Password Field
                            _buildGlassTextField(
                              controller: _passwordController,
                              hintText: 'Mot de passe',
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
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Premium Register Button
                            ElevatedButton(
                              onPressed: _isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.black, strokeWidth: 2),
                                    )
                                  : const Text(
                                      'S\'inscrire',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800),
                                    ),
                            ),

                            const SizedBox(height: 40),
                            if (showSocialAuth) ...[
                              Row(
                                children: [
                                  Expanded(
                                      child: Divider(
                                          color:
                                              Colors.white.withOpacity(0.1))),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Text(
                                      'Ou s\'inscrire avec',
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
                              ),
                              const SizedBox(height: 30),
                              // Social Login Buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _socialButton(
                                    label: 'Google',
                                    onTap: () => _handleSocialLogin(
                                      () => Provider.of<AuthProvider>(context,
                                              listen: false)
                                          .signInWithGoogle(),
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  _socialButton(
                                    label: 'Facebook',
                                    onTap: () => _handleSocialLogin(
                                      () => Provider.of<AuthProvider>(context,
                                              listen: false)
                                          .signInWithFacebook(),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 40),
                          ],
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
              const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
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
        width: 65,
        height: 65,
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
