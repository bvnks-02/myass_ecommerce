import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../theme/myazz_tokens.dart';
import 'press_scale.dart';

/// Luxury liquid-glass bottom navbar — port of the user-supplied reference
/// (myazz-ui/assets/navbar_flutter_reference.dart, visual spec in
/// navbar_reference.html). Fixed-size artwork by design: 94-tall pill,
/// radius 50, blur 25, vertical white glass gradient, gold rim + white
/// hairline borders, top specular line, warm drop shadows and a gold
/// underline indicator under the active tab.
///
/// Tabs (left→right): Home · Health · Sports (center gold coin) · Messages ·
/// Profile. [badges] carries per-tab counts (e.g. `{3: unread}` for the
/// Messages delta) rendered as a gold chip over the icon.
///
/// Adapted from the reference: `withOpacity` → `withValues`, `_WatchPainter`
/// method-name typo fixed, per-tab [PressScale] dip instead of a bare
/// GestureDetector, gold badge chip, and a coin bloom pulse that honors
/// [MediaQuery.disableAnimations]. Geometry, gradients and artwork colors
/// are verbatim (values stay exact — see M.goldNavBar* tokens).
class LuxuryGlassNavbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Optional per-tab badge counts (index → count). Count 0 renders nothing.
  final Map<int, int> badges;

  const LuxuryGlassNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.badges = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 94,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        // Gold rim refraction (HTML spec: 0 0 0 1px rgba(220,182,115,.42)).
        border: const Border.fromBorderSide(
          BorderSide(color: Color(0x6BDCB673), width: 1),
        ),
        boxShadow: [
          // Deep ambient warm drop shadow
          BoxShadow(
            color: const Color(0xFFA28555).withValues(alpha: 0.25),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
          // Subtle gold underglow
          BoxShadow(
            color: M.goldNavBar.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              // Liquid glass reflection gradient (vertical, white)
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.88),
                  Colors.white.withValues(alpha: 0.55),
                  const Color(0xFFFDF8F0).withValues(alpha: 0.78),
                ],
              ),
              // White hairline border
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.95),
                width: 1.5,
              ),
            ),
            child: Stack(
              children: [
                // Top specular highlight line
                Positioned(
                  top: 2,
                  left: 45,
                  right: 45,
                  child: Container(
                    height: 1.5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.95),
                          const Color(0xFFFFF6D8),
                          Colors.white.withValues(alpha: 0.95),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Nav items
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTab(0, 'Home', const LuxuryWatchIcon()),
                    _buildTab(1, 'Health', const HealthBandIcon()),
                    _buildTab(2, 'Sports', const Sports3DBadge()),
                    _buildTab(3, 'Messages', const MessagesDeltaIcon()),
                    _buildTab(4, 'Profile', const ProfileIcon()),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(int index, String label, Widget iconWidget) {
    final bool isActive = currentIndex == index;
    final int badge = badges[index] ?? 0;

    return Expanded(
      // PressScale dip (~.96) replaces the reference's bare GestureDetector;
      // opaque behavior keeps the full-width tab column tappable.
      child: PressScale(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 48,
              width: 48,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  iconWidget,
                  if (badge > 0)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: _NavBadge(count: badge),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: M.fontLat,
                fontSize: 12.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                color: M.ink,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 3),
            // Gold active indicator (AnimatedOpacity per the reference).
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isActive ? 1.0 : 0.0,
              child: Container(
                width: 32,
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [
                      M.goldNavBarDark,
                      M.goldNavBarLight,
                      M.goldNavBarDark,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFC88C1E).withValues(alpha: 0.5),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gold unread-count chip rendered on/above a tab icon (Messages).
/// myazz-ui badge convention: gold fill, INK text, white ring.
class _NavBadge extends StatelessWidget {
  const _NavBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      decoration: BoxDecoration(
        color: M.gold2,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: M.ink.withValues(alpha: 0.18),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        count > 9 ? '9+' : '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: M.ink, // ink on gold (myazz-ui rule)
          fontSize: 9,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
      ),
    );
  }
}

// =============================================================================
// ASSET 1: LUXURY SMARTWATCH (HOME)
// =============================================================================
class LuxuryWatchIcon extends StatelessWidget {
  const LuxuryWatchIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size(44, 44),
      painter: _WatchPainter(),
    );
  }
}

class _WatchPainter extends CustomPainter {
  const _WatchPainter();

  // Reference bug fixed on port: method was declared `void Paint(...)`
  // (capital P), shadowing the Paint type and breaking compilation.
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer golden glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFEBC373).withValues(alpha: 0.5),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius + 4));
    canvas.drawCircle(center, radius + 4, glowPaint);

    // Watch strap stubs
    final strapPaint = Paint()..color = const Color(0xFF181A1D);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(center.dx - 6, 0, 12, 6), const Radius.circular(2)),
      strapPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(center.dx - 6, size.height - 6, 12, 6),
          const Radius.circular(2)),
      strapPaint,
    );

    // Gold Bezel
    final bezelPaint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFFFF8DB),
          Color(0xFFD4A34B),
          Color(0xFF8D621B),
          Color(0xFFE8BF69),
          Color(0xFFFFF8DB),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius - 2));
    canvas.drawCircle(center, radius - 2, bezelPaint);

    // Watch Pushers
    final crownPaint = Paint()..color = const Color(0xFFD4A34B);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width - 2, center.dy - 3, 2.5, 6),
          const Radius.circular(1)),
      crownPaint,
    );

    // Dial background
    final dialPaint = Paint()..color = const Color(0xFF0F1115);
    canvas.drawCircle(center, radius - 4.5, dialPaint);

    // Subdials
    final subDialPaint = Paint()
      ..color = const Color(0xFFD4A34B).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(Offset(center.dx, center.dy - 7), 3.8, subDialPaint);
    canvas.drawCircle(Offset(center.dx - 6, center.dy + 4), 3.4, subDialPaint);
    canvas.drawCircle(Offset(center.dx + 6, center.dy + 4), 3.4, subDialPaint);

    // Hour Markers
    final dotPaint = Paint()..color = const Color(0xFFFFF6D2);
    canvas.drawCircle(Offset(center.dx, center.dy - 12), 1.2, dotPaint);
    canvas.drawCircle(Offset(center.dx, center.dy + 12), 1.2, dotPaint);
    canvas.drawCircle(Offset(center.dx - 12, center.dy), 1.2, dotPaint);
    canvas.drawCircle(Offset(center.dx + 12, center.dy), 1.2, dotPaint);

    // Hands
    final handPaint = Paint()
      ..color = const Color(0xFFF6DC98)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, Offset(center.dx - 5, center.dy - 5), handPaint);

    final minutePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, Offset(center.dx + 7, center.dy - 2), minutePaint);

    // Center pivot
    canvas.drawCircle(center, 1.8, Paint()..color = const Color(0xFFD4A34B));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =============================================================================
