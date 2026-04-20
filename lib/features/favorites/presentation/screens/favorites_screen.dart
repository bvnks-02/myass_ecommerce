// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../theme/app_theme.dart';
import '../../../../core/services/currency_service.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../../providers/favorites_provider.dart';
import '../../../../providers/cart_provider.dart';
import '../../../products/presentation/screens/product_details_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.blackColor,
      appBar: AppBar(
        backgroundColor: AppTheme.blackColor,
        elevation: 0,
        title: const Text(
          'Favorites',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Consumer<FavoritesProvider>(
        builder: (context, favorites, child) {
          if (favorites.favoriteItems.isEmpty) {
            return _buildEmptyFavorites(context);
          }

          return Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: favorites.favoriteItems.length,
              itemBuilder: (context, index) {
                final product = favorites.favoriteItems[index];
                return _buildFavoriteProductCard(context, product);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyFavorites(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 100,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 20),
          Text(
            'No favorites yet',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Start adding products to your favorites',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/home',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Browse Products'),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteProductCard(
      BuildContext context, ProductEntity product) {
    return Consumer2<FavoritesProvider, CartProvider>(
      builder: (context, favorites, cart, child) {
        final isFavorite = favorites.isFavorite(product.id);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailsScreen(product: product),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2C2C2E), Color(0xFF1C1C1E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Product Image (Opacity 0.9 for dark vibe)
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.9,
                      child: CachedNetworkImage(
                        imageUrl: product.image,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child:
                              CircularProgressIndicator(color: Colors.white24),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.image,
                          color: Colors.white24,
                          size: 50,
                        ),
                      ),
                    ),
                  ),
                  // Dark gradient overlay at the bottom for text readability
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 80,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.0),
                            Colors.black.withOpacity(0.8),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  // Product Info at bottom
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          CurrencyService.formatPrice(product.price),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Favorite toggle
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () {
                        favorites.toggleFavorite(product);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.white : Colors.white70,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
