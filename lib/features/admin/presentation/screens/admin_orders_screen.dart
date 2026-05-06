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
  List<dynamic> _filteredOrders = [];
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Pending', 'Shipped', 'Delivered', 'Completed', 'Cancelled'];

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
          _applyFilter();
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

  void _applyFilter() {
    if (_selectedFilter == 'All') {
      _filteredOrders = List.from(_orders);
    } else if (_selectedFilter == 'Completed') {
      _filteredOrders = _orders.where((order) {
        final status = order['status']?.toString().toLowerCase() ?? '';
        return status.contains('completed');
      }).toList();
    } else if (_selectedFilter == 'Delivered') {
      _filteredOrders = _orders.where((order) {
        final status = order['status']?.toString().toLowerCase() ?? '';
        return status.contains('delivered') && !status.contains('completed');
      }).toList();
    } else {
      _filteredOrders = _orders.where((order) {
        final status = order['status']?.toString().toLowerCase() ?? '';
        return status.contains(_selectedFilter.toLowerCase());
      }).toList();
    }
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
      _applyFilter();
    });
  }

  int _getOrderCount(String filter) {
    if (filter == 'All') return _orders.length;
    if (filter == 'Completed') {
      return _orders.where((order) {
        final status = order['status']?.toString().toLowerCase() ?? '';
        return status.contains('completed');
      }).length;
    }
    if (filter == 'Delivered') {
      return _orders.where((order) {
        final status = order['status']?.toString().toLowerCase() ?? '';
        return status.contains('delivered') && !status.contains('completed');
      }).length;
    }
    return _orders.where((order) {
      final status = order['status']?.toString().toLowerCase() ?? '';
      return status.contains(filter.toLowerCase());
    }).length;
  }

  Color _getFilterColor(String filter) {
    switch (filter) {
      case 'Pending':
        return Colors.orange;
      case 'Shipped':
        return Colors.blue;
      case 'Delivered':
        return Colors.teal;
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.white;
    }
  }

  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'Pending':
        return Icons.pending;
      case 'Shipped':
        return Icons.local_shipping;
      case 'Delivered':
        return Icons.home;
      case 'Completed':
        return Icons.check_circle;
      case 'Cancelled':
        return Icons.cancel;
      default:
        return Icons.list;
    }
  }

  Color _getStatusColor(String status) {
    final lowerStatus = status.toLowerCase();
    if (lowerStatus.contains('completed')) return Colors.green;
    if (lowerStatus.contains('delivered')) return Colors.teal;
    if (lowerStatus.contains('shipped')) return Colors.blue;
    if (lowerStatus.contains('cancelled')) return Colors.red;
    return Colors.orange; // Pending
  }

  IconData _getStatusIcon(String status) {
    final lowerStatus = status.toLowerCase();
    if (lowerStatus.contains('completed')) return Icons.check_circle;
    if (lowerStatus.contains('delivered')) return Icons.home;
    if (lowerStatus.contains('shipped')) return Icons.local_shipping;
    if (lowerStatus.contains('cancelled')) return Icons.cancel;
    return Icons.pending;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inDays == 0) {
        if (diff.inHours == 0) {
          return '${diff.inMinutes}m ago';
        }
        return '${diff.inHours}h ago';
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} days ago';
      }
      
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateStr;
    }
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
          : Column(
              children: [
                // Filter Tabs
                Container(
                  height: 55,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final isSelected = _selectedFilter == filter;
                      final filterColor = _getFilterColor(filter);
                      
                      return Material(
                        color: isSelected ? filterColor.withOpacity(0.25) : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                        child: InkWell(
                          onTap: () => _onFilterChanged(filter),
                          borderRadius: BorderRadius.circular(25),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: isSelected ? filterColor : Colors.white.withOpacity(0.2),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected)
                                  Icon(
                                    _getFilterIcon(filter),
                                    color: filterColor,
                                    size: 18,
                                  ),
                                if (isSelected)
                                  const SizedBox(width: 8),
                                Text(
                                  filter,
                                  style: TextStyle(
                                    color: isSelected ? filterColor : Colors.white.withOpacity(0.7),
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Orders List
                Expanded(
                  child: _filteredOrders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getFilterIcon(_selectedFilter),
                                color: Colors.white.withOpacity(0.3),
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No ${_selectedFilter.toLowerCase()} orders',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredOrders.length,
                          itemBuilder: (context, index) {
                            final order = _filteredOrders[index];
                final statusColor = _getStatusColor(order['status']);
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.08),
                        Colors.white.withOpacity(0.02),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Section with Order ID, Status Badge, and Date
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            border: Border(
                              bottom: BorderSide(
                                color: statusColor.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          Icons.shopping_cart_outlined,
                                          color: statusColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Order #${order['id']}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _formatDate(order['created_at']),
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.5),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: statusColor.withOpacity(0.4),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _getStatusIcon(order['status']),
                                          color: statusColor,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          order['status'],
                                          style: TextStyle(
                                            color: statusColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Customer Info Section
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    color: Colors.white.withOpacity(0.6),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Customer Info',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.03),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.08),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order['name'] ?? 'N/A',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    InkWell(
                                      onTap: order['phone'] != null
                                          ? () => _makePhoneCall(order['phone'])
                                          : null,
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.green.withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.phone,
                                              color: Colors.green,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              order['phone'] ?? 'N/A',
                                              style: const TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          color: Colors.white.withOpacity(0.4),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            order['address'] ?? 'N/A',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.7),
                                              fontSize: 13,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Products Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.shopping_bag_outlined,
                                    color: Colors.white.withOpacity(0.6),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Products',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (order['order_items'] != null && order['order_items'] is List)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${order['order_items'].length} item(s)',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.6),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ..._buildProductList(order['order_items']),
                            ],
                          ),
                        ),
                        
                        // Total & Actions Section
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.08),
                                Colors.white.withOpacity(0.02),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            children: [
                              // Total Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.account_balance_wallet_outlined,
                                        color: Colors.green.withOpacity(0.8),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Total Amount',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${_formatPrice(double.tryParse(order['total_amount'].toString()) ?? 0)} DA',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(color: Colors.white12, height: 1),
                              const SizedBox(height: 16),
                              // Action Buttons
                              SizedBox(
                                height: 50,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    _buildStatusButton(
                                      'Pending',
                                      () => _updateOrderStatus(order['id'], 'Pending'),
                                      isActive: order['status']?.toString().toLowerCase() == 'pending',
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 10),
                                    _buildStatusButton(
                                      'Shipped',
                                      () => _updateOrderStatus(order['id'], 'Shipped'),
                                      isActive: order['status']?.toString().toLowerCase() == 'shipped',
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 10),
                                    _buildStatusButton(
                                      'Delivered',
                                      () => _updateOrderStatus(order['id'], 'Delivered'),
                                      isActive: order['status']?.toString().toLowerCase() == 'delivered',
                                      color: Colors.teal,
                                    ),
                                    const SizedBox(width: 10),
                                    _buildStatusButton(
                                      'Completed',
                                      () => _updateOrderStatus(order['id'], 'Completed'),
                                      isActive: order['status']?.toString().toLowerCase() == 'completed',
                                      color: Colors.green,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatusButton(
    String title,
    VoidCallback onPressed, {
    bool isActive = false,
    required Color color,
  }) {
    return Material(
      color: isActive ? color.withOpacity(0.25) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minWidth: 90),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? color : Colors.white.withOpacity(0.2),
              width: isActive ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isActive ? color : Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
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
    // Format with thousands separator, no decimal places
    final roundedPrice = price.round();
    final wholePart = roundedPrice.toString();

    // Add thousands separators
    final buffer = StringBuffer();
    for (int i = 0; i < wholePart.length; i++) {
      if (i > 0 && (wholePart.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(wholePart[i]);
    }

    return buffer.toString();
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
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Product Image
            if (productImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  productImage,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.watch,
                      color: Colors.blue,
                      size: 24,
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.watch,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
            const SizedBox(width: 12),
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Color & Size Chips
                  Row(
                    children: [
                      if (selectedColor != null)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getColorFromName(selectedColor).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _getColorFromName(selectedColor),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                selectedColor,
                                style: TextStyle(
                                  color: _getColorFromName(selectedColor).withOpacity(0.9),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (selectedSize != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.straighten, color: Colors.purple, size: 10),
                              const SizedBox(width: 3),
                              Text(
                                selectedSize,
                                style: const TextStyle(
                                  color: Colors.purple,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Quantity & Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'x$quantity',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_formatPrice(totalItemPrice)} DA',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_formatPrice(price)} DA/u',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }
}
