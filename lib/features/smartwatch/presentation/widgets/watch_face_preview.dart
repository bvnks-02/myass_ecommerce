import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/watch_face.dart';

/// Renders a [WatchFace] as a circular preview without any image assets.
/// Digital faces show the current time as text; analog faces draw hands/ticks.
class WatchFacePreview extends StatelessWidget {
  const WatchFacePreview({
    super.key,
    required this.face,
    this.size = 160,
    this.showTime = true,
  });

  final WatchFace face;
  final double size;
  final bool showTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: face.backgroundGradient,
        ),
        border: Border.all(color: face.accent.withValues(alpha: 0.35), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: face.style == WatchFaceStyle.digital
          ? _buildDigital()
          : CustomPaint(
              painter: _AnalogPainter(accent: face.accent, showTime: showTime),
            ),
    );
  }

  Widget _buildDigital() {
    final now = DateTime.now();
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            showTime ? DateFormat('HH:mm').format(now) : '10:09',
            style: TextStyle(
              color: face.accent,
              fontSize: size * 0.22,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: size * 0.03),
          Text(
            DateFormat('EEE d').format(now).toUpperCase(),
            style: TextStyle(
              color: face.accent.withValues(alpha: 0.7),
              fontSize: size * 0.08,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalogPainter extends CustomPainter {
  _AnalogPainter({required this.accent, required this.showTime});

  final Color accent;
  final bool showTime;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Hour ticks.
    final tickPaint = Paint()
      ..color = accent.withValues(alpha: 0.6)
      ..strokeWidth = 2;
    for (var i = 0; i < 12; i++) {
      final angle = (i * 30) * pi / 180;
      final outer = Offset(
        center.dx + (radius - 8) * sin(angle),
        center.dy - (radius - 8) * cos(angle),
      );
      final inner = Offset(
        center.dx + (radius - 16) * sin(angle),
        center.dy - (radius - 16) * cos(angle),
      );
      canvas.drawLine(inner, outer, tickPaint);
    }

    final now = showTime ? DateTime.now() : DateTime(2020, 1, 1, 10, 9);
    final hourAngle = ((now.hour % 12) + now.minute / 60) * 30 * pi / 180;
    final minuteAngle = now.minute * 6 * pi / 180;

    final hourPaint = Paint()
      ..color = accent
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(center.dx + radius * 0.45 * sin(hourAngle),
          center.dy - radius * 0.45 * cos(hourAngle)),
      hourPaint,
    );

    final minutePaint = Paint()
      ..color = accent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(center.dx + radius * 0.68 * sin(minuteAngle),
          center.dy - radius * 0.68 * cos(minuteAngle)),
      minutePaint,
    );

    canvas.drawCircle(center, 4, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(covariant _AnalogPainter oldDelegate) =>
      oldDelegate.accent != accent;
}
