// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unused_import

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../theme/app_theme.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/security/input_sanitizer.dart';
import '../../../../core/security/rate_limiter.dart';
import '../../domain/entities/product_entity.dart';
import '../providers/products_provider.dart';
import '../../../../providers/cart_provider.dart';
import '../../../../providers/favorites_provider.dart';
import '../../../../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when returning from admin screens
    _loadData();
  }

  void _loadData() {
    Future.microtask(() {
      if (mounted) {
        _fetchCategories();
        context.read<ProductsProvider>().forceRefresh();
      }
    });
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final categories = await ApiService.getCategories();
      if (mounted) {
        setState(() {
          _categories = ['All', ...categories];
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // Fallback to hardcoded categories if API fails
        setState(() {
          _categories = [
            'All',
            'Smart watch',
            'Buds',
            'Buds plus',
            'SPEAKERS',
            'Air tag',
            'Watch strap',
          ];
          _isLoadingCategories = false;
        });
      }
    }
  }

  List<ProductEntity> _filteredProducts(List<ProductEntity> products) {
    if (_selectedCategory == 'All') return products;
    if (_selectedCategory == 'Popular') {
      return products.where((p) => p.isFeatured).toList();
    }
    return products.where((p) => p.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Consumer<ProductsProvider>(
          builder: (context, productsProvider, child) {
            if (productsProvider.isLoading &&
                productsProvider.products.isEmpty) {
              return _buildShimmerLoading();
            }

            final filteredProducts =
                _filteredProducts(productsProvider.products);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    _buildTopBar(productsProvider.products),
                    const SizedBox(height: 20),
                    _buildCategories(),
                    const SizedBox(height: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 100),
                        child: _buildProductGrid(filteredProducts),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar(List<ProductEntity> allProducts) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.padding(context)),
      child: Row(
        children: [
          // Logo / Avatar
          Container(
            width: ResponsiveUtils.sw(context, 45),
            height: ResponsiveUtils.sh(context, 45),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: const DecorationImage(
                image: AssetImage(
                    'assets/images/logo.jpeg'), // using logo as placeholder for the cheetah
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: ResponsiveUtils.sw(context, 15)),
          // Search Bar
          Expanded(
            child: GestureDetector(
              onTap: () {
                showSearch(
                  context: context,
                  delegate: ProductSearchDelegate(allProducts),
                );
              },
              child: Container(
                height: ResponsiveUtils.sh(context, 45),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(width: ResponsiveUtils.sw(context, 15)),
                    Icon(Icons.search, color: Colors.grey[400], size: ResponsiveUtils.sf(context, 20)),
                    SizedBox(width: ResponsiveUtils.sw(context, 10)),
                    Expanded(
                      child: Text(
                        'Search luxury watches...',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: ResponsiveUtils.sf(context, 14),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: ResponsiveUtils.sw(context, 15)),
          // Customer Service Icon
          IconButton(
            icon: const Icon(Icons.support_agent, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/support');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Shimmer.fromColors(
              baseColor: Colors.grey[800]!,
              highlightColor: Colors.grey[600]!,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Shimmer.fromColors(
              baseColor: Colors.grey[800]!,
              highlightColor: Colors.grey[600]!,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(5, (index) {
                    return Container(
                      width: 80,
                      height: 40,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                return Shimmer.fromColors(
                  baseColor: Colors.grey[800]!,
                  highlightColor: Colors.grey[600]!,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // _buildFeaturedSlider removed for cheetah app design

  Widget _buildCategories() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.padding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoadingCategories)
            SizedBox(
              height: ResponsiveUtils.sh(context, 30),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Loading categories...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: ResponsiveUtils.sf(context, 12),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: ResponsiveUtils.sh(context, 30),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = category == _selectedCategory;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  child: Container(
                    margin: EdgeInsets.only(right: ResponsiveUtils.sw(context, 25)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          category,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[500],
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: ResponsiveUtils.sf(context, 15),
                            fontFamily: 'Inter',
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.sh(context, 5)),
                        if (isSelected)
                          Container(
                            height: ResponsiveUtils.sh(context, 2),
                            width: ResponsiveUtils.sw(context, 25),
                            color: Colors.white,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: ResponsiveUtils.sh(context, 10)),
          Divider(
              color: Colors.white.withOpacity(0.2), height: 1, thickness: 1),
        ],
      ),
    );
  }

  Widget _buildProductGrid(List<ProductEntity> products) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.padding(context)),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: ResponsiveUtils.gridAspectRatio(context),
          crossAxisSpacing: ResponsiveUtils.sw(context, 15),
          mainAxisSpacing: ResponsiveUtils.sh(context, 15),
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildProductCard(ProductEntity product) {
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
                  child: product.image.startsWith('assets/')
                      ? Image.asset(
                          product.image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.watch,
                            color: Colors.white24,
                            size: 50,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: product.image,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(color: Colors.white24, strokeWidth: 2),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.watch,
                            color: Colors.white24,
                            size: 50,
                          ),
                          memCacheWidth: 400,
                          memCacheHeight: 400,
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
                right: ResponsiveUtils.sw(context, 50),
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
              // Add to cart button (plus) at bottom right
              Positioned(
                bottom: ResponsiveUtils.sh(context, 12),
                right: ResponsiveUtils.sw(context, 10),
                child: GestureDetector(
                  onTap: () {
                    final cartProvider = Provider.of<CartProvider>(context, listen: false);
                    final selectedColor = product.colors.isNotEmpty ? product.colors.first : null;
                    final selectedSize = product.sizes.isNotEmpty ? product.sizes.first : null;
                    cartProvider.addToCart(
                      product,
                      1,
                      selectedColor: selectedColor,
                      selectedSize: selectedSize,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.name} added to cart'),
                        backgroundColor: AppTheme.primaryColor,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(ResponsiveUtils.sw(context, 6)),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add,
                      color: Colors.black,
                      size: ResponsiveUtils.sf(context, 18),
                    ),
                  ),
                ),
              ),
              // Availability indicator
              Positioned(
                top: ResponsiveUtils.sh(context, 10),
                left: ResponsiveUtils.sw(context, 10),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.sw(context, 8),
                    vertical: ResponsiveUtils.sh(context, 4),
                  ),
                  decoration: BoxDecoration(
                    color: product.isAvailable ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        product.isAvailable ? Icons.check_circle : Icons.cancel,
                        color: Colors.white,
                        size: ResponsiveUtils.sf(context, 12),
                      ),
                      SizedBox(width: ResponsiveUtils.sw(context, 4)),
                      Text(
                        product.isAvailable ? 'Available' : 'Unavailable',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ResponsiveUtils.sf(context, 10),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Favorite toggle - extracted to separate widget
              Positioned(
                top: ResponsiveUtils.sh(context, 10),
                right: ResponsiveUtils.sw(context, 10),
                child: _FavoriteIconButton(productId: product.id, product: product),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteIconButton extends StatelessWidget {
  final int productId;
  final ProductEntity product;

  const _FavoriteIconButton({
    required this.productId,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesProvider>(
      builder: (context, favorites, child) {
        final isFavorite = favorites.isFavorite(productId);
        return GestureDetector(
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
        );
      },
    );
  }
}

class ProductSearchDelegate extends SearchDelegate<ProductEntity?> {
  final List<ProductEntity> products;

  ProductSearchDelegate(this.products);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Sanitize search query
    final sanitizedQuery = InputSanitizer.sanitizeSearchQuery(query);
    
    // Rate limiting check
    if (!RateLimiters.search.isAllowed('search')) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Too many search requests. Please try again later.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final results = products.where((product) {
      return product.name.toLowerCase().contains(sanitizedQuery.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final product = results[index];
        return ListTile(
          leading: product.image.startsWith('assets/')
              ? Image.asset(
                  product.image,
                  width: ResponsiveUtils.sw(context, 50),
                  height: ResponsiveUtils.sh(context, 50),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.watch,
                    color: Colors.white24,
                    size: ResponsiveUtils.sf(context, 50),
                  ),
                )
              : CachedNetworkImage(
                  imageUrl: product.image,
                  width: ResponsiveUtils.sw(context, 50),
                  height: ResponsiveUtils.sh(context, 50),
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Icon(
                    Icons.watch,
                    color: Colors.white24,
                    size: ResponsiveUtils.sf(context, 50),
                  ),
                  errorWidget: (context, url, error) => Icon(
                    Icons.watch,
                    color: Colors.white24,
                    size: ResponsiveUtils.sf(context, 50),
                  ),
                ),
          title: Text(
            product.name,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            CurrencyService.formatPrice(product.price),
            style: const TextStyle(color: AppTheme.primaryColor),
          ),
          onTap: () {
            close(context, product);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Sanitize search query
    final sanitizedQuery = InputSanitizer.sanitizeSearchQuery(query);
    
    final suggestions = products.where((product) {
      return product.name.toLowerCase().contains(sanitizedQuery.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final product = suggestions[index];
        return ListTile(
          leading: product.image.startsWith('assets/')
              ? Image.asset(
                  product.image,
                  width: ResponsiveUtils.sw(context, 50),
                  height: ResponsiveUtils.sh(context, 50),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.watch,
                    color: Colors.white24,
                    size: ResponsiveUtils.sf(context, 50),
                  ),
                )
              : CachedNetworkImage(
                  imageUrl: product.image,
                  width: ResponsiveUtils.sw(context, 50),
                  height: ResponsiveUtils.sh(context, 50),
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Icon(
                    Icons.watch,
                    color: Colors.white24,
                    size: ResponsiveUtils.sf(context, 50),
                  ),
                  errorWidget: (context, url, error) => Icon(
                    Icons.watch,
                    color: Colors.white24,
                    size: ResponsiveUtils.sf(context, 50),
                  ),
                ),
          title: Text(
            product.name,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            CurrencyService.formatPrice(product.price),
            style: const TextStyle(color: AppTheme.primaryColor),
          ),
          onTap: () {
            query = product.name;
            showResults(context);
          },
        );
      },
    );
  }
}
