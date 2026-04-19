import 'package:flutter/foundation.dart';
import '../features/products/domain/entities/product_entity.dart';

class FavoritesProvider extends ChangeNotifier {
  final List<ProductEntity> _favoriteItems = [];

  List<ProductEntity> get favoriteItems => _favoriteItems;

  bool isFavorite(int productId) {
    return _favoriteItems.any((product) => product.id == productId);
  }

  void toggleFavorite(ProductEntity product) {
    final existingIndex = _favoriteItems.indexWhere(
      (item) => item.id == product.id,
    );

    if (existingIndex >= 0) {
      _favoriteItems.removeAt(existingIndex);
    } else {
      _favoriteItems.add(product);
    }
    notifyListeners();
  }

  void addToFavorites(ProductEntity product) {
    if (!isFavorite(product.id)) {
      _favoriteItems.add(product);
      notifyListeners();
    }
  }

  void removeFromFavorites(int productId) {
    _favoriteItems.removeWhere((product) => product.id == productId);
    notifyListeners();
  }

  void clearFavorites() {
    _favoriteItems.clear();
    notifyListeners();
  }
}
