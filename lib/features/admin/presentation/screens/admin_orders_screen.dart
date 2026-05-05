// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../theme/app_theme.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      // Check if user is authenticated
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Not authenticated');
      }

      debugPrint('Fetching orders for admin: ${user.id}');

      // First fetch orders
      final ordersResponse = await _supabase
          .from('orders')
          .select('*')
          .order('created_at', ascending: false);

      final orders = ordersResponse as List<dynamic>;
      debugPrint('Found ${orders.length} orders');

      // Fetch order items with product details for each order
      final List<dynamic> enrichedOrders = [];
      for (final order in orders) {
        final orderId = order['id'];
        if (orderId == null) continue;

        final Map<String, dynamic> orderMap = Map<String, dynamic>.from(order);
        try {
          final itemsResponse = await _supabase
              .from('order_items')
              .select('*, products(id, name, image, images)')
              .eq('order_id', orderId);

          debugPrint('Order $orderId items: $itemsResponse');
          debugPrint('itemsResponse type: ${itemsResponse.runtimeType}');

          // Ensure items is a list and process product data
          final List<dynamic> processedItems = [];
          if (itemsResponse is! List) {
            debugPrint('ERROR: itemsResponse is not a List! Type: ${itemsResponse.runtimeType}');
            orderMap['order_items'] = [];
            enrichedOrders.add(orderMap);
            continue;
          }
          
          for (final item in itemsResponse) {
              final Map<String, dynamic> processedItem = Map<String, dynamic>.from(item);
              // Handle products data - Supabase returns it as a nested object or list
              final productsData = item['products'];
              if (productsData != null) {
                if (productsData is List && productsData.isNotEmpty) {
                  processedItem['products'] = productsData.first;
                } else if (productsData is Map) {
                  processedItem['products'] = productsData;
                }
                debugPrint('Product data for item: ${processedItem['products']}');
              }
              processedItems.add(processedItem);
            }

          orderMap['order_items'] = processedItems;
          enrichedOrders.add(orderMap);
        } catch (itemError) {
          debugPrint('Error fetching items for order $orderId: $itemError');
          // If we can't fetch items, still show the order without items
          orderMap['order_items'] = [];
          enrichedOrders.add(orderMap);
        }
      }

      if (mounted) {
        setState(() {
          _orders = enrichedOrders;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading orders: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load orders: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: _fetchOrders,
            ),
          ),
        );
        setState(() {
          _isLoading = false;
          _orders = [];
        });
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot launch phone dialer')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _updateOrderStatus(int orderId, String newStatus) async {
    try {
      await _supabase
          .from('orders')
          .update({'status': newStatus}).eq('id', orderId);
      _fetchOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    if (status.toLowerCase().contains('delivered')) return Colors.green;
    if (status.toLowerCase().contains('shipped')) return Colors.blue;
    if (status.toLowerCase().contains('cancelled')) return Colors.red;
    return Colors.orange; // Pending
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.blackColor,
      appBar: AppBar(
        title: const Text('Manage Orders',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order ID and Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order #${order['id']}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(order['status'])
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              order['status'],
                              style: TextStyle(
                                color: _getStatusColor(order['status']),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white24, height: 16),
                      // Client Info
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.white54, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              order['name'] ?? 'N/A',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Phone (Clickable)
                      InkWell(
                        onTap: order['phone'] != null
                            ? () => _makePhoneCall(order['phone'])
                            : null,
                        child: Row(
                          children: [
                            const Icon(Icons.phone, color: Colors.green, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              order['phone'] ?? 'N/A',
                              style: TextStyle(
                                color: order['phone'] != null
                                    ? Colors.green
                                    : Colors.white54,
                                fontWeight: FontWeight.w500,
                                decoration: order['phone'] != null
                                    ? TextDecoration.underline
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Address
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, color: Colors.white54, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              order['address'] ?? 'N/A',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white24, height: 16),
                      // Products
                      const Row(
                        children: [
                          Icon(Icons.shopping_bag, color: Colors.white54, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Products:',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ..._buildProductList(order['order_items']),
                      const Divider(color: Colors.white24, height: 16),
                      // Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${_formatPrice(double.tryParse(order['total_amount'].toString()) ?? 0)} DA',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildStatusButton('Pending',
                              () => _updateOrderStatus(order['id'], 'Pending')),
                          const SizedBox(width: 8),
                          _buildStatusButton('Shipped',
                              () => _updateOrderStatus(order['id'], 'Shipped')),
                          const SizedBox(width: 8),
                          _buildStatusButton(
                              'Delivered',
                              () =>
                                  _updateOrderStatus(order['id'], 'Delivered')),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatusButton(String title, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withOpacity(0.3)),
        minimumSize: const Size(60, 30),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: Text(title, style: const TextStyle(fontSize: 12)),
    );
  }

  Color _getColorFromName(String colorName) {
    final lower = colorName.toLowerCase();
    if (lower.contains('black') || lower.contains('midnight')) return Colors.black;
    if (lower.contains('white') || lower.contains('starlight')) return Colors.white;
    if (lower.contains('silver')) return Colors.grey.shade400;
    if (lower.contains('gold')) return Colors.amber;
    if (lower.contains('red')) return Colors.red;
    if (lower.contains('blue')) return Colors.blue;
    if (lower.contains('green')) return Colors.green;
    if (lower.contains('pink')) return Colors.pink;
    if (lower.contains('purple')) return Colors.purple;
    if (lower.contains('orange')) return Colors.orange;
    if (lower.contains('yellow')) return Colors.yellow;
    if (lower.contains('gray') || lower.contains('grey') || lower.contains('carbon') || lower.contains('slate')) return Colors.grey;
    return Colors.blueGrey;
  }

  String _formatPrice(double price) {
    // Format with thousands separator and 3 decimal places
    final formatted = price.toStringAsFixed(3);
    final parts = formatted.split('.');
    final wholePart = parts[0];
    final decimalPart = parts[1];

    // Add thousands separators
    final buffer = StringBuffer();
    for (int i = 0; i < wholePart.length; i++) {
      if (i > 0 && (wholePart.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(wholePart[i]);
    }

    return '${buffer.toString()},$decimalPart';
  }

  List<Widget> _buildProductList(dynamic orderItems) {
    debugPrint('_buildProductList called with: $orderItems');
    debugPrint('orderItems type: ${orderItems.runtimeType}');
    
    if (orderItems == null || orderItems is! List || orderItems.isEmpty) {
      debugPrint('No products found - orderItems: $orderItems');
      return [
        const Text(
          'No products',
          style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
        ),
      ];
    }
    
    debugPrint('Building product list with ${orderItems.length} items');

    return orderItems.map<Widget>((item) {
      final product = item['products'];
      final productName = product != null ? product['name'] ?? 'Unknown' : 'Unknown';
      final productImage = product != null ? (product['image'] ?? (product['images'] != null && product['images'] is List && product['images'].isNotEmpty ? product['images'][0] : null)) : null;
      final quantity = item['quantity'] ?? 0;
      final price = double.tryParse(item['price_at_time']?.toString() ?? '0') ?? 0;
      final totalItemPrice = price * quantity;
      // Get selected color and size from order_item
      final selectedColor = item['color'];
      final selectedSize = item['size'];

      return Container(
        margin: const EdgeInsets.only(left: 24, bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product name with image
            Row(
              children: [
                if (productImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      productImage,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.watch,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.watch,
                      color: Colors.blue,
                      size: 20,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    productName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            // Selected options (Color & Size)
            if (selectedColor != null || selectedSize != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (selectedColor != null)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _getColorFromName(selectedColor).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getColorFromName(selectedColor).withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _getColorFromName(selectedColor),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            selectedColor,
                            style: TextStyle(
                              color: _getColorFromName(selectedColor),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (selectedSize != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.straighten, color: Colors.purple, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            selectedSize,
                            style: const TextStyle(
                              color: Colors.purple,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            // Quantity and Price row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Quantity badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Qty: $quantity',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Price details
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_formatPrice(price)} DA / unit',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      '${_formatPrice(totalItemPrice)} DA',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }
}
