import 'package:flutter/material.dart';

import '../../../../core/utils/responsive_utils.dart';
import '../../../../theme/app_theme.dart';

/// Minimal brand placeholder screen (bottom-nav "Myazz" tab, route '/brand').
///
/// Intentionally sparse: the logo in an ivory tile on the warm canvas, the
/// wordmark, and a single French line. Replace the copy/CTA with the real
/// brand story when it's written.
class BrandScreen extends StatelessWidget {
  const BrandScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo in a clean ivory circle tile (logo.jpeg is not
              // transparent — the tile keeps it crisp on the canvas).
              Container(
                width: ResponsiveUtils.sw(context, 104),
                height: ResponsiveUtils.sw(context, 104),
                padding: EdgeInsets.all(ResponsiveUtils.sw(context, 8)),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.line, width: 1),
                  boxShadow: [AppTheme.cardShadow],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.jpeg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: ResponsiveUtils.sh(context, 24)),
              Text(
                'Myazz',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SizedBox(height: ResponsiveUtils.sh(context, 8)),
              Text(
                'Notre histoire, bientôt.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
