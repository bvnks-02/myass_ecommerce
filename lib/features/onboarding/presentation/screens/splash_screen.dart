import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showText = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _startSplashSequence();
  }

  /// Animated logo splash: brand mark fades/scales in, then the wordmark
  /// card follows with a shimmer, then navigate.
  Future<void> _startSplashSequence() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _showText = true);
    await Future.delayed(const Duration(milliseconds: 3200));
    _navigate();
  }

  Future<void> _navigate() async {
    if (_navigated || !mounted) return;
    _navigated = true;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Login is optional: guests land on the store. Admins still go to dashboard.
    if (authProvider.isAuthenticated) {
      await authProvider.refreshRole();
      if (!mounted) return;
      Navigator.of(context)
          .pushReplacementNamed(authProvider.isAdmin ? '/admin' : '/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    final logoW = shortest * 0.38;
    final splashW = shortest * 0.72;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Image.asset(
                'assets/images/logo.jpeg',
                width: logoW,
                fit: BoxFit.contain,
              )
                  .animate()
                  .fadeIn(duration: 800.ms)
                  .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.0, 1.0),
                      duration: 1000.ms,
                      curve: Curves.easeOutBack)
                  .fadeOut(duration: 800.ms, delay: 1800.ms),
            ),
            if (_showText)
              Center(
                child: Image.asset(
                  'assets/images/splash.jpeg',
                  width: splashW,
                  fit: BoxFit.contain,
                )
                    .animate()
                    .fadeIn(duration: 800.ms, delay: 400.ms)
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1.0, 1.0),
                      duration: 1000.ms,
                      delay: 400.ms,
                      curve: Curves.easeOutCubic,
                    )
                    .shimmer(delay: 1500.ms, duration: 1000.ms),
              ),
          ],
        ),
      ),
    );
  }
}
