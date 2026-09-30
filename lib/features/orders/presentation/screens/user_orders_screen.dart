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
              color: AppTheme.dim,
            ),
            SizedBox(height: ResponsiveUtils.sh(context, 16)),
            Text(
              'Connectez-vous pour voir vos commandes',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.fg,
                fontSize: ResponsiveUtils.sf(context, 18),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: ResponsiveUtils.sh(context, 8)),
            Text(
              'Vos commandes apparaîtront ici après connexion.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.silver,
                fontSize: ResponsiveUtils.sf(context, 14),
              ),
            ),
            SizedBox(height: ResponsiveUtils.sh(context, 24)),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.fg,
                foregroundColor: AppTheme.bg,
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
        backgroundColor: AppTheme.bg,
        appBar: AppBar(
          backgroundColor: AppTheme.bg,
          title: const Text('Order History', style: TextStyle(color: AppTheme.fg)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.fg),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
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
                          color: AppTheme.dim,
                        ),
                        SizedBox(height: ResponsiveUtils.sh(context, 20)),
                        Text(
                          'No orders yet',
                          style: TextStyle(
                            color: AppTheme.fg,
                            fontSize: ResponsiveUtils.sf(context, 18),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.sh(context, 10)),
                        Text(
                          'Start shopping to see your orders here',
                          style: TextStyle(
                            color: AppTheme.silver,
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
        backgroundColor: AppTheme.bg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Error', style: TextStyle(color: AppTheme.fg, fontSize: 20)),
              const SizedBox(height: 10),
              Text(e.toString(), style: const TextStyle(color: AppTheme.danger)),
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
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.line,
          width: 1,
        ),
        boxShadow: [AppTheme.cardShadow],
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
                                color: AppTheme.surface2,
                                child: const Icon(
                                  Icons.watch,
                                  color: AppTheme.dim,
                                  size: 50,
                                ),
                              ),
                            )
                          : CachedNetworkImage(
                              imageUrl: productImage,
                              fit: BoxFit.contain,
                              alignment: Alignment.center,
                              placeholder: (context, url) => Container(
                                color: AppTheme.surface2,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: AppTheme.dim,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppTheme.surface2,
                                child: const Icon(
                                  Icons.watch,
                                  color: AppTheme.dim,
                                  size: 50,
                                ),
                              ),
                            ),
                    ),
                    // Order ID Badge — frosted chip over the product photo
                    Positioned(
                      top: ResponsiveUtils.sh(context, 10),
                      left: ResponsiveUtils.sw(context, 10),
                      child: AppTheme.glass(
                        radius: 20,
                        sigma: 10,
                        fill: AppTheme.glassFillSheer,
                        borderColor: Colors.white.withValues(alpha: 0.6),
                        shadow: false,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtils.sw(context, 12),
                            vertical: ResponsiveUtils.sh(context, 6),
                          ),
                          child: Text(
                            'Order #${orderId ?? 'N/A'}',
                            style: TextStyle(
                              color: AppTheme.fg,
                              fontSize: ResponsiveUtils.sf(context, 12),
                              fontWeight: FontWeight.w600,
                            ),
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
                  color: AppTheme.surface2,
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
                            color: AppTheme.fg.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Order #${orderId ?? 'N/A'}',
                            style: TextStyle(
                              color: AppTheme.bg,
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
                          color: AppTheme.dim,
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
                          color: AppTheme.silver,
                          size: ResponsiveUtils.sf(context, 14),
                        ),
                        SizedBox(width: ResponsiveUtils.sw(context, 6)),
                        Text(
                          '${_dateFormat.format(orderDate)} at ${_timeFormat.format(orderDate)}',
                          style: TextStyle(
                            color: AppTheme.silver,
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
                            color: AppTheme.fg,
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
                                  decoration: const BoxDecoration(
                                    color: AppTheme.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: ResponsiveUtils.sw(context, 8)),
                                Expanded(
                                  child: Text(
                                    itemName,
                                    style: TextStyle(
                                      color: AppTheme.silver,
                                      fontSize: ResponsiveUtils.sf(context, 13),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  'x$quantity',
                                  style: TextStyle(
                                    color: AppTheme.silver,
                                    fontSize: ResponsiveUtils.sf(context, 12),
                                  ),
                                ),
                                SizedBox(width: ResponsiveUtils.sw(context, 8)),
                                  Text(
                                    '${CurrencyService.formatPrice(price * quantity)}',
                                    style: TextStyle(
                                      color: AppTheme.fg,
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
                                color: AppTheme.dim,
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
                      color: AppTheme.surface2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.lineSoft, width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            color: AppTheme.fg,
                            fontSize: ResponsiveUtils.sf(context, 14),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${totalAmount.toStringAsFixed(2)} DA',
                          style: TextStyle(
                            color: AppTheme.fg,
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
                          backgroundColor: AppTheme.danger,
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
        badgeColor = AppTheme.success; // deep green, legible on light
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
      case 'processing':
        badgeColor = const Color(0xFFB4690E); // deep amber
        statusIcon = Icons.pending;
        break;
      case 'cancelled':
        badgeColor = AppTheme.danger;
        statusIcon = Icons.cancel;
        break;
      case 'shipped':
        badgeColor = const Color(0xFF2563EB); // deep blue
        statusIcon = Icons.local_shipping;
        break;
      default:
        badgeColor = AppTheme.silver;
        statusIcon = Icons.help_outline;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.sw(context, 10),
        vertical: ResponsiveUtils.sh(context, 5),
      ),
      decoration: BoxDecoration(
        color: badgeColor,
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
