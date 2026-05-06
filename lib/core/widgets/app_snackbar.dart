import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Snackbar types for consistent styling
enum SnackbarType {
  success,
  error,
  warning,
  info,
}

/// Configuration for each snackbar type
class SnackbarConfig {
  final IconData icon;
  final Color backgroundColor;
  final Color accentColor;

  const SnackbarConfig({
    required this.icon,
    required this.backgroundColor,
    required this.accentColor,
  });
}

/// Snackbar configurations
class SnackbarConfigs {
  static const Map<SnackbarType, SnackbarConfig> configs = {
    SnackbarType.success: SnackbarConfig(
      icon: Icons.check_circle_rounded,
      backgroundColor: Color(0xFF1B5E20),
      accentColor: Color(0xFF4CAF50),
    ),
    SnackbarType.error: SnackbarConfig(
      icon: Icons.error_rounded,
      backgroundColor: Color(0xFFB71C1C),
      accentColor: Color(0xFFEF5350),
    ),
    SnackbarType.warning: SnackbarConfig(
      icon: Icons.warning_amber_rounded,
      backgroundColor: Color(0xFFEF6C00),
      accentColor: Color(0xFFFFA726),
    ),
    SnackbarType.info: SnackbarConfig(
      icon: Icons.info_rounded,
      backgroundColor: Color(0xFF1565C0),
      accentColor: Color(0xFF42A5F5),
    ),
  };
}

/// Reusable modern snackbar
class AppSnackBar {
  static void show({
    required BuildContext context,
    required SnackbarType type,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    HapticFeedback.lightImpact();
    
    final config = SnackbarConfigs.configs[type]!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Clear any existing snackbars
    scaffoldMessenger.hideCurrentSnackBar();
    
    scaffoldMessenger.showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        content: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: config.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: config.accentColor.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: config.accentColor.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Left accent bar
              Container(
                width: 4,
                height: 56,
                decoration: BoxDecoration(
                  color: config.accentColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              
              // Icon
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  config.icon,
                  color: config.accentColor,
                  size: 24,
                ),
              ),
              
              // Message
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              
              // Action button
              if (actionLabel != null && onAction != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextButton(
                    onPressed: () {
                      scaffoldMessenger.hideCurrentSnackBar();
                      onAction();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: config.accentColor,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      actionLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Quick success snackbar
  static void success(BuildContext context, String message, {Duration duration = const Duration(seconds: 3)}) {
    show(
      context: context,
      type: SnackbarType.success,
      message: message,
      duration: duration,
    );
  }

  /// Quick error snackbar
  static void error(BuildContext context, String message, {Duration duration = const Duration(seconds: 4)}) {
    show(
      context: context,
      type: SnackbarType.error,
      message: message,
      duration: duration,
    );
  }

  /// Quick warning snackbar
  static void warning(BuildContext context, String message, {Duration duration = const Duration(seconds: 4)}) {
    show(
      context: context,
      type: SnackbarType.warning,
      message: message,
      duration: duration,
    );
  }

  /// Quick info snackbar
  static void info(BuildContext context, String message, {Duration duration = const Duration(seconds: 3)}) {
    show(
      context: context,
      type: SnackbarType.info,
      message: message,
      duration: duration,
    );
  }
}

/// A floating toast-style notification that appears at the top of the screen
class AppToast {
  static void show({
    required BuildContext context,
    required SnackbarType type,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    HapticFeedback.lightImpact();
    
    final config = SnackbarConfigs.configs[type]!;
    final overlay = Overlay.of(context);
    final animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: Navigator.of(context),
    );
    
    late final OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => AnimatedBuilder(
        animation: animationController,
        builder: (context, child) {
          return Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Opacity(
              opacity: animationController.value,
              child: Transform.translate(
                offset: Offset(0, -20 * (1 - animationController.value)),
                child: child,
              ),
            ),
          );
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: config.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: config.accentColor.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  config.icon,
                  color: config.accentColor,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    overlay.insert(overlayEntry);
    animationController.forward();
    
    Future.delayed(duration, () async {
      await animationController.reverse();
      overlayEntry.remove();
      animationController.dispose();
    });
  }
}
