import 'package:flutter/foundation.dart';
import '../features/products/domain/entities/product_entity.dart';

class CartProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _cartItems = [];

  List<Map<String, dynamic>> get cartItems => List.unmodifiable(_cartItems);

  double get totalAmount {
    double total = 0.0;
    for (var item in _cartItems) {
      try {
        final product = item['product'];
        final quantity = item['quantity'];
        
        if (product is ProductEntity && quantity is int && quantity > 0) {
          total += product.price * quantity;
        }
      } catch (e) {
        debugPrint('Error calculating cart total: $e');
      }
    }
    return total;
  }

  int get itemCount {
    int count = 0;
    for (var item in _cartItems) {
      try {
        final quantity = item['quantity'];
        if (quantity is int && quantity > 0) {
          count += quantity;
        }
      } catch (e) {
        debugPrint('Error calculating item count: $e');
      }
    }
    return count;
  }

  bool get isEmpty => _cartItems.isEmpty;
  bool get isNotEmpty => _cartItems.isNotEmpty;

  bool addToCart(ProductEntity product, int quantity, {String? selectedColor, String? selectedSize}) {
    if (quantity <= 0) return false;
    
    try {
      final existingIndex = _cartItems.indexWhere(
        (item) {
          final itemProduct = item['product'];
          final itemColor = item['selectedColor'];
          final itemSize = item['selectedSize'];
          return itemProduct is ProductEntity && 
                 itemProduct.id == product.id &&
                 itemColor == selectedColor &&
                 itemSize == selectedSize;
        },
      );

      if (existingIndex >= 0) {
        final currentQuantity = _cartItems[existingIndex]['quantity'] as int? ?? 0;
        _cartItems[existingIndex]['quantity'] = currentQuantity + quantity;
      } else {
        _cartItems.add({
          'product': product,
          'quantity': quantity,
          'selectedColor': selectedColor ?? (product.colors.isNotEmpty ? product.colors.first : null),
          'selectedSize': selectedSize ?? (product.sizes.isNotEmpty ? product.sizes.first : null),
          'addedAt': DateTime.now().toIso8601String(),
        });
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      return false;
    }
  }

  bool removeFromCart(int productId, {String? selectedColor, String? selectedSize}) {
    try {
      final initialLength = _cartItems.length;
      _cartItems.removeWhere(
        (item) {
          final itemProduct = item['product'];
          final itemColor = item['selectedColor'];
          final itemSize = item['selectedSize'];
          return itemProduct is ProductEntity && 
                 itemProduct.id == productId &&
                 itemColor == selectedColor &&
                 itemSize == selectedSize;
        },
      );
      
      if (_cartItems.length != initialLength) {
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error removing from cart: $e');
      return false;
    }
  }

  bool updateQuantity(int productId, int quantity, {String? selectedColor, String? selectedSize}) {
    if (quantity < 0) return false;
    
    try {
      final index = _cartItems.indexWhere(
        (item) {
          final itemProduct = item['product'];
          final itemColor = item['selectedColor'];
          final itemSize = item['selectedSize'];
          return itemProduct is ProductEntity && 
                 itemProduct.id == productId &&
                 itemColor == selectedColor &&
                 itemSize == selectedSize;
        },
      );
      
      if (index >= 0) {
        if (quantity == 0) {
          _cartItems.removeAt(index);
        } else {
          _cartItems[index]['quantity'] = quantity;
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating cart quantity: $e');
      return false;
    }
  }

  bool isInCart(int productId, {String? selectedColor, String? selectedSize}) {
    return _cartItems.any((item) {
      final itemProduct = item['product'];
      final itemColor = item['selectedColor'];
      final itemSize = item['selectedSize'];
      return itemProduct is ProductEntity && 
             itemProduct.id == productId &&
             itemColor == selectedColor &&
             itemSize == selectedSize;
    });
  }

  int? getQuantity(int productId, {String? selectedColor, String? selectedSize}) {
    try {
      final item = _cartItems.firstWhere(
        (item) {
          final itemProduct = item['product'];
          final itemColor = item['selectedColor'];
          final itemSize = item['selectedSize'];
          return itemProduct is ProductEntity && 
                 itemProduct.id == productId &&
                 itemColor == selectedColor &&
                 itemSize == selectedSize;
        },
        orElse: () => <String, dynamic>{},
      );
      return item['quantity'] as int?;
    } catch (e) {
      debugPrint('Error getting quantity: $e');
      return null;
    }
  }

  void clearCart() {
    try {
      _cartItems.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing cart: $e');
    }
  }

  Map<String, dynamic> getCheckoutData() {
    return {
      'items': _cartItems.map((item) => {
        'product_id': (item['product'] as ProductEntity).id,
        'quantity': item['quantity'] as int,
        'price': (item['product'] as ProductEntity).price,
        'selected_color': item['selectedColor'],
        'selected_size': item['selectedSize'],
      }).toList(),
      'totalAmount': totalAmount,
      'itemCount': itemCount,
    };
  }
}
