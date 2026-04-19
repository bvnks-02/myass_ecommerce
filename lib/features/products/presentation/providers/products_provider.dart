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

  List<ProductEntity> get products => _products;
  List<ProductEntity> get featuredProducts => _featuredProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get hasProducts => _products.isNotEmpty;

  Future<void> fetchProducts({bool forceRefresh = false}) async {
    if (!forceRefresh && _products.isNotEmpty) return;
    
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
            _retryCount = 0;
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
    if (!forceRefresh && _featuredProducts.isNotEmpty) return;
    
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
            _retryCount = 0;
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
    fetchProducts(forceRefresh: true);
    fetchFeaturedProducts(forceRefresh: true);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
