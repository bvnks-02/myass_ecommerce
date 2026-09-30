// ignore_for_file: deprecated_member_use

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Myazz LIGHT theme — mirrors the website palette
/// (myazz-ecomerce/web/src/app/globals.css). Warm ivory canvas, white
/// surfaces, muted gold-bronze accent, dark-pill CTAs.
///
/// ── Legacy name → light mapping (names kept for API compatibility) ──
///  blackColor         → fg #1A1A16. Historically the dark scaffold bg; it is
///                         now the "on-accent"/pill color (ivory text on it).
///  cardColor          → surface #FFFFFF (cards).
///  cardColorSecondary → surface-2 #F2F1EC (raised tiles / inputs).
///  primaryColor       → fg #1A1A16. Website primary CTAs are dark pills with
///                         ivory text, and prices render in fg — so the legacy
///                         "primary" maps to fg, NOT to the gold accent.
///  secondaryColor     → fg #1A1A16 (was the dark theme's main text color).
///  gradientStart/End  → surface → surface-2 (subtle light card gradient).
///
///  Decorative accents (focus rings, active/selected states, spinners, small
///  bullets) should use [accent] #9C8A5E, matching the website.
class AppTheme {
  // ── Website tokens (source of truth: globals.css) ──
  static const Color bg = Color(0xFFFAF9F5); // warm ivory canvas
  static const Color surface = Color(0xFFFFFFFF); // cards
  static const Color surface2 = Color(0xFFF2F1EC); // raised tiles / inputs
  static const Color fg = Color(0xFF1A1A16); // primary text (warm near-black)
  static const Color silver = Color(0xFF72716A); // secondary text
  static const Color dim = Color(0xFF9D9C94); // hints / placeholders
  static const Color line = Color(0xFFE4E2DB); // hairline borders
  static const Color lineSoft = Color(0xFFEEEDE8); // softer hairline
  static const Color accent = Color(0xFF9C8A5E); // muted gold-bronze
  static const Color accentDim = Color(0xFFB8A87E);
  static const Color danger = Color(0xFFC44040);
  static const Color success = Color(0xFF3A8A4A);

  // ── Legacy API (kept — do not remove/rename) ──
  static const Color blackColor = fg;
  static const Color cardColor = surface;
  static const Color cardColorSecondary = surface2;
  static const Color primaryColor = fg; // dark-pill CTAs / fg emphasis
  static const Color secondaryColor = fg;
  static const Color gradientStart = surface;
  static const Color gradientEnd = surface2;

  /// NOTE: getter name kept (`darkTheme`) for API compatibility — it now
  /// returns the LIGHT theme.
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: bg,
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
        backgroundColor: bg,
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
          backgroundColor: fg, // dark pill, ivory text (website CTA)
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
          backgroundColor: surface, // website secondary button
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
          borderRadius: BorderRadius.circular(16),
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
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      border: Border.all(color: line, width: 1),
    );
  }

  // ── Glassmorphism system ──
  // Real frosted glass = ClipRRect + BackdropFilter blur + translucent white
  // fill + hairline border + soft warm shadow. Use [glass] for the full
  // widget stack; [glassDecoration] is the BoxDecoration counterpart (pair it
  // with your own ClipRRect + BackdropFilter — a fill alone is NOT glass).
  //
  // Rules of thumb:
  //  • Glass only reads over layered/colorful content (imagery, scrolling
  //    lists). On the flat ivory canvas, prefer solid [surface] + [line].
  //  • Keep blurred regions tight, wrap them in a RepaintBoundary, and never
  //    exceed sigma ~18.

  /// Standard frosted fill — white at 62% over light content.
  static Color get glassFill => Colors.white.withValues(alpha: 0.62);

  /// Sheerer frost (white 40%) for chips/bars over darker photography —
  /// lets more of the image bleed through.
  static Color get glassFillSheer => Colors.white.withValues(alpha: 0.40);

  /// Soft warm shadow that lifts a glass panel off the content behind it.
  static BoxShadow get glassShadow => BoxShadow(
        color: fg.withValues(alpha: 0.10),
        blurRadius: 24,
        offset: const Offset(0, 8),
      );

  /// Frosted-glass panel: ClipRRect + BackdropFilter blur + translucent
  /// white fill + hairline border + warm shadow, isolated in its own
  /// RepaintBoundary so scrolling content behind it repaints independently.
  ///
  /// [fill] defaults to [glassFill]; pass [glassFillSheer] over photography.
  /// [corners] overrides [radius] for non-uniform rounding (e.g. a bar that
  /// only rounds its top edge).
  static Widget glass({
    required Widget child,
    double radius = 20,
    double sigma = 16,
    Color? fill,
    BorderRadius? corners,
    Color? borderColor,
    bool shadow = true,
  }) {
    final BorderRadius borderRadius =
        corners ?? BorderRadius.circular(radius);
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: shadow ? [glassShadow] : null,
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: fill ?? glassFill,
                borderRadius: borderRadius,
                border: Border.all(
                  color: borderColor ?? line,
                  width: 1,
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  /// BoxDecoration counterpart of [glass] — the frosted white fill with a
  /// hairline border and warm shadow. Must be combined with a
  /// ClipRRect + BackdropFilter (see [glass]) to actually frost; on its own
  /// it is just a translucent panel.
  static BoxDecoration get glassDecoration {
    return BoxDecoration(
      color: glassFill,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: line,
        width: 1,
      ),
      boxShadow: [glassShadow],
    );
  }

  static BoxShadow get cardShadow {
    // Soft warm shadow — subtle depth on the ivory canvas.
    return BoxShadow(
      color: fg.withValues(alpha: 0.06),
      blurRadius: 20,
      offset: const Offset(0, 6),
    );
  }
}
