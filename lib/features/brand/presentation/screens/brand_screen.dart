import 'package:flutter/material.dart';

import '../../../../core/utils/responsive_utils.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/myazz_tokens.dart';

/// Brand placeholder screen (bottom-nav "Myazz" tab, route '/brand') —
/// the showcase for the "Luminous Glass & Gold" language: silk root (via the
/// MaterialApp builder), one lg-card (AppTheme.glass), a gold-ring logo
/// medallion and a GoldShader wordmark — the screen's two gold moments
/// (the old third, a gold underline, was cut per luxury-glass-ui §5).
///
/// Replace the copy with the real brand story when it's written.
class BrandScreen extends StatelessWidget {
  const BrandScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Transparent — the root pearl gradient shows through, so the glass
      // card has something to frost over (skill rule: glass needs a backdrop).
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding:
                EdgeInsets.symmetric(horizontal: ResponsiveUtils.sw(context, 28)),
            child: AppTheme.glass(
              radius: M.rCard,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.sw(context, 24),
                  vertical: ResponsiveUtils.sh(context, 40),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo medallion — champagne-gold gradient ring around an
                    // ivory tile (logo.jpeg is not transparent; the tile keeps
                    // it crisp).
                    Container(
                      padding: EdgeInsets.all(ResponsiveUtils.sw(context, 3)),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: M.goldGradient,
                      ),
                      child: Container(
                        width: ResponsiveUtils.sw(context, 104),
                        height: ResponsiveUtils.sw(context, 104),
                        padding: EdgeInsets.all(ResponsiveUtils.sw(context, 6)),
                        decoration: const BoxDecoration(
                          color: AppTheme.surface,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/logo.jpeg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.sh(context, 24)),
                    // GoldShader wordmark — champagne gradient numerals/type.
                    const GoldShader(
                      child: Text(
                        'Myazz',
                        style: TextStyle(
                          color: Colors.white, // alpha carrier for the shader
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.sh(context, 10)),
                    // Card description — 13.5, line-height 1.45 (§3/§7).
                    Text(
                      'Notre histoire, bientôt.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.silver,
                        fontSize: ResponsiveUtils.sf(context, 13.5),
                        height: 1.45,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
