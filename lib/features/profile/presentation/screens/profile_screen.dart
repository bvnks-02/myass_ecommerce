// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../theme/app_theme.dart';
import '../../../../providers/auth_provider.dart';
import '../../../admin/presentation/screens/admin_dashboard_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isSaving = false;
  List<Map<String, dynamic>> _orders = [];
  bool _isLoadingOrders = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.refreshRole();
      authProvider.clearError();
      _initData();
      _fetchOrderHistory();
    });
  }

  Future<void> _fetchOrderHistory() async {
    setState(() => _isLoadingOrders = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('orders')
          .select('*, order_items(*, products(name))')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(response);
          _isLoadingOrders = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching order history: $e');
      if (mounted) {
        setState(() => _isLoadingOrders = false);
      }
    }
  }

  void _initData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      _nameController.text = authProvider.user!.userMetadata?['full_name'] ?? '';
      _emailController.text = authProvider.user!.email ?? '';
      _phoneController.text = authProvider.user!.userMetadata?['phone'] ?? '';
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isSaving = true);
    try {
      final supabase = Supabase.instance.client;
      await supabase.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': _nameController.text,
            'phone': _phoneController.text,
          },
        ),
      );
      if (mounted) {
        Provider.of<AuthProvider>(context, listen: false).refreshRole();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      if (mounted) {
        final message = e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _refreshOrders() async {
    await _fetchOrderHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {

        return Scaffold(
          backgroundColor: AppTheme.blackColor,
          appBar: AppBar(
            backgroundColor: AppTheme.blackColor,
            elevation: 0,
            title: const Text(
              'Profile',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              IconButton(
                icon:
                    const Icon(Icons.refresh, color: Colors.white70, size: 20),
                onPressed: () => authProvider.refreshRole(),
              ),
            ],
          ),
          body: authProvider.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(authProvider),
                      const SizedBox(height: 30),
                      _buildUserInfo(),
                      const SizedBox(height: 30),
                      _buildOrderHistory(),
                      const SizedBox(height: 30),
                      _buildSettings(authProvider),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildProfileHeader(AuthProvider authProvider) {
    final name = authProvider.user?.userMetadata?['full_name'] ?? 'Myass User';
    final role = authProvider.isAdmin ? 'Admin' : 'Client';

    return Center(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Icon(
              Icons.person,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: authProvider.isAdmin
                  ? Colors.blue.withOpacity(0.2)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              role,
              style: TextStyle(
                fontSize: 12,
                color: authProvider.isAdmin ? Colors.blue : Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoField(Icons.person, 'Full Name', _nameController),
          const SizedBox(height: 15),
          _buildInfoField(Icons.email, 'E-mail', _emailController, readOnly: true),
          const SizedBox(height: 15),
          _buildInfoField(Icons.phone, 'Phone', _phoneController),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 2),
                    )
                  : const Text(
                      'Update Profile',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField(
      IconData icon, String label, TextEditingController controller,
      {bool readOnly = false}) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white),
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400]),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }

  Widget _buildOrderHistory() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Order History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (!_isLoadingOrders)
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
                  onPressed: _refreshOrders,
                ),
            ],
          ),
          const SizedBox(height: 15),
          if (_isLoadingOrders)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          else if (_orders.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.receipt_long, color: Colors.grey[600], size: 50),
                  const SizedBox(height: 10),
                  Text(
                    'No orders yet',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              ),
            )
          else
            ..._orders.map((order) {
              final orderId = '#${order['id']}';
              final status = order['status'] ?? 'Pending';
              final total = order['total_amount']?.toString() ?? '0';
              final orderItems = order['order_items'] as List<dynamic>? ?? [];
              final productName = orderItems.isNotEmpty
                  ? (orderItems[0]['products']?['name'] as String?) ?? 'Product'
                  : 'Product';

              Color statusColor;
              switch (status.toLowerCase()) {
                case 'delivered':
                  statusColor = Colors.green;
                  break;
                case 'confirmed':
                  statusColor = Colors.white;
                  break;
                case 'cancelled':
                  statusColor = Colors.red;
                  break;
                default:
                  statusColor = Colors.orange;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildOrderItem(
                  'Order $orderId',
                  productName,
                  '$total DA',
                  status,
                  statusColor,
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildOrderItem(
    String orderNumber,
    String productName,
    String amount,
    String status,
    Color statusColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.cardColorSecondary,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orderNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  productName,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettings(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          if (authProvider.isAdmin)
            _buildSettingItem(
              Icons.admin_panel_settings,
              'Admin Dashboard',
              'Manage products and orders',
              () async {
                final isAdmin = await authProvider.checkIsAdmin();
                if (isAdmin && mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminDashboardScreen(),
                    ),
                  );
                }
              },
            ),
          _buildSettingItem(
            Icons.notifications,
            'Notifications',
            'Manage your notifications',
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Notifications coming soon!')),
              );
            },
          ),
          _buildSettingItem(
            Icons.security,
            'Privacy & Security',
            'Manage your privacy settings',
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Settings coming soon!')),
              );
            },
          ),
          _buildSettingItem(
            Icons.help,
            'Help & Support',
            'Get help and support',
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Support coming soon!')),
              );
            },
          ),
          _buildSettingItem(
            Icons.info,
            'About',
            'App version 1.0.0',
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Myass E-commerce v1.0.0')),
              );
            },
          ),
          _buildSettingItem(
            Icons.logout,
            'Sign Out',
            'Sign out of your account',
            () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[400]),
      ),
      trailing:
          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text(
          'Logout',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
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
            onPressed: () async {
              Navigator.pop(dialogContext);
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              await authProvider.signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
