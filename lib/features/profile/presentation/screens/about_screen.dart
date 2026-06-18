// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = 'Loading...';
  String _buildNumber = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() {
        _version = info.version;
        _buildNumber = info.buildNumber;
      });
    } catch (e) {
      debugPrint('Error loading package info: $e');
      setState(() {
        _version = '1.0.0';
        _buildNumber = '1';
      });
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
          'About',
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
            Center(
              child: Column(
                children: [
                  Container(
                    width: ResponsiveUtils.sw(context, 100),
                    height: ResponsiveUtils.sh(context, 100),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Image.asset(
                      'assets/images/logo.jpeg',
                      width: ResponsiveUtils.sw(context, 70),
                      height: ResponsiveUtils.sh(context, 70),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.sh(context, 20)),
                  Text(
                    'Myazz',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: ResponsiveUtils.sf(context, 24),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.sh(context, 5)),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: ResponsiveUtils.sf(context, 14),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: ResponsiveUtils.sh(context, 40)),
            Text(
              'App Information',
              style: TextStyle(
                color: Colors.white,
                fontSize: ResponsiveUtils.sf(context, 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveUtils.sh(context, 20)),
            _buildInfoItem('Version', _version),
            _buildInfoItem('Build', _buildNumber),
            _buildInfoItem('Platform', 'Android & iOS'),
            _buildInfoItem('Developer', 'Belaggoun Amina'),
            SizedBox(height: ResponsiveUtils.sh(context, 30)),
            Text(
              'About Us',
              style: TextStyle(
                color: Colors.white,
                fontSize: ResponsiveUtils.sf(context, 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveUtils.sh(context, 20)),
            Text(
              'Myazz E-commerce is your one-stop destination for premium watches and accessories. We offer a wide selection of high-quality products with fast delivery and excellent customer service.',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: ResponsiveUtils.sf(context, 14),
                height: 1.5,
              ),
            ),
            SizedBox(height: ResponsiveUtils.sh(context, 30)),
            Text(
              'Legal',
              style: TextStyle(
                color: Colors.white,
                fontSize: ResponsiveUtils.sf(context, 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveUtils.sh(context, 20)),
            _buildLegalItem(
              'Terms of Service',
              () {
                _launchUrl('https://myazz.com/terms');
              },
            ),
            _buildLegalItem(
              'Privacy Policy',
              () {
                _launchUrl('https://myazz.com/privacy');
              },
            ),
            SizedBox(height: ResponsiveUtils.sh(context, 30)),
            Text(
              'Connect With Us',
              style: TextStyle(
                color: Colors.white,
                fontSize: ResponsiveUtils.sf(context, 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveUtils.sh(context, 20)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialIcon(FontAwesomeIcons.facebook, () {
                  _launchUrl('https://facebook.com/myazz');
                }),
                SizedBox(width: ResponsiveUtils.sw(context, 20)),
                _buildSocialIcon(FontAwesomeIcons.instagram, () {
                  _launchUrl('https://instagram.com/myazz');
                }),
                SizedBox(width: ResponsiveUtils.sw(context, 20)),
                _buildSocialIcon(FontAwesomeIcons.xTwitter, () {
                  _launchUrl('https://twitter.com/myazz');
                }),
              ],
            ),
            SizedBox(height: ResponsiveUtils.sh(context, 30)),
            Center(
              child: Text(
                '© 2026 Myazz E-commerce. All rights reserved.',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: ResponsiveUtils.sf(context, 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
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
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: ResponsiveUtils.sf(context, 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: ResponsiveUtils.sf(context, 14),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalItem(String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: ResponsiveUtils.sf(context, 14),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: ResponsiveUtils.sf(context, 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: ResponsiveUtils.sw(context, 50),
        height: ResponsiveUtils.sh(context, 50),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: FaIcon(
          icon,
          color: Colors.white,
          size: ResponsiveUtils.sf(context, 24),
        ),
      ),
    );
  }

  void _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
