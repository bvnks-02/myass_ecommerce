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
  bool _showSplashImage = false;

  @override
  void initState() {
    super.initState();
    _startAnimationSequence();
  }

  _startAnimationSequence() async {
    // Phase 1: Show logo for 2 seconds
    await Future.delayed(const Duration(milliseconds: 2000));

    if (mounted) {
      setState(() {
        _showSplashImage = true;
      });
    }

    // Phase 2: Show splash sequence and then navigate
    await Future.delayed(const Duration(milliseconds: 3000));

    if (mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated) {
        // Ensure role is loaded before deciding route
        await authProvider.refreshRole();
        if (mounted) {
          if (authProvider.isAdmin) {
            Navigator.of(context).pushReplacementNamed('/admin');
          } else {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        }
      } else {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Stylized M Logo (Appears first, stays longer)
            Center(
              child: Image.asset(
                'assets/images/logo.jpg',
                width: 150,
                fit: BoxFit.contain,
              )
                  .animate()
                  .fadeIn(duration: 800.ms)
                  .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.0, 1.0),
                      duration: 1000.ms,
                      curve: Curves.easeOutBack)
                  .fadeOut(
                      duration: 800.ms,
                      delay: 2000.ms), // Fades out after 2 seconds
            ),

            // 2. MYASS Text (Appears after logo starts to fade)
            if (_showSplashImage)
              Center(
                child: Image.asset(
                  'assets/images/splash.jpg',
                  width: 300,
                  fit: BoxFit.contain,
                )
                    .animate()
                    .fadeIn(
                        duration: 800.ms,
                        delay: 400.ms) // Delayed to match logo fade
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
