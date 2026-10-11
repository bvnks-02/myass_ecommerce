import 'package:flutter/material.dart';

import '../../../../core/utils/responsive_utils.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/myazz_tokens.dart';

/// Health placeholder screen (bottom-nav "Health" tab, route '/health') —
/// same minimal pattern as brand_screen.dart: transparent scaffold over the
/// root silk, one lg-card (AppTheme.glass) with the §3 content pattern
/// (micro badge → title → one-line description), one muted FR line.
///
/// Replace with the real health-tracking feature when it ships.
class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Transparent — the root pearl gradient shows through, so the glass
      // card has something to frost over (skill rule: glass needs a backdrop).
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.sw(context, 28)),
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
                    // §3 content pattern: micro badge → title → description.
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.sw(context, 10),
                        vertical: ResponsiveUtils.sh(context, 4),
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.badgeGoldBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'SANTÉ',
                        style: TextStyle(
                          color: AppTheme.inkGoldLabel,
                          fontSize: ResponsiveUtils.sf(context, 11),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.9, // .08em @ 11px
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.sh(context, 12)),
                    // Card title — 21/700, tracking −.02em (§7).
                    Text(
                      'Suivi santé',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.fg,
                        fontSize: ResponsiveUtils.sf(context, 21),
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.42,
                        height: 1.15,
                        fontFamily: 'Inter',
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.sh(context, 8)),
                    // Card description — 13.5, line-height 1.45 (§3/§7).
                    Text(
                      'Bientôt disponible.',
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
