// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/services/dialog_service.dart';
import '../../../../core/widgets/app_snackbar.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();


  @override
  void dispose() {
    _passwordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_passwordController.text.isEmpty || _newPasswordController.text.isEmpty) {
      AppSnackBar.warning(context, 'Please fill in all password fields');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      AppSnackBar.warning(context, 'New password and confirmation do not match');
      return;
    }

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          password: _newPasswordController.text,
        ),
      );
      if (mounted) {
        _passwordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        AppSnackBar.success(context, 'Your password has been updated successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error changing password: $e');
      if (mounted) {
        final message = e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', '');
        AppSnackBar.error(context, 'Could not update password: $message');
      }
    }
  }

  Future<void> _showChangePasswordDialog() async {
    context.dialogs.showChangePasswordDialog(
      currentPasswordController: _passwordController,
      newPasswordController: _newPasswordController,
      confirmPasswordController: _confirmPasswordController,
      onSubmit: _changePassword,
    );
  }

  Future<void> _showChangeEmailDialog() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
    }

    context.dialogs.showChangeEmailDialog(
      emailController: _emailController,
      onSubmit: () async {
        try {
          await Supabase.instance.client.auth.updateUser(
            UserAttributes(email: _emailController.text),
          );
          if (mounted) {
            AppSnackBar.success(context, 'Check your new email for a confirmation link');
          }
        } catch (e) {
          debugPrint('Error changing email: $e');
          if (mounted) {
            final message = e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', '');
            AppSnackBar.error(context, 'Could not update email: $message');
          }
        }
      },
    );
  }

  Future<void> _showChangePhoneDialog() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _phoneController.text = user.userMetadata?['phone'] ?? '';
    }

    context.dialogs.showChangePhoneDialog(
      phoneController: _phoneController,
      onSubmit: () async {
        try {
          await Supabase.instance.client.auth.updateUser(
            UserAttributes(data: {'phone': _phoneController.text}),
          );
          if (mounted) {
            AppSnackBar.success(context, 'Your phone number has been updated');
          }
        } catch (e) {
          debugPrint('Error changing phone: $e');
          if (mounted) {
            final message = e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', '');
            AppSnackBar.error(context, 'Could not update phone: $message');
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.blackColor,
      appBar: AppBar(
        backgroundColor: AppTheme.blackColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: ResponsiveUtils.sf(context, 20)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Privacy & Security',
          style: TextStyle(
            color: Colors.white,
            fontSize: ResponsiveUtils.sf(context, 20),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveUtils.padding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Security',
              style: TextStyle(
                color: Colors.white,
                fontSize: ResponsiveUtils.sf(context, 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveUtils.sh(context, 20)),
            _buildSecurityItem(
              Icons.lock,
              'Change Password',
              'Update your password',
              () => _showChangePasswordDialog(),
            ),
            _buildSecurityItem(
              Icons.email,
              'Change Email',
              'Update your email address',
              () => _showChangeEmailDialog(),
            ),
            _buildSecurityItem(
              Icons.phone,
              'Change Phone',
              'Update your phone number',
              () => _showChangePhoneDialog(),
            ),
            SizedBox(height: ResponsiveUtils.sh(context, 30)),
            Text(
              'Privacy',
              style: TextStyle(
                color: Colors.white,
                fontSize: ResponsiveUtils.sf(context, 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveUtils.sh(context, 20)),
            _buildSecurityItem(
              Icons.visibility,
              'Profile Visibility',
              'Control who can see your profile',
              () {
                AppSnackBar.info(context, 'Privacy settings coming soon!');
              },
            ),
            _buildSecurityItem(
              Icons.data_usage,
              'Data & Storage',
              'Manage your data and storage',
              () {
                AppSnackBar.info(context, 'Data management features coming soon!');
              },
            ),
            SizedBox(height: ResponsiveUtils.sh(context, 30)),
            Text(
              'Danger Zone',
              style: TextStyle(
                color: Colors.red,
                fontSize: ResponsiveUtils.sf(context, 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveUtils.sh(context, 20)),
            _buildSecurityItem(
              Icons.delete_forever,
              'Delete Account',
              'Permanently delete your account',
              () => _showDeleteAccountDialog(),
              isDanger: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isDanger = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: ResponsiveUtils.sh(context, 15)),
        padding: EdgeInsets.all(ResponsiveUtils.padding(context)),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isDanger ? Colors.red.withOpacity(0.3) : Colors.white.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDanger ? Colors.red : Colors.white,
              size: ResponsiveUtils.sf(context, 24),
            ),
            SizedBox(width: ResponsiveUtils.sw(context, 15)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDanger ? Colors.red : Colors.white,
                      fontSize: ResponsiveUtils.sf(context, 16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.sh(context, 5)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: ResponsiveUtils.sf(context, 12),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: isDanger ? Colors.red.withOpacity(0.5) : Colors.grey,
              size: ResponsiveUtils.sf(context, 16),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    context.dialogs.showDeleteAccountConfirmation(
      onConfirm: () {
        AppSnackBar.info(context, 'Account deletion feature coming soon!');
      },
    );
  }
}