// ASSET 2: HEALTH WOVEN BAND WITH RED PULSE
// =============================================================================
class HealthBandIcon extends StatelessWidget {
  const HealthBandIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size(36, 44),
      painter: _HealthBandPainter(),
    );
  }
}

class _HealthBandPainter extends CustomPainter {
  const _HealthBandPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // 1. Curved loop of the woven strap
    final strapPath = Path()
      ..moveTo(size.width * 0.45, size.height * 0.12)
      ..cubicTo(
        size.width * 0.85,
        size.height * 0.12,
        size.width * 0.95,
        size.height * 0.35,
        size.width * 0.95,
        size.height * 0.58,
      )
      ..cubicTo(
        size.width * 0.95,
        size.height * 0.82,
        size.width * 0.80,
        size.height * 0.92,
        size.width * 0.45,
        size.height * 0.92,
      )
      ..cubicTo(
        size.width * 0.20,
        size.height * 0.92,
        size.width * 0.15,
        size.height * 0.80,
        size.width * 0.15,
        size.height * 0.65,
      );

    final strapPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF141518), Color(0xFF32363E), Color(0xFF15161A)],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(strapPath, strapPaint);

    // Front loop body
    final frontLoopRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.14, size.height * 0.20, 14, 28),
      const Radius.circular(5),
    );
    canvas.drawRRect(frontLoopRect, Paint()..color = const Color(0xFF1F2228));

    // 2. Metallic clasp / sensor clip
    final claspRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.40, size.height * 0.18, 7.5, 30),
      const Radius.circular(3),
    );
    final claspPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF7E848D), Color(0xFF27292D), Color(0xFF565B65)],
      ).createShader(claspRect.outerRect);
    canvas.drawRRect(claspRect, claspPaint);

    // Sensor inner face
    final sensorInner = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.43, size.height * 0.26, 4.5, 18),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(sensorInner, Paint()..color = const Color(0xFF101214));

    // 3. Red heartbeat ECG line
    final pulsePath = Path()
      ..moveTo(size.width * 0.47, size.height * 0.30)
      ..lineTo(size.width * 0.47, size.height * 0.33)
      ..lineTo(size.width * 0.43, size.height * 0.35)
      ..lineTo(size.width * 0.51, size.height * 0.37)
      ..lineTo(size.width * 0.45, size.height * 0.39)
      ..lineTo(size.width * 0.47, size.height * 0.41)
      ..lineTo(size.width * 0.47, size.height * 0.44);

    final pulsePaint = Paint()
      ..color = const Color(0xFFFF3333)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(pulsePath, pulsePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =============================================================================
// ASSET 3: 3D GOLDEN SPORTS BADGE (center coin, pulsing golden bloom)
// =============================================================================
class Sports3DBadge extends StatefulWidget {
  const Sports3DBadge({super.key});

  @override
  State<Sports3DBadge> createState() => _Sports3DBadgeState();
}

class _Sports3DBadgeState extends State<Sports3DBadge>
    with SingleTickerProviderStateMixin {
  // HTML spec: golden-pulse 3s infinite ease-in-out (scale 1→1.15, .85→1).
  // repeat(reverse) over 1.5s gives the same 3s round trip.
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Honor the OS "remove animations" setting: full static bloom instead.
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
      _pulse.value = 1;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Pulsing golden bloom behind the coin
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              final double t = Curves.easeInOut.transform(_pulse.value);
              return Transform.scale(
                scale: 1 + 0.15 * t,
                child: Opacity(
                  opacity: 0.85 + 0.15 * t,
                  child: child,
                ),
              );
            },
            child: Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFEBB94B).withValues(alpha: 0.60),
                    const Color(0xFFDCA02D).withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 0.72],
                ),
              ),
            ),
          ),
          const _SportsCoin(),
        ],
      ),
    );
  }
}

