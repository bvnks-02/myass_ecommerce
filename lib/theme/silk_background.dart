import 'package:flutter/material.dart';

import 'myazz_tokens.dart';

/// Root silk background — luxury-glass-ui §1 (the skill's #1 rule: glass only
/// reads when textured silk sits behind it).
///
/// Layers (bottom → top), all vector — no PNGs:
///  1. `--lg-silk` diagonal base: warm cream → near-white → sand at 135°
///     (plus the two radial washes from the same token),
///  2. the blurred white/sand ellipse layer (CSS `blur(20px)` over two huge
///     radial-gradient ellipses — the gradients are already smooth, so the
///     blur only softens their falloff; painted directly, no ImageFilter),
///  3. 2–3 thin gold light curves (stroke 1.2–2.5, gradient strokes fading
///     transparent → #e8be6c → #fff4cf → transparent).
///
/// Painted ONCE at the app root (MaterialApp builder) inside a
/// [RepaintBoundary]; it never animates and never repaints.
///
/// Curve routing (from reference-screen.html, viewBox 430×860, scaled
/// proportionally to the window): every curve ENTERS and EXITS through the
/// left/right screen edges (x runs from −80 to +490 of 430) so the strokes
/// sweep through the outer margins — the high pair crosses the upper third
/// above the content column, the low curve hugs the bottom edge beneath it.
/// Where a curve does pass behind a panel, the panel is either opaque (grid
/// cards) or frosted glass (headers, sheets, the nav pill) which blurs the
/// stroke — curves never sit directly behind raw text.
class SilkBackground extends StatelessWidget {
  const SilkBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: M.silkBase),
        // CustomPaint's `painter` draws BEHIND the child — the whole app
        // renders on top of the silk.
        child: CustomPaint(
          painter: const _SilkPainter(),
          child: child,
        ),
      ),
    );
  }
}

class _SilkPainter extends CustomPainter {
  const _SilkPainter();

  /// Reference geometry (reference-screen.html `.gold-lines` viewBox).
  static const double _refW = 430, _refH = 860;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // ── 1. --lg-silk radial washes ──
    // circle at 50% 32% — rgba(255,246,230,.9) → transparent @60%
    _radialWash(
      canvas,
      center: Offset(w * .50, h * .32),
      radius: _farthestCorner(Offset(w * .50, h * .32), size),
      color: M.silkGlowTop,
      fadeAt: .60,
    );
    // circle at 10% 80% — rgba(230,210,180,.6) → transparent @50%
    _radialWash(
      canvas,
      center: Offset(w * .10, h * .80),
      radius: _farthestCorner(Offset(w * .10, h * .80), size),
      color: M.silkSandLow,
      fadeAt: .50,
    );

    // ── 2. The blurred ellipse layer (::before) ──
    // ellipse 110%×70% at 75%/35% — white .9 → transparent @60%
    _ellipseWash(
      canvas,
      center: Offset(w * .75, h * .35),
      rx: w * 1.10,
      ry: h * .70,
      color: M.silkEllipseWhite,
      fadeAt: .60,
    );
    // ellipse 80%×50% at 20%/75% — rgba(210,185,145,.35) → transparent @60%
    _ellipseWash(
      canvas,
      center: Offset(w * .20, h * .75),
      rx: w * .80,
      ry: h * .50,
      color: M.silkEllipseSand,
      fadeAt: .60,
    );

    // ── 3. Gold light curves (§1) ──
    final double sx = w / _refW;
    final double sy = h / _refH;
    Offset p(double x, double y) => Offset(x * sx, y * sy);

    // High sweep: left edge mid-height → right edge upper third (2.5px, .75).
    final curveA = Path()
      ..moveTo(p(-80, 480).dx, p(-80, 480).dy)
      ..cubicTo(
        p(120, 400).dx, p(120, 400).dy,
        p(240, 230).dx, p(240, 230).dy,
        p(460, 190).dx, p(460, 190).dy,
      );
    // Its thin companion line (1.2px, .5).
    final curveB = Path()
      ..moveTo(p(-40, 500).dx, p(-40, 500).dy)
      ..cubicTo(
        p(150, 420).dx, p(150, 420).dy,
        p(270, 250).dx, p(270, 250).dy,
        p(490, 210).dx, p(490, 210).dy,
      );
    // Low curve near the bottom edge (2px, .55).
    final curveC = Path()
      ..moveTo(p(-60, 760).dx, p(-60, 760).dy)
      ..cubicTo(
        p(180, 680).dx, p(180, 680).dy,
        p(320, 790).dx, p(320, 790).dy,
        p(500, 600).dx, p(500, 600).dy,
      );

    canvas
      ..drawPath(curveA, _curveStroke(curveA, M.curveGold1, M.curveGold1Stops, 2.5, .75))
      ..drawPath(curveB, _curveStroke(curveB, M.curveGold2, M.curveGold2Stops, 1.2, .50))
      ..drawPath(curveC, _curveStroke(curveC, M.curveGold1, M.curveGold1Stops, 2.0, .55));
  }

  /// Stroke paint with the path's bounding box as the gradient frame (CSS
  /// objectBoundingBox x1=0,y1=0 → x2=1,y2=1). [opacity] is baked into the
  /// gradient stops' alpha, matching the SVG per-path `opacity` attribute.
  static Paint _curveStroke(
    Path path,
    List<Color> colors,
    List<double> stops,
    double strokeWidth,
    double opacity,
  ) {
    final bounds = path.getBounds();
    return Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          for (final c in colors) c.withValues(alpha: c.a * opacity),
        ],
        stops: stops,
      ).createShader(bounds);
  }

  static void _radialWash(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color color,
    required double fadeAt,
  }) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
          stops: [0, fadeAt],
        ).createShader(rect),
    );
  }

  static void _ellipseWash(
    Canvas canvas, {
    required Offset center,
    required double rx,
    required double ry,
    required Color color,
    required double fadeAt,
  }) {
    final rect = Rect.fromCenter(center: center, width: rx * 2, height: ry * 2);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
          stops: [0, fadeAt],
        ).createShader(rect),
    );
  }

  /// CSS radial-gradient default extent: farthest-corner.
  static double _farthestCorner(Offset c, Size size) {
    double d(double x, double y) => (c - Offset(x, y)).distance;
    return [
      d(0, 0),
      d(size.width, 0),
      d(0, size.height),
      d(size.width, size.height),
    ].reduce((a, b) => a > b ? a : b);
  }

  @override
  bool shouldRepaint(covariant _SilkPainter oldDelegate) => false;
}
