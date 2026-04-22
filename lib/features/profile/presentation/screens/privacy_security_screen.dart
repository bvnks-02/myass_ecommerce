// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          password: _newPasswordController.text,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error changing password: $e');
      if (mounted) {
        final message = e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  Future<void> _showChangePasswordDialog() async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text(
          'Change Password',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _passwordController.clear();
              _newPasswordController.clear();
              _confirmPasswordController.clear();
              Navigator.pop(dialogContext);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _changePassword();
            },
            child: const Text(
              'Change',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangeEmailDialog() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text(
          'Change Email',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'New Email',
            labelStyle: TextStyle(color: Colors.grey),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _emailController.clear();
              Navigator.pop(dialogContext);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (_emailController.text.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Please enter an email')),
                );
                return;
              }
              Navigator.pop(dialogContext);
              try {
                await Supabase.instance.client.auth.updateUser(
                  UserAttributes(email: _emailController.text),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Confirmation email sent')),
                  );
                }
              } catch (e) {
                debugPrint('Error changing email: $e');
                if (mounted) {
                  final message = e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', '');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                }
              }
            },
            child: const Text(
              'Change',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangePhoneDialog() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _phoneController.text = user.userMetadata?['phone'] ?? '';
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text(
          'Change Phone',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'New Phone Number',
            labelStyle: TextStyle(color: Colors.grey),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.phone,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _phoneController.clear();
              Navigator.pop(dialogContext);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (_phoneController.text.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Please enter a phone number')),
                );
                return;
              }
              Navigator.pop(dialogContext);
              try {
                await Supabase.instance.client.auth.updateUser(
                  UserAttributes(data: {'phone': _phoneController.text}),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Phone number updated')),
                  );
                }
              } catch (e) {
                debugPrint('Error changing phone: $e');
                if (mounted) {
                  final message = e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', '');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                }
              }
            },
            child: const Text(
              'Change',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Privacy settings coming soon!')),
                );
              },
            ),
            _buildSecurityItem(
              Icons.data_usage,
              'Data & Storage',
              'Manage your data and storage',
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data settings coming soon!')),
                );
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
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text(
          'Delete Account',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deletion feature coming soon!')),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
