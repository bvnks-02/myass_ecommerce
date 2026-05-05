// ignore_for_file: unused_local_variable, deprecated_member_use, use_build_context_synchronously, use_build_context_synchronously, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../providers/cart_provider.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../../theme/app_theme.dart';
import '../../../../services/api_service.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/security/input_sanitizer.dart';
import '../../../../core/security/input_validator.dart';
import '../../../../core/security/rate_limiter.dart';
import '../../../orders/presentation/screens/user_orders_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.blackColor,
      appBar: AppBar(
        backgroundColor: AppTheme.blackColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cart',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserOrdersScreen()),
              );
            },
            tooltip: 'Order History',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<CartProvider>(
              builder: (context, cart, child) {
                if (cart.cartItems.isEmpty) {
                  return _buildEmptyCart();
                }

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
                      itemCount: cart.cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cart.cartItems[index];
                        final product = item['product'] as ProductEntity;
                        final quantity = item['quantity'] as int;

                        return _buildCartItem(product, quantity, cart, item);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              if (cart.cartItems.isEmpty) {
                return const SizedBox.shrink();
              }
              return _buildCheckoutSection(cart);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: ResponsiveUtils.sf(context, 100),
            color: Colors.grey[600],
          ),
          SizedBox(height: ResponsiveUtils.sh(context, 20)),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: ResponsiveUtils.sf(context, 20),
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveUtils.sh(context, 10)),
          Text(
            'Add products to get started',
            style: TextStyle(
              fontSize: ResponsiveUtils.sf(context, 14),
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: ResponsiveUtils.sh(context, 30)),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/home',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: const Color.fromARGB(255, 0, 0, 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(
      ProductEntity product, int quantity, CartProvider cart, Map<String, dynamic> item) {
    final selectedColor = item['selectedColor'] as String?;
    final selectedSize = item['selectedSize'] as String?;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C2C2E), Color(0xFF1C1C1E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: ResponsiveUtils.sw(context, 80),
            height: ResponsiveUtils.sh(context, 80),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withOpacity(0.05),
            ),
            child: CachedNetworkImage(
              imageUrl: product.image,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              errorWidget: (context, url, error) => Icon(
                Icons.watch,
                color: Colors.white,
                size: ResponsiveUtils.sf(context, 40),
              ),
            ),
          ),
          SizedBox(width: ResponsiveUtils.sw(context, 16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveUtils.sf(context, 16),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: ResponsiveUtils.sh(context, 4)),
                if (selectedColor != null || selectedSize != null)
                  Text(
                    '${selectedColor != null ? 'Color: $selectedColor' : ''}${selectedColor != null && selectedSize != null ? ' • ' : ''}${selectedSize != null ? 'Size: $selectedSize' : ''}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: ResponsiveUtils.sf(context, 12),
                    ),
                  ),
                SizedBox(height: ResponsiveUtils.sh(context, 4)),
                Text(
                  CurrencyService.formatPrice(product.price),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveUtils.sf(context, 16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardColorSecondary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove,
                          size: ResponsiveUtils.sf(context, 18), color: Colors.white),
                      onPressed: quantity > 1
                          ? () {
                              cart.updateQuantity(
                                product.id, 
                                quantity - 1,
                                selectedColor: selectedColor,
                                selectedSize: selectedSize,
                              );
                            }
                          : null,
                    ),
                    Container(
                      width: ResponsiveUtils.sw(context, 30),
                      alignment: Alignment.center,
                      child: Text(
                        '$quantity',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ResponsiveUtils.sf(context, 14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon:
                          Icon(Icons.add, size: ResponsiveUtils.sf(context, 18), color: Colors.white),
                      onPressed: () {
                        cart.updateQuantity(
                          product.id, 
                          quantity + 1,
                          selectedColor: selectedColor,
                          selectedSize: selectedSize,
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: ResponsiveUtils.sh(context, 8)),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    size: ResponsiveUtils.sf(context, 20), color: Colors.red),
                onPressed: () {
                  cart.removeFromCart(
                    product.id,
                    selectedColor: selectedColor,
                    selectedSize: selectedSize,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSection(CartProvider cart) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.blackColor,
        border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveUtils.padding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveUtils.sf(context, 18),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  CurrencyService.formatPrice(cart.totalAmount),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveUtils.sf(context, 24),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.sh(context, 20)),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Full Name',
                prefixIcon: const Icon(Icons.person, color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtils.sh(context, 15)),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Phone Number',
                prefixIcon: const Icon(Icons.phone, color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtils.sh(context, 15)),
            TextField(
              controller: _addressController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Delivery Address',
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(bottom: 20.0, right: 5),
                  child: IconButton(
                    icon: const Icon(Icons.location_on, color: Colors.white),
                    onPressed: _getCurrentLocation,
                    padding: const EdgeInsets.all(8.0),
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtils.sh(context, 20)),
            SizedBox(
              width: double.infinity,
              height: ResponsiveUtils.sh(context, 50),
              child: ElevatedButton(
                onPressed: () {
                  _placeOrder(cart);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  'Place Order',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.sf(context, 16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtils.sh(context, 20)),
          ],
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationDisabledDialog();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are denied.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showLocationPermissionDialog();
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        
        // Build a clean address string
        List<String> addressParts = [];
        
        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }
        if (place.country != null && place.country!.isNotEmpty) {
          addressParts.add(place.country!);
        }
        
        String address = addressParts.join(', ');
        _addressController.text = address;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location detected: $address'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLocationDisabledDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text(
          'Location Services Disabled',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Please enable location services to detect your current address automatically.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Geolocator.openLocationSettings();
            },
            child: const Text(
              'Open Settings',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text(
          'Location Permission Denied',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Location permissions are permanently denied. Please enable them in app settings.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Geolocator.openAppSettings();
            },
            child: const Text(
              'Open Settings',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder(CartProvider cart) async {
    // Sanitize inputs
    final name = InputSanitizer.sanitizeString(_nameController.text.trim(), maxLength: 100);
    final phone = InputSanitizer.sanitizeNumeric(_phoneController.text.trim());
    final address = InputSanitizer.sanitizeString(_addressController.text.trim(), maxLength: 500);
    
    // Validate inputs
    if (name.isEmpty || phone.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final nameError = InputValidator.validateFullName(name);
    if (nameError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(nameError), backgroundColor: Colors.red),
      );
      return;
    }
    
    final phoneError = InputValidator.validatePhoneNumber(phone);
    if (phoneError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(phoneError), backgroundColor: Colors.red),
      );
      return;
    }
    
    if (address.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address must be at least 10 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Rate limiting check for order placement
    if (!RateLimiters.cart.isAllowed('place_order')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Too many order attempts. Please try again later.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if user is authenticated
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to place an order'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    final orderItems = cart.cartItems.map((item) {
      final product = item['product'] as ProductEntity;
      return {
        'product_id': product.id,
        'quantity': item['quantity'],
        'price': product.price,
        'color': item['selectedColor'],
        'size': item['selectedSize'],
      };
    }).toList();

    try {
      debugPrint('=== Starting order creation ===');
      debugPrint('User ID: ${user.id}');
      debugPrint('Total: ${cart.totalAmount}');
      debugPrint('Name: $name');
      debugPrint('Phone: $phone');
      debugPrint('Address: $address');
      debugPrint('Order items: $orderItems');

      final success = await ApiService.createOrder(
        total: cart.totalAmount,
        name: name,
        phone: phone,
        address: address,
        items: orderItems,
      );

      debugPrint('=== Order creation result: $success ===');

      // Pop the loading dialog
      if (mounted) Navigator.of(context).pop();

      if (success) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppTheme.cardColor,
              title: const Text(
                'Order confirmed!',
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                'Your order has been placed successfully.',
                style: TextStyle(color: Colors.grey),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    cart.clearCart();
                    Navigator.of(context).pop(); // Close dialog only
                    // Navigate back to home instead of popping twice
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/home',
                      (route) => false,
                    );
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order failed. Check console for details.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Pop the loading dialog
      if (mounted) Navigator.of(context).pop();
      
      debugPrint('=== Order creation exception: $e ===');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
