import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/security/input_sanitizer.dart';
import '../../../../core/security/rate_limiter.dart';
import '../providers/support_provider.dart';
import '../../domain/entities/faq_model.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _problemTitleController = TextEditingController();
  final TextEditingController _problemDescriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupportProvider>().clearSearch();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _problemTitleController.dispose();
    _problemDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _launchWhatsApp() async {
    final Uri whatsappUri = Uri.parse('https://wa.me/213542455634');
    if (!await launchUrl(whatsappUri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp')),
        );
      }
    }
  }

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'myazzalgérie@gmail.com',
      query: 'subject=Support Request',
    );
    if (!await launchUrl(emailUri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch email client')),
        );
      }
    }
  }

  Future<void> _submitProblem() async {
    // Sanitize inputs
    final title = InputSanitizer.sanitizeString(_problemTitleController.text.trim(), maxLength: 200);
    final description = InputSanitizer.sanitizeString(_problemDescriptionController.text.trim(), maxLength: 2000);
    
    // Validate inputs
    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (title.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title must be at least 5 characters')),
      );
      return;
    }

    if (description.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Description must be at least 10 characters')),
      );
      return;
    }

    // Rate limiting check
    if (!RateLimiters.contact.isAllowed('contact_form')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Too many contact form submissions. Please try again later.')),
      );
      return;
    }

    // Create email with problem details
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'myazzalgérie@gmail.com',
      query: 'subject=Support Request: $title&body=${Uri.encodeComponent(description)}',
    );

    if (!await launchUrl(emailUri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch email client')),
        );
      }
    } else {
      if (mounted) {
        _problemTitleController.clear();
        _problemDescriptionController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email client opened successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.blackColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: ResponsiveUtils.padding(context),
                  right: ResponsiveUtils.padding(context),
                  top: ResponsiveUtils.sh(context, 20),
                  bottom: ResponsiveUtils.sh(context, 100)
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(),
                    SizedBox(height: ResponsiveUtils.sh(context, 25)),
                    _buildFAQSection(),
                    SizedBox(height: ResponsiveUtils.sh(context, 25)),
                    _buildOrdersHelpSection(),
                    SizedBox(height: ResponsiveUtils.sh(context, 25)),
                    _buildContactSupportSection(),
                    SizedBox(height: ResponsiveUtils.sh(context, 25)),
                    _buildReportProblemSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(ResponsiveUtils.padding(context)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(ResponsiveUtils.sw(context, 12)),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: ResponsiveUtils.sf(context, 20),
              ),
            ),
          ),
          Text(
            'Service Client',
            style: TextStyle(
              color: Colors.white,
              fontSize: ResponsiveUtils.sf(context, 20),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: ResponsiveUtils.sw(context, 48)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: ResponsiveUtils.sh(context, 50),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: ResponsiveUtils.sw(context, 15)),
          Icon(Icons.search, color: Colors.grey[400], size: ResponsiveUtils.sf(context, 20)),
          SizedBox(width: ResponsiveUtils.sw(context, 10)),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search for help...',
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: ResponsiveUtils.sf(context, 14),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              onChanged: (value) {
                final sanitizedQuery = InputSanitizer.sanitizeSearchQuery(value);
                context.read<SupportProvider>().searchFAQs(sanitizedQuery);
              },
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, color: Colors.grey[400], size: ResponsiveUtils.sf(context, 20)),
              onPressed: () {
                _searchController.clear();
                context.read<SupportProvider>().clearSearch();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFAQSection() {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.padding(context)),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, color: Colors.white, size: ResponsiveUtils.sf(context, 24)),
              SizedBox(width: ResponsiveUtils.sw(context, 10)),
              Text(
                'FAQ',
                style: TextStyle(
                  fontSize: ResponsiveUtils.sf(context, 18),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.sh(context, 20)),
          Consumer<SupportProvider>(
            builder: (context, supportProvider, _) {
              final faqs = supportProvider.faqs;
              if (faqs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'No FAQs found',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: faqs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final faq = faqs[index];
                  return _buildFAQItem(faq);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(FAQModel faq) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColorSecondary,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        childrenPadding: const EdgeInsets.all(15),
        iconColor: Colors.white,
        collapsedIconColor: Colors.grey[400],
        title: Text(
          faq.question,
          style: TextStyle(
            color: Colors.white,
            fontSize: ResponsiveUtils.sf(context, 14),
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  faq.category,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: ResponsiveUtils.sf(context, 11),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(height: ResponsiveUtils.sh(context, 10)),
              Text(
                faq.answer,
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: ResponsiveUtils.sf(context, 13),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersHelpSection() {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.padding(context)),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.white, size: ResponsiveUtils.sf(context, 24)),
              SizedBox(width: ResponsiveUtils.sw(context, 10)),
              Text(
                'Orders Help',
                style: TextStyle(
                  fontSize: ResponsiveUtils.sf(context, 18),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.sh(context, 20)),
          _buildOrderHelpItem(
            Icons.local_shipping,
            'Track Order',
            'Check your order status',
            () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          const SizedBox(height: 15),
          _buildOrderHelpItem(
            Icons.cancel,
            'Cancel Order',
            'Cancel your pending order',
            () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          const SizedBox(height: 15),
          _buildOrderHelpItem(
            Icons.assignment_return,
            'Request Refund',
            'Get refund for your order',
            () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderHelpItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(ResponsiveUtils.sw(context, 15)),
        decoration: BoxDecoration(
          color: AppTheme.cardColorSecondary,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: ResponsiveUtils.sf(context, 14),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.sh(context, 3)),
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
            Icon(Icons.arrow_forward_ios, color: Colors.grey, size: ResponsiveUtils.sf(context, 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSupportSection() {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.padding(context)),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.support_agent, color: Colors.white, size: ResponsiveUtils.sf(context, 24)),
              SizedBox(width: ResponsiveUtils.sw(context, 10)),
              Text(
                'Contact Support',
                style: TextStyle(
                  fontSize: ResponsiveUtils.sf(context, 18),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.sh(context, 20)),
          Row(
            children: [
              Expanded(
                child: _buildContactButton(
                  FontAwesomeIcons.whatsapp,
                  'WhatsApp',
                  Colors.green,
                  _launchWhatsApp,
                ),
              ),
              SizedBox(width: ResponsiveUtils.sw(context, 15)),
              Expanded(
                child: _buildContactButton(
                  FontAwesomeIcons.google,
                  'Gmail',
                  Colors.red,
                  _launchEmail,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton(FaIconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.sh(context, 15)),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            FaIcon(icon, color: color, size: ResponsiveUtils.sf(context, 28)),
            SizedBox(height: ResponsiveUtils.sh(context, 8)),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: ResponsiveUtils.sf(context, 14),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportProblemSection() {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.padding(context)),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.report_problem, color: Colors.white, size: ResponsiveUtils.sf(context, 24)),
              SizedBox(width: ResponsiveUtils.sw(context, 10)),
              Text(
                'Report a Problem',
                style: TextStyle(
                  fontSize: ResponsiveUtils.sf(context, 18),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.sh(context, 20)),
          TextField(
            controller: _problemTitleController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Title',
              labelStyle: TextStyle(color: Colors.grey[400]),
              filled: false,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey[600]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey[600]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Colors.white, width: 1.5),
              ),
            ),
          ),
          SizedBox(height: ResponsiveUtils.sh(context, 15)),
          TextField(
            controller: _problemDescriptionController,
            style: const TextStyle(color: Colors.white),
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Description',
              labelStyle: TextStyle(color: Colors.grey[400]),
              filled: false,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey[600]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey[600]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Colors.white, width: 1.5),
              ),
            ),
          ),
          SizedBox(height: ResponsiveUtils.sh(context, 15)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitProblem,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.sh(context, 15)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                'Submit',
                style: TextStyle(
                  fontSize: ResponsiveUtils.sf(context, 14),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
