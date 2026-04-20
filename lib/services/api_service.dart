import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/products/domain/entities/product_entity.dart';
import '../features/products/data/models/product_model.dart';
import '../core/utils/logger.dart';

class ApiService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const bool _useMockData = true; // Set to true for development without DB

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
        brand: 'Apple',
        model: 'Series 9',
        description: 'Advanced health features, ECG, blood oxygen monitoring. Always-on Retina display.',
        price: 399.00,
        image: 'assets/images/spr1.jpg',
        images: ['assets/images/spr1.jpg', 'assets/images/spr2.jpg', 'assets/images/spr3.jpg', 'assets/images/spr4.jpg', 'assets/images/spr5.jpg', 'assets/images/spr6.jpg'],
        colors: ['Midnight', 'Starlight', 'Silver', 'Red'],
        sizes: ['41mm', '45mm'],
        features: {'battery': '18h', 'waterproof': 'IPX8', 'bluetooth': '5.3', 'gps': true},
        categoryId: 1,
        category: 'Sport',
        isFeatured: true,
      ),
      const ProductModel(
        id: 2,
        name: 'Samsung Galaxy Watch 6',
        brand: 'Samsung',
        model: 'Galaxy Watch 6',
        description: 'Comprehensive health tracking, sleep analysis, fitness monitoring with GPS.',
        price: 349.99,
        image: 'assets/images/spr2.jpg',
        images: ['assets/images/spr1.jpg', 'assets/images/spr2.jpg', 'assets/images/spr3.jpg', 'assets/images/spr4.jpg', 'assets/images/spr5.jpg', 'assets/images/spr6.jpg'],
        colors: ['Black', 'Silver', 'Gold'],
        sizes: ['44mm', '40mm'],
        features: {'battery': '40h', 'waterproof': '5ATM', 'bluetooth': '5.3', 'gps': true},
        categoryId: 1,
        category: 'Sport',
        isFeatured: true,
      ),
      const ProductModel(
        id: 3,
        name: 'Garmin Fenix 7',
        brand: 'Garmin',
        model: 'Fenix 7',
        description: 'Premium multisport GPS watch with solar charging and advanced training features.',
        price: 699.99,
        image: 'assets/images/spr3.jpg',
        images: ['assets/images/spr1.jpg', 'assets/images/spr2.jpg', 'assets/images/spr3.jpg', 'assets/images/spr4.jpg', 'assets/images/spr5.jpg', 'assets/images/spr6.jpg'],
        colors: ['Black', 'Carbon Gray', 'Slate Blue'],
        sizes: ['47mm', '42mm'],
        features: {'battery': '18 days', 'waterproof': '10ATM', 'bluetooth': '5.0', 'gps': true, 'solar': true},
        categoryId: 1,
        category: 'Sport',
        isFeatured: true,
      ),
      const ProductModel(
        id: 4,
        name: 'Fossil Gen 6',
        brand: 'Fossil',
        model: 'Gen 6',
        description: 'Classic design with modern smart features. Heart rate, GPS, and Wear OS.',
        price: 299.00,
        image: 'assets/images/lux1.jpg',
        images: ['assets/images/lux1.jpg', 'assets/images/lux2.jpg', 'assets/images/lux3.jpg', 'assets/images/lux4.jpg', 'assets/images/lux5.jpg', 'assets/images/lux6.jpg'],
        colors: ['Black', 'Rose Gold', 'Silver'],
        sizes: ['44mm', '42mm'],
        features: {'battery': '24h', 'waterproof': '3ATM', 'bluetooth': '5.0', 'gps': true},
        categoryId: 2,
        category: 'Luxury',
      ),
      const ProductModel(
        id: 5,
        name: 'Fitbit Versa 4',
        brand: 'Fitbit',
        model: 'Versa 4',
        description: 'Health and fitness tracker with built-in GPS, sleep tracking, and smart notifications.',
        price: 229.99,
        image: 'assets/images/fit1.jpg',
        images: ['assets/images/fit1.jpg', 'assets/images/fit2.jpg', 'assets/images/fit3.jpg', 'assets/images/fit4.jpg', 'assets/images/fit5.jpg', 'assets/images/fit6.jpg'],
        colors: ['Black', 'Waterfall Blue', 'Pink'],
        sizes: ['40mm'],
        features: {'battery': '6 days', 'waterproof': '5ATM', 'bluetooth': '5.0', 'gps': true},
        categoryId: 3,
        category: 'Fitness',
      ),
      const ProductModel(
        id: 6,
        name: 'Casio G-Shock GBA-900',
        brand: 'Casio',
        model: 'GBA-900',
        description: 'Rugged sport watch with step tracking and Bluetooth connectivity.',
        price: 149.99,
        image: 'assets/images/spr4.jpg',
        images: ['assets/images/spr1.jpg', 'assets/images/spr2.jpg', 'assets/images/spr3.jpg', 'assets/images/spr4.jpg', 'assets/images/spr5.jpg', 'assets/images/spr6.jpg'],
        colors: ['Black', 'White', 'Blue'],
        sizes: ['46mm'],
        features: {'battery': '2 years', 'waterproof': '20ATM', 'bluetooth': '5.0', 'gps': false},
        categoryId: 1,
        category: 'Sport',
      ),
      const ProductModel(
        id: 7,
        name: 'Huawei Watch GT 3',
        brand: 'Huawei',
        model: 'Watch GT 3',
        description: 'Long battery life up to 14 days. Health monitoring and 100+ workout modes.',
        price: 279.99,
        image: 'assets/images/spr5.jpg',
        images: ['assets/images/spr1.jpg', 'assets/images/spr2.jpg', 'assets/images/spr3.jpg', 'assets/images/spr4.jpg', 'assets/images/spr5.jpg', 'assets/images/spr6.jpg'],
        colors: ['Black', 'Brown', 'Grey'],
        sizes: ['46mm', '42mm'],
        features: {'battery': '14 days', 'waterproof': '5ATM', 'bluetooth': '5.2', 'gps': true},
        categoryId: 1,
        category: 'Sport',
      ),
      const ProductModel(
        id: 8,
        name: 'Amazfit GTS 4',
        brand: 'Amazfit',
        model: 'GTS 4',
        description: 'Slim design with 150+ sports modes, blood oxygen, and stress monitoring.',
        price: 199.99,
        image: 'assets/images/fit2.jpg',
        images: ['assets/images/fit1.jpg', 'assets/images/fit2.jpg', 'assets/images/fit3.jpg', 'assets/images/fit4.jpg', 'assets/images/fit5.jpg', 'assets/images/fit6.jpg'],
        colors: ['Black', 'Rose Pink', 'Brown'],
        sizes: ['42mm'],
        features: {'battery': '8 days', 'waterproof': '5ATM', 'bluetooth': '5.0', 'gps': true},
        categoryId: 3,
        category: 'Fitness',
      ),
      const ProductModel(
        id: 9,
        name: 'Rolex Submariner',
        brand: 'Rolex',
        model: 'Submariner',
        description: 'Legendary diving watch with ceramic bezel and luminous dial. Water-resistant to 300m.',
        price: 8999.00,
        image: 'assets/images/lux2.jpg',
        images: ['assets/images/lux1.jpg', 'assets/images/lux2.jpg', 'assets/images/lux3.jpg', 'assets/images/lux4.jpg', 'assets/images/lux5.jpg', 'assets/images/lux6.jpg'],
        colors: ['Black', 'Green', 'Blue'],
        sizes: ['41mm', '40mm'],
        features: {'battery': 'Automatic', 'waterproof': '300m', 'bluetooth': false, 'gps': false},
        categoryId: 2,
        category: 'Luxury',
        isFeatured: true,
      ),
      const ProductModel(
        id: 10,
        name: 'Omega Seamaster',
        brand: 'Omega',
        model: 'Seamaster',
        description: 'Professional diving watch with helium escape valve and anti-magnetic properties.',
        price: 5499.00,
        image: 'assets/images/lux3.jpg',
        images: ['assets/images/lux1.jpg', 'assets/images/lux2.jpg', 'assets/images/lux3.jpg', 'assets/images/lux4.jpg', 'assets/images/lux5.jpg', 'assets/images/lux6.jpg'],
        colors: ['Black', 'Blue', 'Silver'],
        sizes: ['42mm', '40mm'],
        features: {'battery': 'Automatic', 'waterproof': '300m', 'bluetooth': false, 'gps': false},
        categoryId: 2,
        category: 'Luxury',
      ),
      const ProductModel(
        id: 11,
        name: 'Cartier Tank',
        brand: 'Cartier',
        model: 'Tank',
        description: 'Iconic rectangular watch with Roman numerals and blue sapphire crown.',
        price: 6299.00,
        image: 'assets/images/lux4.jpg',
        images: ['assets/images/lux1.jpg', 'assets/images/lux2.jpg', 'assets/images/lux3.jpg', 'assets/images/lux4.jpg', 'assets/images/lux5.jpg', 'assets/images/lux6.jpg'],
        colors: ['Gold', 'Silver', 'Rose Gold'],
        sizes: ['31mm', '35mm'],
        features: {'battery': 'Automatic', 'waterproof': '30m', 'bluetooth': false, 'gps': false},
        categoryId: 2,
        category: 'Luxury',
      ),
      const ProductModel(
        id: 12,
        name: 'Tag Heuer Carrera',
        brand: 'Tag Heuer',
        model: 'Carrera',
        description: 'Sporty chronograph with tachymeter bezel and precision Swiss movement.',
        price: 3999.00,
        image: 'assets/images/lux5.jpg',
        images: ['assets/images/lux1.jpg', 'assets/images/lux2.jpg', 'assets/images/lux3.jpg', 'assets/images/lux4.jpg', 'assets/images/lux5.jpg', 'assets/images/lux6.jpg'],
        colors: ['Black', 'Silver', 'Blue'],
        sizes: ['44mm', '41mm'],
        features: {'battery': 'Automatic', 'waterproof': '100m', 'bluetooth': false, 'gps': false},
        categoryId: 2,
        category: 'Luxury',
      ),
      const ProductModel(
        id: 13,
        name: 'Hamilton Khaki',
        brand: 'Hamilton',
        model: 'Khaki Field',
        description: 'Military-inspired field watch with durable stainless steel case.',
        price: 599.00,
        image: 'assets/images/cla1.jpg',
        images: ['assets/images/cla1.jpg', 'assets/images/cla2.jpg', 'assets/images/cla3.jpg', 'assets/images/cla4.jpg', 'assets/images/cla5.jpg', 'assets/images/cla6.jpg'],
        colors: ['Black', 'Brown', 'Green'],
        sizes: ['42mm', '38mm'],
        features: {'battery': 'Automatic', 'waterproof': '100m', 'bluetooth': false, 'gps': false},
        categoryId: 4,
        category: 'Classic',
      ),
      const ProductModel(
        id: 14,
        name: 'Seiko Presage',
        brand: 'Seiko',
        model: 'Presage',
        description: 'Elegant Japanese watch with enamel dial and mechanical movement.',
        price: 449.00,
        image: 'assets/images/cla2.jpg',
        images: ['assets/images/cla1.jpg', 'assets/images/cla2.jpg', 'assets/images/cla3.jpg', 'assets/images/cla4.jpg', 'assets/images/cla5.jpg', 'assets/images/cla6.jpg'],
        colors: ['Black', 'Blue', 'White'],
        sizes: ['40mm', '38mm'],
        features: {'battery': 'Automatic', 'waterproof': '50m', 'bluetooth': false, 'gps': false},
        categoryId: 4,
        category: 'Classic',
      ),
      const ProductModel(
        id: 15,
        name: 'Tissot PRX',
        brand: 'Tissot',
        model: 'PRX',
        description: 'Vintage-inspired integrated bracelet watch with Swiss quartz movement.',
        price: 399.00,
        image: 'assets/images/cla3.jpg',
        images: ['assets/images/cla1.jpg', 'assets/images/cla2.jpg', 'assets/images/cla3.jpg', 'assets/images/cla4.jpg', 'assets/images/cla5.jpg', 'assets/images/cla6.jpg'],
        colors: ['Silver', 'Gold', 'Black'],
        sizes: ['40mm', '35mm'],
        features: {'battery': 'Quartz', 'waterproof': '100m', 'bluetooth': false, 'gps': false},
        categoryId: 4,
        category: 'Classic',
      ),
      const ProductModel(
        id: 16,
        name: 'Citizen Eco-Drive',
        brand: 'Citizen',
        model: 'Eco-Drive One',
        description: 'Ultra-thin solar-powered watch that never needs a battery change.',
        price: 349.00,
        image: 'assets/images/cla4.jpg',
        images: ['assets/images/cla1.jpg', 'assets/images/cla2.jpg', 'assets/images/cla3.jpg', 'assets/images/cla4.jpg', 'assets/images/cla5.jpg', 'assets/images/cla6.jpg'],
        colors: ['Silver', 'Black', 'Rose Gold'],
        sizes: ['40mm', '36mm'],
        features: {'battery': 'Solar', 'waterproof': '50m', 'bluetooth': false, 'gps': false},
        categoryId: 4,
        category: 'Classic',
      ),
      const ProductModel(
        id: 17,
        name: 'Garmin Forerunner',
        brand: 'Garmin',
        model: 'Forerunner 265',
        description: 'Advanced running watch with multi-band GPS and training readiness score.',
        price: 449.99,
        image: 'assets/images/fit3.jpg',
        images: ['assets/images/fit1.jpg', 'assets/images/fit2.jpg', 'assets/images/fit3.jpg', 'assets/images/fit4.jpg', 'assets/images/fit5.jpg', 'assets/images/fit6.jpg'],
        colors: ['Black', 'White', 'Blue'],
        sizes: ['46mm', '42mm'],
        features: {'battery': '13 days', 'waterproof': '5ATM', 'bluetooth': '5.3', 'gps': true},
        categoryId: 3,
        category: 'Fitness',
      ),
      const ProductModel(
        id: 18,
        name: 'Polar Vantage',
        brand: 'Polar',
        model: 'Vantage V3',
        description: 'Premium multisport watch with wrist-based ECG and recovery tracking.',
        price: 549.99,
        image: 'assets/images/fit4.jpg',
        images: ['assets/images/fit1.jpg', 'assets/images/fit2.jpg', 'assets/images/fit3.jpg', 'assets/images/fit4.jpg', 'assets/images/fit5.jpg', 'assets/images/fit6.jpg'],
        colors: ['Black', 'Grey', 'White'],
        sizes: ['47mm', '43mm'],
        features: {'battery': '8 days', 'waterproof': '100m', 'bluetooth': '5.3', 'gps': true},
        categoryId: 3,
        category: 'Fitness',
      ),
      const ProductModel(
        id: 19,
        name: 'Suunto Race',
        brand: 'Suunto',
        model: 'Race',
        description: 'Lightweight sports watch with vibrant AMOLED display and route navigation.',
        price: 399.99,
        image: 'assets/images/fit5.jpg',
        images: ['assets/images/fit1.jpg', 'assets/images/fit2.jpg', 'assets/images/fit3.jpg', 'assets/images/fit4.jpg', 'assets/images/fit5.jpg', 'assets/images/fit6.jpg'],
        colors: ['Black', 'White', 'Slate'],
        sizes: ['49mm', '44mm'],
        features: {'battery': '26 days', 'waterproof': '100m', 'bluetooth': '5.3', 'gps': true},
        categoryId: 3,
        category: 'Fitness',
      ),
      const ProductModel(
        id: 20,
        name: 'Coros Pace 3',
        brand: 'Coros',
        model: 'Pace 3',
        description: 'Ultra-light GPS watch with advanced running metrics and long battery life.',
        price: 229.99,
        image: 'assets/images/fit6.jpg',
        images: ['assets/images/fit1.jpg', 'assets/images/fit2.jpg', 'assets/images/fit3.jpg', 'assets/images/fit4.jpg', 'assets/images/fit5.jpg', 'assets/images/fit6.jpg'],
        colors: ['Black', 'White', 'Blue'],
        sizes: ['42mm', '38mm'],
        features: {'battery': '17 days', 'waterproof': '50m', 'bluetooth': '5.0', 'gps': true},
        categoryId: 3,
        category: 'Fitness',
      ),
      const ProductModel(
        id: 21,
        name: 'New Arrival Special',
        brand: 'Premium',
        model: 'New Edition',
        description: 'Exclusive new arrival with cutting-edge technology and premium design.',
        price: 599.00,
        image: 'assets/images/new.jpeg',
        images: ['assets/images/new.jpeg', 'assets/images/lux1.jpg', 'assets/images/lux2.jpg', 'assets/images/spr1.jpg', 'assets/images/fit1.jpg', 'assets/images/cla1.jpg'],
        colors: ['Noir', 'Gris'],
        sizes: ['44mm', '40mm'],
        features: {'battery': '7 days', 'waterproof': '5ATM', 'bluetooth': '5.3', 'gps': true},
        categoryId: 1,
        category: 'New',
        isFeatured: true,
      ),
    ];
  }
}
