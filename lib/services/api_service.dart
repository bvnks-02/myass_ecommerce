import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/products/domain/entities/product_entity.dart';
import '../features/products/data/models/product_model.dart';
import '../core/utils/logger.dart';

class ApiService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const bool _useMockData = false; // Set to true for development without DB

  static Future<List<ProductEntity>> getProducts() async {
    try {
      if (_useMockData) {
        AppLogger.info('Using mock products data', tag: 'ApiService');
        return _getMockProducts();
      }

      AppLogger.debug('Fetching products from Supabase', tag: 'ApiService');
      final response = await _supabase.from('products').select();
      final List<dynamic> data = response as List<dynamic>;
      
      AppLogger.info('Successfully fetched ${data.length} products', tag: 'ApiService');
      return data.map((json) => ProductModel.fromJson(json)).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching products', tag: 'ApiService', error: e, stackTrace: stackTrace);
      
      // Return mock data as fallback for development
      if (kDebugMode) {
        AppLogger.warning('Falling back to mock data', tag: 'ApiService');
        return _getMockProducts();
      }
      
      rethrow;
    }
  }

  static Future<List<ProductEntity>> getFeaturedProducts() async {
    try {
      if (_useMockData) {
        AppLogger.info('Using mock featured products data', tag: 'ApiService');
        return _getMockProducts().take(3).toList();
      }

      AppLogger.debug('Fetching featured products from Supabase', tag: 'ApiService');
      final response = await _supabase.from('products').select().eq('is_featured', true);
      final List<dynamic> data = response as List<dynamic>;
      
      AppLogger.info('Successfully fetched ${data.length} featured products', tag: 'ApiService');
      return data.map((json) => ProductModel.fromJson(json)).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching featured products', tag: 'ApiService', error: e, stackTrace: stackTrace);
      
      // Return mock data as fallback for development
      if (kDebugMode) {
        AppLogger.warning('Falling back to mock featured data', tag: 'ApiService');
        return _getMockProducts().take(3).toList();
      }
      
      rethrow;
    }
  }

  static Future<bool> createOrder({
    required double total,
    required String phone,
    required String address,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      AppLogger.debug('Creating new order', tag: 'ApiService');
      
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        AppLogger.error('No authenticated user found', tag: 'ApiService');
        return false;
      }

      // 1. Insert order
      final orderResponse = await _supabase
          .from('orders')
          .insert({
            'user_id': userId,
            'total_amount': total,
            'phone': phone,
            'address': address,
            'status': 'Pending',
          })
          .select()
          .single();

      final orderId = orderResponse['id'];
      AppLogger.debug('Order created with ID: $orderId', tag: 'ApiService');

      // 2. Prepare order items
      final orderItemsList = items.map((item) {
        return {
          'order_id': orderId,
          'product_id': item['product_id'],
          'quantity': item['quantity'],
          'price_at_time': item['price'],
        };
      }).toList();

      // 3. Insert order items
      await _supabase.from('order_items').insert(orderItemsList);
      
      AppLogger.info('Order and items created successfully', tag: 'ApiService');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Error creating order', tag: 'ApiService', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  static List<ProductEntity> _getMockProducts() {
    AppLogger.debug('Generating mock products data', tag: 'ApiService');
    
    return [
      const ProductModel(
        id: 1,
        name: 'Apple Watch Series 9',
        description: 'Advanced health features, ECG, blood oxygen monitoring. Always-on Retina display.',
        price: 399.00,
        image: 'https://images.unsplash.com/photo-1546868871-7041f2a55e12?w=400',
        categoryId: 1,
        category: 'Sport',
        isFeatured: true,
      ),
      const ProductModel(
        id: 2,
        name: 'Samsung Galaxy Watch 6',
        description: 'Comprehensive health tracking, sleep analysis, fitness monitoring with GPS.',
        price: 349.99,
        image: 'https://images.unsplash.com/photo-1579586337278-3befd40fd17a?w=400',
        categoryId: 1,
        category: 'Sport',
        isFeatured: true,
      ),
      const ProductModel(
        id: 3,
        name: 'Garmin Fenix 7',
        description: 'Premium multisport GPS watch with solar charging and advanced training features.',
        price: 699.99,
        image: 'https://images.unsplash.com/photo-1508685096489-7aacd43bd3b1?w=400',
        categoryId: 1,
        category: 'Sport',
        isFeatured: true,
      ),
      const ProductModel(
        id: 4,
        name: 'Fossil Gen 6',
        description: 'Classic design with modern smart features. Heart rate, GPS, and Wear OS.',
        price: 299.00,
        image: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400',
        categoryId: 2,
        category: 'Luxury',
      ),
      const ProductModel(
        id: 5,
        name: 'Fitbit Versa 4',
        description: 'Health and fitness tracker with built-in GPS, sleep tracking, and smart notifications.',
        price: 229.99,
        image: 'https://images.unsplash.com/photo-1575311373937-040b8e1fd5b6?w=400',
        categoryId: 3,
        category: 'Fitness',
      ),
      const ProductModel(
        id: 6,
        name: 'Casio G-Shock GBA-900',
        description: 'Rugged sport watch with step tracking and Bluetooth connectivity.',
        price: 149.99,
        image: 'https://images.unsplash.com/photo-1524592094714-0f0654e20314?w=400',
        categoryId: 1,
        category: 'Sport',
      ),
      const ProductModel(
        id: 7,
        name: 'Huawei Watch GT 3',
        description: 'Long battery life up to 14 days. Health monitoring and 100+ workout modes.',
        price: 279.99,
        image: 'https://images.unsplash.com/photo-1508685096489-7aacd43bd3b1?w=400',
        categoryId: 1,
        category: 'Sport',
      ),
      const ProductModel(
        id: 8,
        name: 'Amazfit GTS 4',
        description: 'Slim design with 150+ sports modes, blood oxygen, and stress monitoring.',
        price: 199.99,
        image: 'https://images.unsplash.com/photo-1546868871-7041f2a55e12?w=400',
        categoryId: 3,
        category: 'Fitness',
      ),
    ];
  }
}
