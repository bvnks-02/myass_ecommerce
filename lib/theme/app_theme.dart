// ignore_for_file: deprecated_member_use

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'myazz_tokens.dart';

/// Myazz "Luminous Glass & Gold" theme — the app-level mapping of the
/// myazz-ui design tokens ([M], lib/theme/myazz_tokens.dart — the single
/// source of truth for values).
///
/// ── Legacy name → token mapping (names kept for API compatibility) ──
///  bg                   → pearl #F4F3F1 (solid scaffold base; the SILK root
///                         background — luxury-glass-ui §1 — is painted once
///                         by SilkBackground at the app root; scaffolds are
///                         transparent so glass refracts the silk).
///  surface              → M.bgMid #FFFFFF (cards).
///  surface2             → M.bgBottom #F1F0EE (raised tiles / inputs).
///  fg / blackColor /
///  primaryColor         → M.ink #14161A (primary text, dark-pill CTAs).
///  silver               → M.ink2 #5B6068 (secondary text).
///  dim                  → M.ink3 #9AA0A8 (hints / inactive).
///  accent               → M.gold3 #C99A3C (champagne gold, deep core —
///                         active states, focus rings, spinners).
///  accentBright         → M.gold2 #E3BC63 (gold fills; pair with ink text).
///  accentDim            → M.gold2 (legacy alias, on-dark gold text).
///  accentLegacy         → the old bronze #9C8A5E, kept as an alias only.
///
///  Gold is the ONLY accent color (myazz-ui hard rule). Semantic states
///  (success/danger) stay muted and never replace gold on primary actions.
class AppTheme {
  // ── myazz-ui tokens (source of truth: M) ──
  static const Color pearl = Color(0xFFF4F3F1); // --m-bg solid base
  static const Color bg = pearl; // scaffold base / ivory-on-dark text
  static const Color surface = M.bgMid; // cards (white)
  static const Color surface2 = M.bgBottom; // raised tiles / inputs
  static const Color fg = M.ink; // primary text (cool near-black)
  static const Color silver = M.ink2; // secondary text
  static const Color dim = M.ink3; // hints / placeholders / inactive
  static const Color line = Color(0xFFE4E2DB); // hairline borders (solid surfaces)
  static const Color lineSoft = Color(0xFFEEEDE8); // softer hairline
  static const Color accent = M.gold3; // champagne gold core (deep)
  static const Color accentBright = M.gold2; // champagne gold (fills, ink text)
  static const Color accentDim = M.gold2; // legacy alias → gold2
  static const Color goldDeep = M.gold4; // gold-4: icons/text on gold fills
  static const Color goldLight = M.gold1; // gold-1: highlights
  static const Color accentLegacy = Color(0xFF9C8A5E); // old bronze (alias only)
  static const Color danger = Color(0xFFC44040);
  static const Color success = Color(0xFF3A8A4A);

  // ── Gold + night systems (myazz-ui) ──
  static const LinearGradient goldGradient = M.goldGradient; // 4-stop champagne
  static const LinearGradient goldSoft = M.goldSoft; // active nav pill fill
  static const List<BoxShadow> goldGlow = M.goldGlow; // glow, active/primary only
  static const LinearGradient nightGradient = M.nightGradient; // dark contrast cards

  // ── Glass tokens ──
  static const Color glassBorder = M.glassBorder; // white .95 hairline edge (--lg-edge-card)
  static const Color glassInner = M.glassInner; // white .5 inner highlight

  // ── luxury-glass-ui (--lg-*) delegates — source of truth: M ──
  static const Color inkGold = M.inkGold; // chip text (§4)
  static const Color inkGoldLabel = M.inkGoldLabel; // badge text (§3)
  static const Color chipGoldBg = M.chipGoldBg; // gold chip fill (§4)
  static const Color chipGoldBorder = M.chipGoldBorder; // gold chip border (§4)
  static const Color badgeGoldBg = M.badgeGoldBg; // card badge fill (§3)
  static const Color goldRim = M.goldRim; // hairline gold outer rim
  static const LinearGradient silkBase = M.silkBase; // root silk gradient (§1)
  static const List<BoxShadow> lgCardShadow = M.lgCardShadow; // --lg-shadow-card stack (§3)

