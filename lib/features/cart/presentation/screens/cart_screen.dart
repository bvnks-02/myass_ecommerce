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
import '../../../../theme/gold_cta.dart';
import '../../../../services/api_service.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/security/input_sanitizer.dart';
import '../../../../core/security/input_validator.dart';
import '../../../../core/security/rate_limiter.dart';
import '../../../../core/services/dialog_service.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/price_text.dart';
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
      // Transparent — the root pearl gradient (MaterialApp builder) shows.
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.fg),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cart',
          style: TextStyle(color: AppTheme.fg),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long, color: AppTheme.fg),
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
      body: Stack(
        children: [
          // Cart list — scrolls under the frosted checkout sheet so the
          // blur reads as real glass.
          Positioned.fill(
            child: Consumer<CartProvider>(
              builder: (context, cart, child) {
                if (cart.cartItems.isEmpty) {
                  return _buildEmptyCart();
                }

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 440),
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
          // Floating frosted checkout sheet (capped so the keyboard can
          // never squeeze it into an overflow — it scrolls internally).
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: constraints.maxHeight * 0.78,
                  ),
                  child: Consumer<CartProvider>(
                    builder: (context, cart, child) {
                      if (cart.cartItems.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return _buildCheckoutSection(cart);
                    },
                  ),
                );
              },
            ),
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
          Container(
            width: ResponsiveUtils.sw(context, 110),
            height: ResponsiveUtils.sw(context, 110),
            decoration: BoxDecoration(
              color: AppTheme.surface2,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.lineSoft, width: 1),
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: ResponsiveUtils.sf(context, 48),
              color: AppTheme.dim,
            ),
          ),
          SizedBox(height: ResponsiveUtils.sh(context, 20)),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: ResponsiveUtils.sf(context, 20),
              color: AppTheme.fg,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveUtils.sh(context, 10)),
          Text(
            'Add products to get started',
            style: TextStyle(
              fontSize: ResponsiveUtils.sf(context, 14),
              color: AppTheme.silver,
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
              foregroundColor: AppTheme.bg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: const Text('Continuer mes achats'),
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
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.line, width: 1),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Row(
        children: [
          Container(
            width: ResponsiveUtils.sw(context, 80),
            height: ResponsiveUtils.sh(context, 80),
            padding: EdgeInsets.all(ResponsiveUtils.sw(context, 8)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppTheme.surface2,
              border: Border.all(color: AppTheme.lineSoft, width: 1),
            ),
            child: CachedNetworkImage(
              imageUrl: product.image,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(color: AppTheme.accent),
              ),
              errorWidget: (context, url, error) => Icon(
                Icons.watch,
                color: AppTheme.dim,
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
                    color: AppTheme.fg,
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
                      color: AppTheme.silver,
                      fontSize: ResponsiveUtils.sf(context, 12),
                    ),
                  ),
                SizedBox(height: ResponsiveUtils.sh(context, 4)),
                PriceText(
                  price: product.price,
                  fontSize: ResponsiveUtils.sf(context, 16),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface2,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.line, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove,
                          size: ResponsiveUtils.sf(context, 18), color: AppTheme.fg),
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
                          color: AppTheme.fg,
                          fontSize: ResponsiveUtils.sf(context, 14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon:
                          Icon(Icons.add, size: ResponsiveUtils.sf(context, 18), color: AppTheme.fg),
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
                    size: ResponsiveUtils.sf(context, 20), color: AppTheme.danger),
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
    // Frosted checkout sheet — myazz-ui "strong" glass (fill .82, blur 32):
    // total, delivery fields and CTA float over the scrolling cart list.
    return AppTheme.glass(
      corners: const BorderRadius.vertical(top: Radius.circular(28)),
      strong: true,
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
                    color: AppTheme.silver,
                    fontSize: ResponsiveUtils.sf(context, 14),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                PriceText(
                  price: cart.totalAmount,
                  fontSize: ResponsiveUtils.sf(context, 26),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.sh(context, 20)),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Nom complet',
                prefixIcon: const Icon(Icons.person, color: AppTheme.silver),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.accent, width: 2),
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtils.sh(context, 15)),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Numéro de téléphone',
                prefixIcon: const Icon(Icons.phone, color: AppTheme.silver),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.accent, width: 2),
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtils.sh(context, 15)),
            TextField(
              controller: _addressController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Adresse de livraison',
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(bottom: 20.0, right: 5),
                  child: IconButton(
                    icon: const Icon(Icons.location_on, color: AppTheme.silver),
                    onPressed: _getCurrentLocation,
                    padding: const EdgeInsets.all(8.0),
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.accent, width: 2),
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtils.sh(context, 20)),
            // Primary checkout CTA — myazz-ui StartButton language (gold
            // ring, navy fill, sheen sweep). The ONE sheen on this screen.
            SizedBox(
              width: double.infinity,
              child: GoldCta(
                label: 'Place Order',
                height: ResponsiveUtils.sh(context, 52),
                onTap: () {
                  _placeOrder(cart);
                },
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
            content: Text('Les autorisations de localisation sont refusées.'),
            backgroundColor: AppTheme.danger,
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
            content: Text('Position détectée : $address'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      AppSnackBar.error(context, 'Could not detect your location. Please enter it manually.');
    }
  }

  void _showLocationDisabledDialog() {
    context.dialogs.showLocationDisabled(
      onOpenSettings: () => Geolocator.openLocationSettings(),
      onDismiss: () {},
    );
  }

  void _showLocationPermissionDialog() {
    context.dialogs.showLocationPermissionDenied(
      onOpenSettings: () => Geolocator.openAppSettings(),
      onDismiss: () {},
    );
  }

  Future<void> _placeOrder(CartProvider cart) async {
    // Sanitize inputs
    final name = InputSanitizer.sanitizeString(_nameController.text.trim(), maxLength: 100);
    final phone = InputSanitizer.sanitizeNumeric(_phoneController.text.trim());
    final address = InputSanitizer.sanitizeString(_addressController.text.trim(), maxLength: 500);
    
    // Validate inputs
    if (name.isEmpty || phone.isEmpty || address.isEmpty) {
      AppSnackBar.warning(context, 'Please fill in all delivery details');
      return;
    }
    
    final nameError = InputValidator.validateFullName(name);
    if (nameError != null) {
      AppSnackBar.warning(context, nameError);
      return;
    }
    
    final phoneError = InputValidator.validatePhoneNumber(phone);
    if (phoneError != null) {
      AppSnackBar.warning(context, phoneError);
      return;
    }
    
    if (address.length < 10) {
      AppSnackBar.warning(context, 'Please provide a complete address');
      return;
    }
    
    // Rate limiting check for order placement
    if (!RateLimiters.cart.isAllowed('place_order')) {
      AppSnackBar.warning(context, 'Too many attempts. Please try again in a moment.');
      return;
    }

    // Check if user is authenticated
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      context.dialogs.showLoginRequired(
        onLogin: () => Navigator.of(context).pushNamed('/login'),
      );
      return;
    }

    // Show loading dialog
    context.dialogs.showLoading(message: 'Placing your order...');

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

      // Hide loading dialog
      if (mounted) context.dialogs.hideLoading();

      if (success) {
        if (mounted) {
          cart.clearCart();
          context.dialogs.showOrderSuccess(
            onContinueShopping: () => Navigator.of(context).pushNamedAndRemoveUntil(
              '/home',
              (route) => false,
            ),
            onViewOrders: () => Navigator.of(context).pushNamedAndRemoveUntil(
              '/my_orders',
              (route) => false,
            ),
          );
        }
      } else {
        if (mounted) {
          AppSnackBar.error(context, 'Could not place order. Please try again.');
        }
      }
    } catch (e) {
      // Hide loading dialog
      if (mounted) context.dialogs.hideLoading();
      
      debugPrint('=== Order creation exception: $e ===');
      
      if (mounted) {
        AppSnackBar.error(context, 'Something went wrong. Please try again later.');
      }
    }
  }
}
