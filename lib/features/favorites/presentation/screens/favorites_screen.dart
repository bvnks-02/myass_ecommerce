// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../theme/app_theme.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../../providers/favorites_provider.dart';
import '../../../../providers/cart_provider.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.blackColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Consumer<FavoritesProvider>(
        builder: (context, favorites, child) {
          if (favorites.favoriteItems.isEmpty) {
            return _buildEmptyFavorites(context);
          }

          return Padding(
            padding: EdgeInsets.only(
              left: ResponsiveUtils.padding(context),
              right: ResponsiveUtils.padding(context),
              top: ResponsiveUtils.sh(context, 16),
              bottom: ResponsiveUtils.sh(context, 100)
            ),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: ResponsiveUtils.gridAspectRatio(context),
                crossAxisSpacing: ResponsiveUtils.sw(context, 15),
                mainAxisSpacing: ResponsiveUtils.sh(context, 15),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(ResponsiveUtils.padding(context)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
            child: Container(
              padding: EdgeInsets.all(ResponsiveUtils.sw(context, 12)),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: ResponsiveUtils.sf(context, 20),
              ),
            ),
          ),
          Text(
            'Favorites',
            style: TextStyle(
              color: Colors.white,
              fontSize: ResponsiveUtils.sf(context, 20),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: ResponsiveUtils.sw(context, 48)),
        ],
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
            size: ResponsiveUtils.sf(context, 100),
            color: Colors.grey[600],
          ),
          SizedBox(height: ResponsiveUtils.sh(context, 20)),
          Text(
            'No favorites yet',
            style: TextStyle(
              fontSize: ResponsiveUtils.sf(context, 20),
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveUtils.sh(context, 10)),
          Text(
            'Start adding products to your favorites',
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
            Navigator.pushNamed(
              context,
              '/product_details',
              arguments: product,
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
                    bottom: ResponsiveUtils.sh(context, 12),
                    left: ResponsiveUtils.sw(context, 12),
                    right: ResponsiveUtils.sw(context, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: ResponsiveUtils.sf(context, 13),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: ResponsiveUtils.sh(context, 2)),
                        Text(
                          CurrencyService.formatPrice(product.price),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: ResponsiveUtils.sf(context, 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Favorite toggle
                  Positioned(
                    top: ResponsiveUtils.sh(context, 10),
                    right: ResponsiveUtils.sw(context, 10),
                    child: GestureDetector(
                      onTap: () {
                        favorites.toggleFavorite(product);
                      },
                      child: Container(
                        padding: EdgeInsets.all(ResponsiveUtils.sw(context, 6)),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.white : Colors.white70,
                          size: ResponsiveUtils.sf(context, 18),
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