  /// Pearl gradient — kept for API compatibility. The app root now paints the
  /// full silk treatment (SilkBackground, luxury-glass-ui §1) in the
  /// MaterialApp builder; scaffolds stay transparent so glass reads over it.
  static const LinearGradient pearlGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [M.bgTop, M.bgMid, M.bgBottom],
  );

  // ── Legacy API (kept — do not remove/rename) ──
  static const Color blackColor = fg;
  static const Color cardColor = surface;
  static const Color cardColorSecondary = surface2;
  static const Color primaryColor = fg; // dark-pill CTAs / ink emphasis
  static const Color secondaryColor = fg;
  static const Color gradientStart = surface;
  static const Color gradientEnd = surface2;

  /// NOTE: getter name kept (`darkTheme`) for API compatibility — it returns
  /// the LIGHT "Luminous Glass & Gold" theme. Scaffolds are transparent: the
  /// pearl gradient (MaterialApp builder) is the real root background.
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: Colors.transparent,
      cardColor: cardColor,
      colorScheme: ColorScheme.light(
        primary: fg,
        onPrimary: bg,
        secondary: accent,
        onSecondary: surface,
        error: danger,
        onError: surface,
        surface: surface,
        onSurface: fg,
        outline: line,
      ),
      iconTheme: const IconThemeData(color: fg),
      dividerColor: line,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: fg,
        titleTextStyle: TextStyle(
          color: fg,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
        iconTheme: IconThemeData(color: fg),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: fg, // dark pill, ivory text
          foregroundColor: bg,
          disabledBackgroundColor: dim,
          disabledForegroundColor: bg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999), // full pill
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: surface,
          foregroundColor: fg,
          side: const BorderSide(color: line, width: 1),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: fg,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(M.rTile),
          side: const BorderSide(color: line, width: 1),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: fg,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
        headlineMedium: TextStyle(
          color: fg,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
        headlineSmall: TextStyle(
          color: fg,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
        titleLarge: TextStyle(
          color: fg,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
        titleMedium: TextStyle(
          color: fg,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: 'Inter',
        ),
        bodyLarge: TextStyle(
          color: fg,
          fontSize: 16,
          fontFamily: 'Inter',
        ),
        bodyMedium: TextStyle(
          color: silver,
          fontSize: 14,
          fontFamily: 'Inter',
        ),
        bodySmall: TextStyle(
          color: dim,
          fontSize: 12,
          fontFamily: 'Inter',
        ),
        labelLarge: TextStyle(
          color: fg,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: 'Inter',
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: fg,
        unselectedItemColor: dim,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2, // raised input tile
        hintStyle: const TextStyle(
          color: dim,
          fontFamily: 'Inter',
        ),
        labelStyle: const TextStyle(color: silver, fontFamily: 'Inter'),
        floatingLabelStyle: const TextStyle(color: accent, fontFamily: 'Inter'),
        prefixIconColor: silver,
        suffixIconColor: silver,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: line, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: line, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: fg, // dark pill notification, ivory text
        contentTextStyle: TextStyle(color: bg, fontFamily: 'Inter'),
        actionTextColor: accentDim,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accent,
        circularTrackColor: Colors.transparent,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: surface,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
      ),
    );
  }

  static BoxDecoration get gradientDecoration {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [gradientStart, gradientEnd],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: const BorderRadius.all(Radius.circular(M.rTile)),
      border: Border.all(color: line, width: 1),
    );
  }

  // ── Glassmorphism system (myazz-ui "Luminous Glass" × luxury-glass-ui §3) ──
  // Real frosted glass = ClipRRect + BackdropFilter blur + translucent white
  // fill + diagonal sheen + hairline WHITE border (--lg-edge-card .95) + the
  // warm two-tier --lg-shadow-card stack.
  //  • standard: the full lg-card stack — fill .62, blur 24, radius 28.
  //  • strong:   fill .82, blur 32 — nav, sheets, modals (pass strong: true).
  // Budget: ≤6 blurred layers per screen; over FLAT backgrounds (e.g. inside
  // an opaque card) use a translucent fill WITHOUT blur (skip [glass], use a
  // plain Container + glassStrongFill + lgCardShadow + hairline border).

  /// Standard frosted fill — white at ~62% (--lg-glass-card).
  static Color get glassFill => M.glass;

  /// Strong frosted fill — white at ~82% (nav, sheets, modals).
  static Color get glassStrongFill => M.glassStrong;

  /// Sheerer frost (white 40%) for chips/bars over darker photography.
  static Color get glassFillSheer => Colors.white.withValues(alpha: 0.40);

  /// Soft long shadow that lifts a glass panel off the content behind it
  /// (first tier of the --lg-shadow-card stack).
  static BoxShadow get glassShadow => M.lgCardShadow[0];

  /// Frosted-glass panel: ClipRRect + BackdropFilter blur + translucent
  /// white fill + GlassCard-style diagonal sheen (white .35 → .05) + hairline
  /// white border + warm two-tier --lg-shadow-card shadow, isolated in its
  /// own RepaintBoundary.
  ///
  /// [strong] switches to the nav/sheet variant (fill .82, blur 32).
  /// [fill] overrides the fill; [corners] overrides [radius] for non-uniform
  /// rounding (e.g. a bar that only rounds its top edge).
  static Widget glass({
    required Widget child,
    double radius = M.rCard,
    double sigma = 24,
    bool strong = false,
    Color? fill,
    BorderRadius? corners,
    Color? borderColor,
    bool shadow = true,
    bool sheen = true,
  }) {
    final BorderRadius borderRadius =
        corners ?? BorderRadius.circular(radius);
    final double blur = strong ? 32 : sigma;
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: shadow ? M.lgCardShadow : null,
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: fill ?? (strong ? M.glassStrong : M.glass),
                borderRadius: borderRadius,
                border: Border.all(
                  color: borderColor ?? glassBorder,
                  width: 1,
                ),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  // GlassCard sheen: diagonal white highlight .35 → .05.
                  gradient: sheen
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0x59FFFFFF), Color(0x0DFFFFFF)],
                        )
                      : null,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Flat-background glass panel — the lg-card stack WITHOUT backdrop blur,
  /// for panels that sit ON an opaque surface (skill §9: glass on flat white
  /// refracts nothing, and the blur would cost a layer for free): translucent
  /// fill + white hairline + 1px gold outer rim (the nav-pill refraction
  /// edge — on a white card this is what delineates the panel) + warm
  /// two-tier --lg-shadow-card + diagonal sheen.
  static Widget glassFlat({
    required Widget child,
    double radius = M.rCard,
    Color? fill,
    bool sheen = true,
  }) {
    final BorderRadius borderRadius = BorderRadius.circular(radius);
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: fill ?? M.glassStrong,
          borderRadius: borderRadius,
          border: Border.all(color: glassBorder, width: 1),
          boxShadow: const [
            // 1px gold outer rim (--lg-gold-rim), nav-pill style.
            BoxShadow(
              color: M.goldRim,
              blurRadius: 0,
              offset: Offset.zero,
              spreadRadius: 1,
            ),
            ...M.lgCardShadow,
          ],
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              gradient: sheen
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0x59FFFFFF), Color(0x0DFFFFFF)],
                    )
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  /// BoxDecoration counterpart of [glass] — frosted white fill, hairline
  /// white border, warm --lg-shadow-card stack. Combine with ClipRRect +
  /// BackdropFilter to actually frost; on its own it is just a translucent
  /// panel.
  static BoxDecoration get glassDecoration {
    return BoxDecoration(
      color: M.glass,
      borderRadius: BorderRadius.circular(M.rCard),
      border: Border.all(
        color: glassBorder,
        width: 1,
      ),
      boxShadow: M.lgCardShadow,
    );
  }

  static BoxShadow get cardShadow {
    // Soft long shadow — warm first tier.
    return M.cardShadow[0];
  }

  /// Full two-tier warm card shadow (soft long + hairline contact).
  static List<BoxShadow> get cardShadows => M.cardShadow;
}

/// Champagne-gold gradient treatment for text/icons (myazz-ui "GoldShader").
/// Use with restraint: featured-hero + product-details prices, brand
/// wordmark — never on grid-card prices (those stay ink for calm).
class GoldShader extends StatelessWidget {
  const GoldShader({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (r) => M.goldGradient.createShader(r),
        child: child,
      );
}
