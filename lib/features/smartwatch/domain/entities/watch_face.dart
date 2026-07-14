import 'package:flutter/material.dart';

/// Visual style used by [WatchFacePreview] to render a face without needing any
/// image assets.
enum WatchFaceStyle { digital, analog }

/// A selectable watch face for the smart-watch faces gallery.
class WatchFace {
  final String id;
  final String name;
  final WatchFaceStyle style;
  final List<Color> backgroundGradient;
  final Color accent;

  const WatchFace({
    required this.id,
    required this.name,
    required this.style,
    required this.backgroundGradient,
    required this.accent,
  });

  /// Built-in face catalogue (dark-luxe styled, matching the app theme).
  static const List<WatchFace> catalog = [
    WatchFace(
      id: 'noir',
      name: 'Noir Minimal',
      style: WatchFaceStyle.digital,
      backgroundGradient: [Color(0xFF0A0A0A), Color(0xFF1C1C1E)],
      accent: Colors.white,
    ),
    WatchFace(
      id: 'or',
      name: 'Luxe Or',
      style: WatchFaceStyle.analog,
      backgroundGradient: [Color(0xFF1A1407), Color(0xFF2E2410)],
      accent: Color(0xFFE7C873),
    ),
    WatchFace(
      id: 'sport',
      name: 'Sport Néon',
      style: WatchFaceStyle.digital,
      backgroundGradient: [Color(0xFF04121A), Color(0xFF08303F)],
      accent: Color(0xFF33E0C9),
    ),
    WatchFace(
      id: 'classique',
      name: 'Classique',
      style: WatchFaceStyle.analog,
      backgroundGradient: [Color(0xFF14181F), Color(0xFF20262F)],
      accent: Color(0xFFBFC7D5),
    ),
    WatchFace(
      id: 'rubis',
      name: 'Rubis',
      style: WatchFaceStyle.digital,
      backgroundGradient: [Color(0xFF1A0708), Color(0xFF3A0F12)],
      accent: Color(0xFFE7556A),
    ),
    WatchFace(
      id: 'aurore',
      name: 'Aurore',
      style: WatchFaceStyle.analog,
      backgroundGradient: [Color(0xFF0B0A1E), Color(0xFF241B4A)],
      accent: Color(0xFF9B8CFF),
    ),
  ];
}
