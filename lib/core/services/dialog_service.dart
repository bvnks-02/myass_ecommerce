import 'package:flutter/material.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/app_snackbar.dart';

/// A service that provides easy-to-use methods for showing common dialogs
/// with improved UX writing and consistent styling.
class DialogService {
  final BuildContext context;
  
  DialogService(this.context);

  // ==================== SUCCESS DIALOGS ====================

  /// Show order placed successfully dialog
  Future<void> showOrderSuccess({
    VoidCallback? onContinueShopping,
    VoidCallback? onViewOrders,
  }) {
    return AppDialog.show(
      context: context,
      type: DialogType.success,
      title: 'Order Placed!',
      message: 'Your order has been received and is being processed. You\'ll receive a confirmation shortly.',
      primaryActionText: 'Continue Shopping',
      onPrimaryAction: onContinueShopping ?? () => Navigator.of(context).pop(),
      secondaryActionText: 'View My Orders',
      onSecondaryAction: onViewOrders ?? () => Navigator.of(context).pop(),
    );
  }

  /// Show generic success dialog
  Future<void> showSuccess({
    required String title,
    required String message,
    String actionText = 'Got it',
    VoidCallback? onAction,
  }) {
    return AppDialog.show(
      context: context,
      type: DialogType.success,
      title: title,
      message: message,
      primaryActionText: actionText,
      onPrimaryAction: onAction ?? () => Navigator.of(context).pop(),
    );
  }

  // ==================== CONFIRMATION DIALOGS ====================

  /// Show cancel order confirmation with proper context
  Future<bool> showCancelOrderConfirmation({
    required int orderId,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
  }) async {
    bool confirmed = false;
    
    await AppDialog.show(
      context: context,
      type: DialogType.warning,
      title: 'Cancel Order?',
      message: 'Order #$orderId will be cancelled and cannot be restored. This action is immediate.',
      primaryActionText: 'Yes, Cancel Order',
      onPrimaryAction: () {
        confirmed = true;
        Navigator.of(context).pop();
        onConfirm();
      },
      secondaryActionText: 'Keep Order',
      onSecondaryAction: () {
        Navigator.of(context).pop();
        onCancel?.call();
      },
      isDestructive: true,
    );
    
    return confirmed;
  }

  /// Show logout confirmation
  Future<bool> showLogoutConfirmation({
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
  }) async {
    bool confirmed = false;
    
    await AppDialog.show(
      context: context,
      type: DialogType.confirm,
      title: 'Sign Out?',
      message: 'You\'ll need to sign in again to access your account and orders.',
      primaryActionText: 'Sign Out',
      onPrimaryAction: () {
        confirmed = true;
        Navigator.of(context).pop();
        onConfirm();
      },
      secondaryActionText: 'Stay Signed In',
      onSecondaryAction: () {
        Navigator.of(context).pop();
        onCancel?.call();
      },
      isDestructive: true,
    );
    
    return confirmed;
  }

  /// Show delete product confirmation for admin
  Future<bool> showDeleteProductConfirmation({
    required String productName,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
  }) async {
    bool confirmed = false;
    
    await AppDialog.show(
      context: context,
      type: DialogType.warning,
      title: 'Delete Product?',
      message: '"$productName" will be permanently removed from your store. Customers will no longer be able to purchase it.',
      primaryActionText: 'Delete Product',
      onPrimaryAction: () {
        confirmed = true;
        Navigator.of(context).pop();
        onConfirm();
      },
      secondaryActionText: 'Keep Product',
      onSecondaryAction: () {
        Navigator.of(context).pop();
        onCancel?.call();
      },
      isDestructive: true,
    );
    
    return confirmed;
  }

  /// Show delete account confirmation
  Future<bool> showDeleteAccountConfirmation({
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
  }) async {
    bool confirmed = false;
    
    await AppDialog.show(
      context: context,
      type: DialogType.error,
      title: 'Delete Your Account?',
      message: 'This will permanently delete your account, order history, and all saved data. This action cannot be undone.',
      primaryActionText: 'Delete Account',
      onPrimaryAction: () {
        confirmed = true;
        Navigator.of(context).pop();
        onConfirm();
      },
      secondaryActionText: 'Keep My Account',
      onSecondaryAction: () {
        Navigator.of(context).pop();
        onCancel?.call();
      },
      isDestructive: true,
    );
    
    return confirmed;
  }

  // ==================== AUTH DIALOGS ====================

  /// Show login required dialog
  Future<void> showLoginRequired({
    required VoidCallback onLogin,
    VoidCallback? onContinueBrowsing,
  }) {
    return AppDialog.show(
      context: context,
      type: DialogType.info,
      title: 'Sign In to Continue',
      message: 'Create an account or sign in to place orders and track your purchases.',
      primaryActionText: 'Sign In',
      onPrimaryAction: () {
        Navigator.of(context).pop();
        onLogin();
      },
      secondaryActionText: 'Continue Browsing',
      onSecondaryAction: () {
        Navigator.of(context).pop();
        onContinueBrowsing?.call();
      },
    );
  }

