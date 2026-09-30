import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../../theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/services/dialog_service.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../services/api_service.dart';
import '../../../../core/services/currency_service.dart';

class UserOrdersScreen extends StatefulWidget {
  const UserOrdersScreen({super.key});

  @override
  State<UserOrdersScreen> createState() => _UserOrdersScreenState();
}

class _UserOrdersScreenState extends State<UserOrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  final DateFormat _timeFormat = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final response = await supabase
          .from('orders')
          .select('*, order_items(*, products(name, image_url, image, images))')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          // Filter out cancelled orders on the client side
          _orders = List<Map<String, dynamic>>.from(response)
              .where((order) {
                final status = (order['status'] as String?)?.toLowerCase() ?? '';
                debugPrint('Order ${order['id']} status: $status, keeping: ${status != 'cancelled'}');
                return status != 'cancelled';
              })
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildSignedOut(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.padding(context)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: ResponsiveUtils.sf(context, 72),
              color: Colors.white24,
            ),
            SizedBox(height: ResponsiveUtils.sh(context, 16)),
            Text(
              'Connectez-vous pour voir vos commandes',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: ResponsiveUtils.sf(context, 18),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: ResponsiveUtils.sh(context, 8)),
            Text(
              'Vos commandes apparaîtront ici après connexion.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: ResponsiveUtils.sf(context, 14),
              ),
            ),
            SizedBox(height: ResponsiveUtils.sh(context, 24)),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
              child: const Text('Se connecter'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSignedIn = Supabase.instance.client.auth.currentUser != null;
    try {
      return Scaffold(
        backgroundColor: AppTheme.blackColor,
        appBar: AppBar(
          backgroundColor: AppTheme.blackColor,
          title: const Text('Order History', style: TextStyle(color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : !isSignedIn
                ? _buildSignedOut(context)
                : _orders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: ResponsiveUtils.sf(context, 80),
                          color: Colors.white24,
                        ),
                        SizedBox(height: ResponsiveUtils.sh(context, 20)),
                        Text(
                          'No orders yet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: ResponsiveUtils.sf(context, 18),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.sh(context, 10)),
                        Text(
                          'Start shopping to see your orders here',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: ResponsiveUtils.sf(context, 14),
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.all(ResponsiveUtils.padding(context)),
                    child: Column(
                      children: _orders.map((order) => _buildOrderCard(order)).toList(),
                    ),
                  ),
      );
    } catch (e, stack) {
      debugPrint('BUILD ERROR: $e');
      debugPrint('STACK: $stack');
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Error', style: TextStyle(color: Colors.white, fontSize: 20)),
              const SizedBox(height: 10),
              Text(e.toString(), style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderItems = order['order_items'] as List<dynamic>? ?? [];
    final firstItem = orderItems.isNotEmpty ? orderItems[0] as Map<String, dynamic>? : null;
    final product = firstItem?['products'] as Map<String, dynamic>?;
    
    String? productImage;
    if (product != null) {
      final images = product['images'] as List<dynamic>?;
      if (images != null && images.isNotEmpty) {
        productImage = images[0] as String?;
      } else {
        productImage =
            (product['image_url'] ?? product['image']) as String?;
      }
    }

    final createdAt = order['created_at'] as String?;
    DateTime? orderDate;
    if (createdAt != null) {
      try {
        orderDate = DateTime.parse(createdAt);
      } catch (e) {
        debugPrint('Error parsing date: $e');
      }
    }

    final status = order['status'] as String? ?? 'Pending';
    final totalAmount = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
    final orderId = order['id'] as int?;

    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveUtils.sh(context, 20)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C2C2E), Color(0xFF1C1C1E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image Section
            if (productImage != null)
              SizedBox(
                height: ResponsiveUtils.sh(context, 180),
                width: double.infinity,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: productImage.startsWith('assets/')
                          ? Image.asset(
                              productImage,
                              fit: BoxFit.contain,
                              alignment: Alignment.center,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: const Color(0xFF1C1C1E),
                                child: const Icon(
                                  Icons.watch,
                                  color: Colors.white24,
                                  size: 50,
                                ),
                              ),
                            )
                          : CachedNetworkImage(
                              imageUrl: productImage,
                              fit: BoxFit.contain,
                              alignment: Alignment.center,
                              placeholder: (context, url) => Container(
                                color: const Color(0xFF1C1C1E),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white24,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: const Color(0xFF1C1C1E),
                                child: const Icon(
                                  Icons.watch,
                                  color: Colors.white24,
                                  size: 50,
                                ),
                              ),
                            ),
                    ),
                    // Order ID Badge
                    Positioned(
                      top: ResponsiveUtils.sh(context, 10),
                      left: ResponsiveUtils.sw(context, 10),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.sw(context, 12),
                          vertical: ResponsiveUtils.sh(context, 6),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Order #${orderId ?? 'N/A'}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: ResponsiveUtils.sf(context, 12),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    // Status Badge
                    Positioned(
                      top: ResponsiveUtils.sh(context, 10),
                      right: ResponsiveUtils.sw(context, 10),
                      child: _buildStatusBadge(status),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: ResponsiveUtils.sh(context, 100),
                width: double.infinity,
                child: Container(
                  color: const Color(0xFF1C1C1E),
                  child: Stack(
                    children: [
                      Positioned(
                        top: ResponsiveUtils.sh(context, 10),
                        left: ResponsiveUtils.sw(context, 10),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtils.sw(context, 12),
                            vertical: ResponsiveUtils.sh(context, 6),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Order #${orderId ?? 'N/A'}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: ResponsiveUtils.sf(context, 12),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: ResponsiveUtils.sh(context, 10),
                        right: ResponsiveUtils.sw(context, 10),
                        child: _buildStatusBadge(status),
                      ),
                      const Center(
                        child: Icon(
                          Icons.shopping_bag,
                          color: Colors.white24,
                          size: 50,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Order Details Section
            Padding(
              padding: EdgeInsets.all(ResponsiveUtils.sw(context, 16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date
                  if (orderDate != null)
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: Colors.grey[400],
                          size: ResponsiveUtils.sf(context, 14),
                        ),
                        SizedBox(width: ResponsiveUtils.sw(context, 6)),
                        Text(
                          '${_dateFormat.format(orderDate)} at ${_timeFormat.format(orderDate)}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: ResponsiveUtils.sf(context, 12),
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: ResponsiveUtils.sh(context, 12)),
                  // Product List Preview
                  if (orderItems.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Items (${orderItems.length})',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: ResponsiveUtils.sf(context, 14),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.sh(context, 8)),
                        ...orderItems.take(3).map((item) {
                          final itemData = item as Map<String, dynamic>;
                          final itemProduct = itemData['products'] as Map<String, dynamic>?;
                          final itemName = itemProduct?['name'] as String? ?? 'Unknown Product';
                          final quantity = itemData['quantity'] as int? ?? 1;
                          // Schema: 'price' (web project); fall back to 'price_at_time'
                          // (legacy app project) so both order sources render.
                          final price = (itemData['price'] as num?)?.toDouble() ??
                              (itemData['price_at_time'] as num?)?.toDouble() ?? 0.0;
                          
                          return Padding(
                            padding: EdgeInsets.only(bottom: ResponsiveUtils.sh(context, 6)),
                            child: Row(
                              children: [
                                Container(
                                  width: ResponsiveUtils.sw(context, 4),
                                  height: ResponsiveUtils.sh(context, 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: ResponsiveUtils.sw(context, 8)),
                                Expanded(
                                  child: Text(
                                    itemName,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: ResponsiveUtils.sf(context, 13),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  'x$quantity',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: ResponsiveUtils.sf(context, 12),
                                  ),
                                ),
                                SizedBox(width: ResponsiveUtils.sw(context, 8)),
                                Text(
                                  '${CurrencyService.formatPrice(price * quantity)}',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: ResponsiveUtils.sf(context, 12),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        if (orderItems.length > 3)
                          Padding(
                            padding: EdgeInsets.only(top: ResponsiveUtils.sh(context, 4)),
                            child: Text(
                              '+${orderItems.length - 3} more items',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: ResponsiveUtils.sf(context, 11),
                              ),
                            ),
                          ),
                      ],
                    ),
                  SizedBox(height: ResponsiveUtils.sh(context, 16)),
                  // Total Amount
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.sw(context, 16),
                      vertical: ResponsiveUtils.sh(context, 12),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: ResponsiveUtils.sf(context, 14),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${totalAmount.toStringAsFixed(2)} DA',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: ResponsiveUtils.sf(context, 16),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.sh(context, 12)),
                  // Cancel Order Button (only for Pending status)
                  if (status.toLowerCase() == 'pending' && orderId != null)
                    SizedBox(
                      width: double.infinity,
                      height: ResponsiveUtils.sh(context, 45),
                      child: ElevatedButton(
                        onPressed: () => _showCancelOrderDialog(orderId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel Order',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.sf(context, 14),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelOrderDialog(int orderId) async {
    await context.dialogs.showCancelOrderConfirmation(
      orderId: orderId,
      onConfirm: () async {
        final success = await ApiService.cancelOrder(orderId);
        if (success && mounted) {
          AppSnackBar.success(context, 'Order #$orderId has been cancelled.');
          _fetchOrders();
        } else if (mounted) {
          AppSnackBar.error(context, 'Could not cancel order. Please try again.');
        }
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    IconData statusIcon;
    
    switch (status.toLowerCase()) {
      case 'completed':
      case 'delivered':
        badgeColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
      case 'processing':
        badgeColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'cancelled':
        badgeColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'shipped':
        badgeColor = Colors.blue;
        statusIcon = Icons.local_shipping;
        break;
      default:
        badgeColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.sw(context, 10),
        vertical: ResponsiveUtils.sh(context, 5),
      ),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            color: Colors.white,
            size: ResponsiveUtils.sf(context, 12),
          ),
          SizedBox(width: ResponsiveUtils.sw(context, 4)),
          Text(
            status,
            style: TextStyle(
              color: Colors.white,
              fontSize: ResponsiveUtils.sf(context, 11),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
