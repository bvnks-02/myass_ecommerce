import 'package:flutter/material.dart';

import '../../../../core/utils/responsive_utils.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/myazz_tokens.dart';

/// Health placeholder screen (bottom-nav "Health" tab, route '/health') —
/// same minimal pattern as brand_screen.dart: transparent scaffold over the
/// root pearl gradient, one GlassCard, one muted FR line.
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
                    Text(
                      'Suivi santé, bientôt disponible.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
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
