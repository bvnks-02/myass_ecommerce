// MYAZZ UI — design tokens (Flutter). Drop into lib/theme/myazz_tokens.dart
import 'package:flutter/material.dart';

class M {
  M._();

  // Surfaces
  static const bgTop = Color(0xFFF7F6F4);
  static const bgMid = Color(0xFFFFFFFF);
  static const bgBottom = Color(0xFFF1F0EE);
  static const glass = Color(0x9EFFFFFF); // ~.62
  static const glassStrong = Color(0xD1FFFFFF); // ~.82
  static const glassBorder = Color(0xE6FFFFFF); // ~.9
  static const glassInner = Color(0x80FFFFFF); // ~.5

  // Gold
  static const gold1 = Color(0xFFF7E3A1);
  static const gold2 = Color(0xFFE3BC63);
  static const gold3 = Color(0xFFC99A3C);
  static const gold4 = Color(0xFF8F6A1F);
  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gold1, gold2, gold3, gold4],
    stops: [0, .38, .72, 1],
  );
  static const goldSoft = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xE6F7E3A1), Color(0xBFC99A3C)],
  );

  // Ink
  static const ink = Color(0xFF14161A);
  static const ink2 = Color(0xFF5B6068);
  static const ink3 = Color(0xFF9AA0A8);
  static const heart = Color(0xFFE5484D);

  // Night
  static const night1 = Color(0xFF0C1424);
  static const night2 = Color(0xFF16233D);
  static const nightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [night1, night2],
  );

  // Radii
  static const rCard = 28.0;
  static const rTile = 20.0;
  static const rChip = 14.0;
  static const rPill = 999.0;

  // Spacing
  static const s1 = 4.0, s2 = 8.0, s3 = 12.0, s4 = 16.0, s5 = 20.0, s6 = 24.0, s8 = 32.0;

  // Shadows
  static const cardShadow = [
    BoxShadow(color: Color(0x141E222C), blurRadius: 30, offset: Offset(0, 10)),
    BoxShadow(color: Color(0x0A1E222C), blurRadius: 6, offset: Offset(0, 2)),
  ];
  static const goldGlow = [
    BoxShadow(color: Color(0x8CE3BC63), blurRadius: 18),
    BoxShadow(color: Color(0x40E3BC63), blurRadius: 48),
  ];

  // Motion
  static const easeOut = Cubic(.22, 1, .36, 1);
  static const spring = Cubic(.34, 1.56, .64, 1);
  static const d1 = Duration(milliseconds: 140);
  static const d2 = Duration(milliseconds: 260);
  static const d3 = Duration(milliseconds: 480);
  static const d4 = Duration(milliseconds: 900);

  // Type (add google_fonts: Tajawal + Inter)
  static const fontAr = 'Tajawal';
  static const fontLat = 'Inter';
  static const display = TextStyle(fontFamily: fontLat, fontSize: 56, fontWeight: FontWeight.w700, letterSpacing: -1.5, color: ink, height: 1);
  static const titleXl = TextStyle(fontFamily: fontAr, fontSize: 32, fontWeight: FontWeight.w800, color: ink);
  static const title = TextStyle(fontFamily: fontAr, fontSize: 22, fontWeight: FontWeight.w700, color: ink);
  static const body = TextStyle(fontFamily: fontAr, fontSize: 15, fontWeight: FontWeight.w500, color: ink2);
  static const caption = TextStyle(fontFamily: fontAr, fontSize: 12, fontWeight: FontWeight.w500, color: ink2);
  static const latinLabel = TextStyle(fontFamily: fontLat, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 3.1, color: ink2);
}
