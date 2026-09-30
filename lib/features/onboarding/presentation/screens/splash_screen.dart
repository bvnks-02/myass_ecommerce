import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/utils/logger.dart';
import '../../../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const String _videoAsset = 'assets/videos/entry_animation.mp4';

  VideoPlayerController? _videoController;
  bool _videoReady = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _initSplash();
  }

  Future<void> _initSplash() async {
    // Try the intro video first; fall back to the animated logo on any failure.
    try {
      final controller = VideoPlayerController.asset(_videoAsset);
      _videoController = controller;
      await controller.initialize();
      await controller.setVolume(0);
      controller.addListener(_onVideoTick);
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _videoReady = true);
      await controller.play();

      // Safety net: navigate after the clip's duration (+buffer) even if the
      // completion tick is missed.
      final ms = controller.value.duration.inMilliseconds;
      Future.delayed(Duration(milliseconds: ms > 0 ? ms + 400 : 5000), _navigate);
    } catch (e) {
      AppLogger.warning('Splash video failed, using fallback animation: $e',
          tag: 'Splash');
      _startFallbackSequence();
    }
  }

  void _onVideoTick() {
    final c = _videoController;
    if (c == null) return;
    final value = c.value;
    if (value.isInitialized &&
        !value.isPlaying &&
        value.position >= value.duration &&
        value.duration > Duration.zero) {
      _navigate();
    }
  }

  /// Original logo/text animation used when the video is unavailable.
  Future<void> _startFallbackSequence() async {
    if (mounted) setState(() => _videoReady = false);
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) setState(() => _showFallbackText = true);
    await Future.delayed(const Duration(milliseconds: 3000));
    _navigate();
  }

  bool _showFallbackText = false;

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
  void dispose() {
    _videoController?.removeListener(_onVideoTick);
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _videoReady && _videoController != null
          ? _buildVideo()
          : _buildFallback(),
    );
  }

  Widget _buildVideo() {
    final controller = _videoController!;
    // contain + slight scale: larger than pure fit, milder crop than cover.
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Transform.scale(
          scale: 1.18,
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.center,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallback() {
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    final logoW = shortest * 0.38;
    final splashW = shortest * 0.72;

    return Center(
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
                .fadeOut(duration: 800.ms, delay: 2000.ms),
          ),
          if (_showFallbackText)
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
    );
  }
}