  // ==================== LOCATION DIALOGS ====================

  /// Show location services disabled dialog
  Future<void> showLocationDisabled({
    required VoidCallback onOpenSettings,
    VoidCallback? onDismiss,
  }) {
    return AppDialog.show(
      context: context,
      type: DialogType.info,
      title: 'Location Services Off',
      message: 'Enable location services to automatically detect and fill your delivery address.',
      primaryActionText: 'Enable Location',
      onPrimaryAction: () {
        Navigator.of(context).pop();
        onOpenSettings();
      },
      secondaryActionText: 'Enter Address Manually',
      onSecondaryAction: () {
        Navigator.of(context).pop();
        onDismiss?.call();
      },
    );
  }

  /// Show location permission denied dialog
  Future<void> showLocationPermissionDenied({
    required VoidCallback onOpenSettings,
    VoidCallback? onDismiss,
  }) {
    return AppDialog.show(
      context: context,
      type: DialogType.warning,
      title: 'Location Access Denied',
      message: 'We need your permission to detect your location. You can enable this in your device settings.',
      primaryActionText: 'Open Settings',
      onPrimaryAction: () {
        Navigator.of(context).pop();
        onOpenSettings();
      },
      secondaryActionText: 'Enter Address Manually',
      onSecondaryAction: () {
        Navigator.of(context).pop();
        onDismiss?.call();
      },
    );
  }

  // ==================== INPUT DIALOGS ====================

  /// Show change password dialog
  Future<void> showChangePasswordDialog({
    required TextEditingController currentPasswordController,
    required TextEditingController newPasswordController,
    required TextEditingController confirmPasswordController,
    required VoidCallback onSubmit,
  }) {
    return AppDialog.show(
      context: context,
      type: DialogType.input,
      title: 'Change Password',
      message: 'Create a strong password with at least 8 characters, including numbers and symbols.',
      customContent: Column(
        children: [
          _buildPasswordField(
            controller: currentPasswordController,
            hint: 'Current password',
          ),
          const SizedBox(height: 12),
          _buildPasswordField(
            controller: newPasswordController,
            hint: 'New password',
          ),
          const SizedBox(height: 12),
          _buildPasswordField(
            controller: confirmPasswordController,
            hint: 'Confirm new password',
          ),
        ],
      ),
      primaryActionText: 'Update Password',
      onPrimaryAction: () {
        Navigator.of(context).pop();
        onSubmit();
      },
      secondaryActionText: 'Cancel',
      onSecondaryAction: () {
        Navigator.of(context).pop();
      },
    );
  }

  /// Show change email dialog
  Future<void> showChangeEmailDialog({
    required TextEditingController emailController,
    required VoidCallback onSubmit,
  }) {
    return AppDialog.show(
      context: context,
      type: DialogType.input,
      title: 'Update Email',
      message: 'A confirmation link will be sent to your new email address.',
      customContent: _buildTextField(
        controller: emailController,
        hint: 'New email address',
        keyboardType: TextInputType.emailAddress,
      ),
      primaryActionText: 'Send Confirmation',
      onPrimaryAction: () {
        Navigator.of(context).pop();
        onSubmit();
      },
      secondaryActionText: 'Cancel',
      onSecondaryAction: () {
        Navigator.of(context).pop();
      },
    );
  }

  /// Show change phone dialog
  Future<void> showChangePhoneDialog({
    required TextEditingController phoneController,
    required VoidCallback onSubmit,
  }) {
    return AppDialog.show(
      context: context,
      type: DialogType.input,
      title: 'Update Phone Number',
      message: 'Your phone number helps us contact you about your orders.',
      customContent: _buildTextField(
        controller: phoneController,
        hint: 'Phone number',
        keyboardType: TextInputType.phone,
      ),
      primaryActionText: 'Save Number',
      onPrimaryAction: () {
        Navigator.of(context).pop();
        onSubmit();
      },
      secondaryActionText: 'Cancel',
      onSecondaryAction: () {
        Navigator.of(context).pop();
      },
    );
  }

  // ==================== LOADING DIALOGS ====================

  void showLoading({String message = 'Please wait...'}) {
    AppLoadingDialog.show(context, message: message);
  }

  void hideLoading() {
    AppLoadingDialog.hide(context);
  }

  // ==================== SNACKBARS ====================

  void showSuccessSnackBar(String message) {
    AppSnackBar.success(context, message);
  }

  void showErrorSnackBar(String message) {
    AppSnackBar.error(context, message);
  }

  void showWarningSnackBar(String message) {
    AppSnackBar.warning(context, message);
  }

  void showInfoSnackBar(String message) {
    AppSnackBar.info(context, message);
  }

  // ==================== HELPER WIDGETS ====================

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
  }) {
    return _buildTextField(
      controller: controller,
      hint: hint,
      obscureText: true,
      prefixIcon: Icons.lock_outline,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    IconData? prefixIcon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: Colors.white.withOpacity(0.4), size: 20)
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

/// Extension for easy access to DialogService
extension DialogServiceExtension on BuildContext {
  DialogService get dialogs => DialogService(this);
}
