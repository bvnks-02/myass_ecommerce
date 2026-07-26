// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _orderUpdates = true;
  bool _promotionalOffers = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _pushNotifications = prefs.getBool('push_notifications') ?? true;
        _emailNotifications = prefs.getBool('email_notifications') ?? true;
        _orderUpdates = prefs.getBool('order_updates') ?? true;
        _promotionalOffers = prefs.getBool('promotional_offers') ?? false;
      });
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    }
  }

  Future<void> _savePreference(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    } catch (e) {
      debugPrint('Error saving preference: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save settings')),
      );
    }
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
          'Notifications',
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
              'Notification Preferences',
              style: TextStyle(
                color: Colors.white,
                fontSize: ResponsiveUtils.sf(context, 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveUtils.sh(context, 20)),
            _buildNotificationToggle(
              'Push Notifications',
              'Receive push notifications on your device',
              _pushNotifications,
              (value) {
                setState(() => _pushNotifications = value);
                _savePreference('push_notifications', value);
              },
            ),
            _buildNotificationToggle(
              'Email Notifications',
              'Receive updates via email',
              _emailNotifications,
              (value) {
                setState(() => _emailNotifications = value);
                _savePreference('email_notifications', value);
              },
            ),
            _buildNotificationToggle(
              'Order Updates',
              'Get notified about your order status',
              _orderUpdates,
              (value) {
                setState(() => _orderUpdates = value);
                _savePreference('order_updates', value);
              },
            ),
            _buildNotificationToggle(
              'Promotional Offers',
              'Receive deals and special offers',
              _promotionalOffers,
              (value) {
                setState(() => _promotionalOffers = value);
                _savePreference('promotional_offers', value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationToggle(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveUtils.sh(context, 15)),
      padding: EdgeInsets.all(ResponsiveUtils.padding(context)),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: Colors.grey[700],
          ),
        ],
      ),
    );
  }
}