/// The 3D convex metallic coin itself (reference Sports3DBadge container).
class _SportsCoin extends StatelessWidget {
  const _SportsCoin();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          // Outer bloom glow
          BoxShadow(
            color: const Color(0xFFEBB95D).withValues(alpha: 0.55),
            blurRadius: 16,
            spreadRadius: 2,
          ),
          // Deep drop shadow
          BoxShadow(
            color: const Color(0xFF99660F).withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        // 3D convex metallic radial gradient
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.3),
          radius: 0.85,
          colors: [
            Color(0xFFFFFBE6),
            Color(0xFFF1BE61),
            Color(0xFFB57A1B),
            Color(0xFF7E5008),
          ],
          stops: [0.0, 0.32, 0.75, 1.0],
        ),
        border: Border.all(
          color: const Color(0xFFFFF5D2),
          width: 1.8,
        ),
      ),
      child: const Center(
        child: CustomPaint(
          size: Size(36, 14),
          painter: _SportsWordmarkPainter(),
        ),
      ),
    );
  }
}

class _SportsWordmarkPainter extends CustomPainter {
  const _SportsWordmarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'sports',
        style: TextStyle(
          color: Color(0xFF0C1017), // artwork ink — stays literal
          fontSize: 11.2,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          letterSpacing: -0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Center text perfectly
    final offset = Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2,
    );
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =============================================================================
// ASSET 4: MESSAGES ORIGAMI DELTA ARROW WITH SLIT
// =============================================================================
class MessagesDeltaIcon extends StatelessWidget {
  const MessagesDeltaIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size(26, 26),
      painter: _MessagesDeltaPainter(),
    );
  }
}

class _MessagesDeltaPainter extends CustomPainter {
  const _MessagesDeltaPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Solid delta arrow shape
    final path = Path()
      ..moveTo(w * 0.22, h * 0.26)
      ..cubicTo(w * 0.18, h * 0.26, w * 0.16, h * 0.30, w * 0.18, h * 0.34)
      ..lineTo(w * 0.47, h * 0.82)
      ..cubicTo(w * 0.49, h * 0.85, w * 0.53, h * 0.85, w * 0.55, h * 0.82)
      ..lineTo(w * 0.84, h * 0.34)
      ..cubicTo(w * 0.86, h * 0.30, w * 0.84, h * 0.26, w * 0.78, h * 0.26)
      ..close();

    final paint = Paint()
      ..color = const Color(0xFF0C1017) // artwork ink — stays literal
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);

    // Diagonal origami slit
    final slitPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.34, h * 0.58),
      Offset(w * 0.62, h * 0.38),
      slitPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =============================================================================
// ASSET 5: MINIMAL PROFILE OUTLINE
// =============================================================================
class ProfileIcon extends StatelessWidget {
  const ProfileIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size(26, 26),
      painter: _ProfilePainter(),
    );
  }
}

class _ProfilePainter extends CustomPainter {
  const _ProfilePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = const Color(0xFF0C1017) // artwork ink — stays literal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);

    // Head
    canvas.drawCircle(Offset(center.dx, size.height * 0.32), 4.8, strokePaint);

    // Shoulders arc
    final shoulderPath = Path()
      ..moveTo(size.width * 0.16, size.height * 0.84)
      ..cubicTo(
        size.width * 0.16,
        size.height * 0.62,
        size.width * 0.32,
        size.height * 0.54,
        size.width * 0.50,
        size.height * 0.54,
      )
      ..cubicTo(
        size.width * 0.68,
        size.height * 0.54,
        size.width * 0.84,
        size.height * 0.62,
        size.width * 0.84,
        size.height * 0.84,
      );
    canvas.drawPath(shoulderPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
