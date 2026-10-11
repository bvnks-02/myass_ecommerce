// MYAZZ UI — design tokens (Flutter). Drop into lib/theme/myazz_tokens.dart
import 'package:flutter/material.dart';

class M {
  M._();

  // Surfaces
  static const bgTop = Color(0xFFF7F6F4);
  static const bgMid = Color(0xFFFFFFFF);
  static const bgBottom = Color(0xFFF1F0EE);
  static const glass = Color(0x9EFFFFFF); // ~.62 (--lg-glass-card)
  static const glassStrong = Color(0xD1FFFFFF); // ~.82
  static const glassBorder = Color(0xF2FFFFFF); // ~.95 (--lg-edge-card)
  static const glassInner = Color(0x80FFFFFF); // ~.5

  // ── Silk background (luxury-glass-ui §1 / --lg-bg, --lg-silk) ──
  // Root layer painted ONCE (lib/theme/silk_background.dart): diagonal
  // cream→near-white→sand base + soft ellipse washes + gold light curves.
  static const silkBg = Color(0xFFF7F3EB); // --lg-bg base tone
  static const silkBase = LinearGradient(
    // --lg-silk linear layer: 135° warm cream → near-white → sand
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF4EDE1),
      Color(0xFFFDFBF7),
      Color(0xFFEDE2CF),
      Color(0xFFFFFDFA),
      Color(0xFFE4D5BC),
    ],
    stops: [0, .30, .60, .85, 1],
  );
  static const silkGlowTop = Color(0xE6FFF6E6); // radial @50%/32% rgba(255,246,230,.9)
  static const silkSandLow = Color(0x99E6D2B4); // radial @10%/80% rgba(230,210,180,.6)
  static const silkEllipseWhite = Color(0xE6FFFFFF); // blur-layer ellipse @75%/35%
  static const silkEllipseSand = Color(0x59D2B991); // blur-layer ellipse @20%/75% rgba(210,185,145,.35)

  // Gold light-curve stroke gradients (transparent → #e8be6c → #fff4cf →
  // transparent so the lines "emerge" and "dissolve"). Per-path opacity is
  // baked in by the painter.
  static const curveGold1 = [
    Color(0x00CAA056),
    Color(0xF2E8BE6C), // #e8be6c @ .95
    Color(0xFFFFF4CF), // #fff4cf @ 1
    Color(0x00C69A4D),
  ];
  static const curveGold1Stops = [0.0, .40, .70, 1.0];
  static const curveGold2 = [
    Color(0x00ECD18B),
    Color(0xCCDFAD51), // #dfad51 @ .8
    Color(0x00B68233),
  ];
  static const curveGold2Stops = [0.0, .50, 1.0];

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

  // Gold — luxury navbar family (lib/core/widgets/liquid_nav_bar.dart).
  // Exact reference values kept on purpose: visual fidelity beats token
  // purity — do NOT retune these toward gold1–gold4.
  static const goldNavBar = Color(0xFFD4A94A); // rim refraction / underglow
  static const goldNavBarLight = Color(0xFFE2AB44); // active underline core
  static const goldNavBarDark = Color(0xFF915A0F); // active underline ends

  // Ink
  static const ink = Color(0xFF14161A);
  static const ink2 = Color(0xFF5B6068);
  static const ink3 = Color(0xFF9AA0A8);
  static const heart = Color(0xFFE5484D);

  // Ink-gold (luxury-glass-ui §4 — text on chip/badge gold, never large text)
  static const inkGold = Color(0xFF79571E); // --lg-ink-gold (chip text)
  static const inkGoldLabel = Color(0xFF9C6C1F); // --lg-ink-gold-label (badge text)

  // Chips / badges (luxury-glass-ui §3–§4)
  static const chipGoldBg = Color(0xE6FFF1D6); // --lg-chip-gold-bg rgba(255,241,214,.9)
  static const chipGoldBorder = Color(0x73DCB772); // --lg-chip-gold-border rgba(220,183,114,.45)
  static const badgeGoldBg = Color(0x38EBB95D); // --lg-badge-bg rgba(235,185,93,.22)
  static const goldRim = Color(0x6BDCB673); // --lg-gold-rim rgba(220,182,115,.42)

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

  // Shadows — WARM tinted only (skill rule: rgba(162,133,85,…)-family browns,
  // never neutral black, or the cream palette goes grey).
  static const cardShadow = [
    BoxShadow(color: Color(0x14A08250), blurRadius: 30, offset: Offset(0, 10)),
    BoxShadow(color: Color(0x0AA08250), blurRadius: 6, offset: Offset(0, 2)),
  ];

  // --lg-shadow-card (0 15px 35px -10px rgba(160,130,80,.12)) + a tight warm
  // contact tier — the glass-card shadow stack (luxury-glass-ui §3).
  static const lgCardShadow = [
    BoxShadow(color: Color(0x1FA08250), blurRadius: 35, offset: Offset(0, 15), spreadRadius: -10),
    BoxShadow(color: Color(0x14A08250), blurRadius: 8, offset: Offset(0, 3), spreadRadius: -3),
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

  // Luxury-glass type scale (skill §7 — Inter kept per project hard rule;
  // the skill's SIZE/WEIGHT/TRACKING relationships applied on top of it).
  /// Card title — 21/700, tracking −.02em, tight.
  static const cardTitle = TextStyle(fontFamily: fontLat, fontSize: 21, fontWeight: FontWeight.w700, letterSpacing: -0.42, color: ink, height: 1.15);
  /// Big metric — 26/700, tight.
  static const metric = TextStyle(fontFamily: fontLat, fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: ink, height: 1.1);
  /// One-line card description — 13.5, ink2, line-height 1.45.
  static const cardDesc = TextStyle(fontFamily: fontLat, fontSize: 13.5, fontWeight: FontWeight.w400, color: ink2, height: 1.45);
  /// Micro badge — 11/700 UPPERCASE, tracking .08em, ink-gold-label.
  static const microBadge = TextStyle(fontFamily: fontLat, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.9, color: inkGoldLabel, height: 1.2);
  /// Gold chip label — 12/600 ink-gold on chip-gold-bg.
  static const chipLabel = TextStyle(fontFamily: fontLat, fontSize: 12, fontWeight: FontWeight.w600, color: inkGold, height: 1.2);
  /// Tab/rail label — 12.5/600, tracking −.01em (active: w700).
  static const railLabel = TextStyle(fontFamily: fontLat, fontSize: 12.5, fontWeight: FontWeight.w600, letterSpacing: -0.125, color: ink);
}
