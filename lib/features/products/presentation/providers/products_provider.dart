import 'package:flutter/material.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/usecases/get_products.dart';
import '../../domain/usecases/get_featured_products.dart';
import '../../../../core/usecases/usecase.dart';

class ProductsProvider extends ChangeNotifier {
  final GetProducts getProductsUseCase;
  final GetFeaturedProducts getFeaturedProductsUseCase;

  ProductsProvider({
    required this.getProductsUseCase,
    required this.getFeaturedProductsUseCase,
  });

  List<ProductEntity> _products = [];
  List<ProductEntity> _featuredProducts = [];
  bool _isLoading = false;
  String? _error;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  List<ProductEntity> get products => _products;
  List<ProductEntity> get featuredProducts => _featuredProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get hasProducts => _products.isNotEmpty;
  bool get isCacheValid {
    if (_lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheDuration;
  }

  List<ProductEntity> filterByCategory(String category) {
    if (category == 'All') return _products;
    return _products.where((p) => p.category == category).toList();
  }

  List<ProductEntity> filterByBrand(String brand) {
    return _products.where((p) => p.brand.toLowerCase() == brand.toLowerCase()).toList();
  }

  List<ProductEntity> searchProducts(String query) {
    if (query.isEmpty) return _products;
    final lowerQuery = query.toLowerCase();
    return _products.where((p) =>
      p.name.toLowerCase().contains(lowerQuery) ||
      p.brand.toLowerCase().contains(lowerQuery) ||
      p.model.toLowerCase().contains(lowerQuery) ||
      p.description.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  Future<void> fetchProducts({bool forceRefresh = false}) async {
    if (!forceRefresh && isCacheValid && _products.isNotEmpty) {
      debugPrint('Using cached products data');
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await getProductsUseCase(NoParams());
      
      result.fold(
        (failure) {
          _error = _getErrorMessage(failure.message);
          debugPrint('Products fetch failed: $_error');
        },
        (products) {
          if (_validateProducts(products)) {
            _products = products;
            _lastFetchTime = DateTime.now();
            _retryCount = 0;
            debugPrint('Successfully fetched ${products.length} products');
          } else {
            _error = 'Invalid products data received';
            debugPrint('Products validation failed');
          }
        },
      );
    } catch (e) {
      _error = 'Unexpected error: ${e.toString()}';
      debugPrint('Unexpected error in fetchProducts: $e');
      
      if (_retryCount < _maxRetries) {
        _retryCount++;
        debugPrint('Retrying fetch products ($_retryCount/$_maxRetries)');
        await Future.delayed(Duration(seconds: _retryCount * 2));
        return fetchProducts(forceRefresh: forceRefresh);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchFeaturedProducts({bool forceRefresh = false}) async {
    if (!forceRefresh && isCacheValid && _featuredProducts.isNotEmpty) {
      debugPrint('Using cached featured products data');
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await getFeaturedProductsUseCase(NoParams());
      
      result.fold(
        (failure) {
          _error = _getErrorMessage(failure.message);
          debugPrint('Featured products fetch failed: $_error');
        },
        (products) {
          if (_validateProducts(products)) {
            _featuredProducts = products;
            _lastFetchTime = DateTime.now();
            _retryCount = 0;
            debugPrint('Successfully fetched ${products.length} featured products');
          } else {
            _error = 'Invalid featured products data received';
            debugPrint('Featured products validation failed');
          }
        },
      );
    } catch (e) {
      _error = 'Unexpected error: ${e.toString()}';
      debugPrint('Unexpected error in fetchFeaturedProducts: $e');
      
      if (_retryCount < _maxRetries) {
        _retryCount++;
        debugPrint('Retrying fetch featured products ($_retryCount/$_maxRetries)');
        await Future.delayed(Duration(seconds: _retryCount * 2));
        return fetchFeaturedProducts(forceRefresh: forceRefresh);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAll({bool forceRefresh = false}) async {
    await Future.wait([
      fetchProducts(forceRefresh: forceRefresh),
      fetchFeaturedProducts(forceRefresh: forceRefresh),
    ]);
  }

  bool _validateProducts(List<ProductEntity> products) {
    if (products.isEmpty) return true;
    
    for (final product in products) {
      if (product.id <= 0 || product.name.isEmpty || product.price < 0) {
        return false;
      }
    }
    return true;
  }

  String _getErrorMessage(String originalError) {
    if (originalError.toLowerCase().contains('network')) {
      return 'Network connection error. Please check your internet connection.';
    } else if (originalError.toLowerCase().contains('server')) {
      return 'Server error. Please try again later.';
    } else if (originalError.toLowerCase().contains('timeout')) {
      return 'Request timeout. Please try again.';
    }
    return 'An error occurred. Please try again.';
  }

  void refreshData() {
    _lastFetchTime = null;
    fetchAll(forceRefresh: true);
  }

  void forceRefresh() {
    _lastFetchTime = null;
    _retryCount = 0;
    fetchAll(forceRefresh: true);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
