import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

/// Dialog types for consistent styling
enum DialogType {
  success,
  error,
  warning,
  info,
  confirm,
  input,
  loading,
}

/// Configuration for each dialog type
class DialogConfig {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  const DialogConfig({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });
}

/// Dialog configurations
class DialogConfigs {
  static const Map<DialogType, DialogConfig> configs = {
    DialogType.success: DialogConfig(
      icon: Icons.check_circle_outline,
      iconColor: Color(0xFF4CAF50),
      backgroundColor: Color(0xFF1B5E20),
    ),
    DialogType.error: DialogConfig(
      icon: Icons.error_outline,
      iconColor: Color(0xFFEF5350),
      backgroundColor: Color(0xFFB71C1C),
    ),
    DialogType.warning: DialogConfig(
      icon: Icons.warning_amber_rounded,
      iconColor: Color(0xFFFFA726),
      backgroundColor: Color(0xFFEF6C00),
    ),
    DialogType.info: DialogConfig(
      icon: Icons.info_outline,
      iconColor: Color(0xFF42A5F5),
      backgroundColor: Color(0xFF1565C0),
    ),
    DialogType.confirm: DialogConfig(
      icon: Icons.help_outline,
      iconColor: Color(0xFFAB47BC),
      backgroundColor: Color(0xFF6A1B9A),
    ),
    DialogType.input: DialogConfig(
      icon: Icons.edit_note,
      iconColor: Color(0xFF26A69A),
      backgroundColor: Color(0xFF00695C),
    ),
    DialogType.loading: DialogConfig(
      icon: Icons.hourglass_empty,
      iconColor: AppTheme.accent,
      backgroundColor: AppTheme.cardColor,
    ),
  };
}

/// Reusable modern dialog widget
class AppDialog extends StatelessWidget {
  final DialogType type;
  final String title;
  final String message;
  final String? primaryActionText;
  final String? secondaryActionText;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSecondaryAction;
  final bool isDestructive;
  final bool barrierDismissible;
  final Widget? customContent;
  final List<Widget>? customActions;

  const AppDialog({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    this.primaryActionText,
    this.secondaryActionText,
    this.onPrimaryAction,
    this.onSecondaryAction,
    this.isDestructive = false,
    this.barrierDismissible = true,
    this.customContent,
    this.customActions,
  });

  /// Show the dialog
  static Future<T?> show<T>({
    required BuildContext context,
    required DialogType type,
    required String title,
    required String message,
    String? primaryActionText,
    String? secondaryActionText,
    VoidCallback? onPrimaryAction,
    VoidCallback? onSecondaryAction,
    bool isDestructive = false,
    bool barrierDismissible = true,
    Widget? customContent,
    List<Widget>? customActions,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AppDialog(
        type: type,
        title: title,
        message: message,
        primaryActionText: primaryActionText,
        secondaryActionText: secondaryActionText,
        onPrimaryAction: onPrimaryAction,
        onSecondaryAction: onSecondaryAction,
        isDestructive: isDestructive,
        barrierDismissible: barrierDismissible,
        customContent: customContent,
        customActions: customActions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = DialogConfigs.configs[type]!;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        // Frosted card floating over the dimmed screen content.
        child: AppTheme.glass(
          radius: 24,
          sigma: 18,
          fill: Colors.white.withValues(alpha: 0.70),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon header
                _buildIconHeader(config),

                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    children: [
                      // Title
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppTheme.fg,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      // Message
                      Text(
                        message,
                        style: const TextStyle(
                          color: AppTheme.silver,
                          fontSize: 14,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      // Custom content
                      if (customContent != null) ...[
                        const SizedBox(height: 20),
                        customContent!,
                      ],

                      const SizedBox(height: 24),

                      // Actions
                      if (customActions != null)
                        ...customActions!
                      else
                        _buildDefaultActions(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconHeader(DialogConfig config) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 32, bottom: 16),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: config.iconColor.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          config.icon,
          color: config.iconColor,
          size: 36,
        ),
      ),
    );
  }

  Widget _buildDefaultActions() {
    final hasSecondary = secondaryActionText != null && onSecondaryAction != null;
    final hasPrimary = primaryActionText != null && onPrimaryAction != null;

    if (!hasPrimary && !hasSecondary) return const SizedBox.shrink();

    return Column(
      children: [
        if (hasPrimary)
          _buildPrimaryButton(),
        
        if (hasSecondary) ...[
          if (hasPrimary) const SizedBox(height: 12),
          _buildSecondaryButton(),
        ],
      ],
    );
  }

  Widget _buildPrimaryButton() {
    final backgroundColor = isDestructive 
        ? const Color(0xFFEF5350) 
        : const Color(0xFF4CAF50);
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onPrimaryAction!();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          primaryActionText!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onSecondaryAction!();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.line,
            width: 1,
          ),
        ),
        child: Text(
          secondaryActionText!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.fg,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Loading dialog with modern design
class AppLoadingDialog extends StatelessWidget {
  final String message;

  const AppLoadingDialog({
    super.key,
    this.message = 'Please wait...',
  });

  static void show(BuildContext context, {String message = 'Please wait...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AppLoadingDialog(message: message),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      // Compact frosted card — kept small so the blurred area stays tight.
      child: AppTheme.glass(
        radius: 24,
        sigma: 18,
        fill: Colors.white.withValues(alpha: 0.70),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.accent,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                style: const TextStyle(
                  color: AppTheme.silver,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Success dialog that auto-dismisses
class AppSuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onDismiss;

  const AppSuccessDialog({
    super.key,
    required this.title,
    required this.message,
    this.onDismiss,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onDismiss,
    Duration duration = const Duration(seconds: 2),
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AppSuccessDialog(
        title: title,
        message: message,
        onDismiss: onDismiss,
      ),
    );
    
    await Future.delayed(duration);
    if (context.mounted) {
      Navigator.of(context).pop();
      onDismiss?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      // Frosted success card — green kept only as the semantic accent.
      child: AppTheme.glass(
        radius: 24,
        sigma: 18,
        fill: Colors.white.withValues(alpha: 0.70),
        borderColor: AppTheme.success.withValues(alpha: 0.35),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppTheme.success,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.fg,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(
                  color: AppTheme.silver,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
