// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unused_import

import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/gold_cta.dart';
import '../../../../theme/myazz_tokens.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/security/input_sanitizer.dart';
import '../../../../core/security/rate_limiter.dart';
import '../../../../core/widgets/add_to_cart_animation.dart';
import '../../../../core/widgets/press_scale.dart';
import '../../../../core/widgets/price_text.dart';
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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';
  bool _isLoadingCategories = true;
  final GlobalKey _cartKey = GlobalKey();
  final Map<int, GlobalKey> _addButtonKeys = {};

  GlobalKey _addButtonKeyFor(int productId) =>
      _addButtonKeys.putIfAbsent(productId, GlobalKey.new);

  void _onAddToCart(ProductEntity product, GlobalKey buttonKey) {
    if (!product.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This product is currently unavailable'),
          backgroundColor: AppTheme.danger,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final selectedColor =
        product.colors.isNotEmpty ? product.colors.first : null;
    final selectedSize = product.sizes.isNotEmpty ? product.sizes.first : null;

    AddToCartAnimation.run(
      context: context,
      vsync: this,
      sourceKey: buttonKey,
      cartKey: _cartKey,
      flyColor: AppTheme.primaryColor,
      iconColor: AppTheme.bg,
      icon: Icons.add_shopping_cart,
      onComplete: () {
        if (!mounted) return;
        final added = cartProvider.addToCart(
          product,
          1,
          selectedColor: selectedColor,
          selectedSize: selectedSize,
        );
        if (added) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${product.name} added to cart'),
              // Semantic success stays muted (myazz-ui: gold is accent-only).
              backgroundColor: AppTheme.success,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Removed automatic refresh to prevent unnecessary rebuilds
    // Data is already loaded in initState
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
        // Fallback to the real DB categories if the API fails (kept in
        // French so filtering still matches product.category values).
        setState(() {
          _categories = [
            'All',
            'Montres connectées',
            'Casques audio',
            'Écouteurs',
            'Enceintes',
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
      body: Consumer<ProductsProvider>(
        builder: (context, productsProvider, child) {
          if (productsProvider.isLoading && productsProvider.products.isEmpty) {
            return SafeArea(bottom: false, child: _buildShimmerLoading());
          }

          final filteredProducts =
              _filteredProducts(productsProvider.products);

          // Featured hero treatment (website-style): the featured product —
          // or, with a small catalog, simply the first one — gets a wide
          // banner card on the "All" tab; the rest stay in the grid.
          ProductEntity? heroProduct;
          if (_selectedCategory == 'All' && filteredProducts.isNotEmpty) {
            for (final p in filteredProducts) {
              if (p.isFeatured) {
                heroProduct = p;
                break;
              }
            }
            heroProduct ??= filteredProducts.first;
          }
          final hero = heroProduct;
          final gridProducts = hero == null
              ? filteredProducts
              : filteredProducts.where((p) => p.id != hero.id).toList();

          // Height of the sticky frosted header — must mirror
          // [_buildStickyHeader] exactly so grid content starts right
          // below it and scrolls UNDER the blur.
          final topInset = MediaQuery.of(context).padding.top;
          final headerHeight = topInset +
              10 + // header top padding
              ResponsiveUtils.sh(context, 45) + // top bar row
              14 + // gap
              ResponsiveUtils.sh(context, 30) + // category rail
              ResponsiveUtils.sh(context, 10) + // rail breathing room
              9 + // header bottom padding
              1; // hairline border

          return Stack(
            children: [
              // Scrolling grid — passes behind the frosted header and the
              // floating glass tab bar (MainScreen).
              Positioned.fill(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        top: headerHeight + ResponsiveUtils.sh(context, 16),
                        bottom: 100,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (hero != null) ...[
                            _buildFeaturedHero(hero),
                            SizedBox(height: ResponsiveUtils.sh(context, 20)),
                          ],
                          if (filteredProducts.isEmpty)
                            _buildEmptyCategory()
                          else
                            _buildProductGrid(gridProducts),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Sticky frosted-glass header (search + categories)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: _buildStickyHeader(
                      topInset,
                      productsProvider.products,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Frosted header bar: real glass over the scrolling product grid.
  /// Kept as a tight RepaintBoundary'd strip — never a full-screen blur.
  /// (myazz-ui: blur 24 for card-tier glass; this + hero + nav = 3 layers,
  /// inside the ≤6 budget.)
  Widget _buildStickyHeader(double topInset, List<ProductEntity> allProducts) {
    return RepaintBoundary(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: EdgeInsets.only(top: topInset + 10, bottom: 9),
            decoration: BoxDecoration(
              color: AppTheme.glassFill,
              border: const Border(
                bottom: BorderSide(color: AppTheme.line, width: 1),
              ),
            ),
            child: Column(
              children: [
                _buildTopBar(allProducts),
                const SizedBox(height: 14),
                _buildCategories(),
              ],
            ),
          ),
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
              onTap: () async {
                final selectedProduct = await showSearch<ProductEntity?>(
                  context: context,
                  delegate: ProductSearchDelegate(allProducts),
                );
                if (selectedProduct != null && mounted) {
                  Navigator.pushNamed(
                    context,
                    '/product_details',
                    arguments: selectedProduct,
                  );
                }
              },
              child: Container(
                height: ResponsiveUtils.sh(context, 45),
                decoration: BoxDecoration(
                  // Translucent white pill over the frosted header —
                  // reads as a lighter pane of the same glass.
                  color: AppTheme.glassFill,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: AppTheme.glassBorder,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(width: ResponsiveUtils.sw(context, 15)),
                    Icon(Icons.search, color: AppTheme.dim, size: ResponsiveUtils.sf(context, 20)),
                    SizedBox(width: ResponsiveUtils.sw(context, 10)),
                    Expanded(
                      child: Text(
                        'Search luxury watches...',
                        style: TextStyle(
                          color: AppTheme.dim,
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
          // Store — home IS the store tab, so this grounds the user back on
          // the '/home' root (no-op when already there, pops any pushed
          // routes otherwise). Favorites stay reachable from Profile.
          IconButton(
            icon: const Icon(Icons.storefront_outlined, color: AppTheme.fg),
            onPressed: () {
              Navigator.popUntil(context, ModalRoute.withName('/home'));
            },
          ),
          // Cart (fly-to-cart target + bounce on count increase)
          Selector<CartProvider, int>(
            selector: (_, cart) => cart.itemCount,
            builder: (context, itemCount, _) {
              return AnimatedCartIcon(
                key: _cartKey,
                itemCount: itemCount,
                iconColor: AppTheme.fg,
                onPressed: () {
                  Navigator.pushNamed(context, '/cart');
                },
              );
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
              baseColor: const Color(0xFFE9E7E0),
              highlightColor: const Color(0xFFF6F5F0),
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
              baseColor: const Color(0xFFE9E7E0),
              highlightColor: const Color(0xFFF6F5F0),
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
                  baseColor: const Color(0xFFE9E7E0),
                  highlightColor: const Color(0xFFF6F5F0),
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

  /// Wide banner card for the featured product — myazz-ui ProductCard
  /// language: GlassCard over the pearl gradient, muted category label, bold
  /// ink name, GoldShader price numerals with a gold underline, and a
  /// compact GoldButton that flies to the header cart. (The hero's ONE gold
  /// accent moment — no sheen here; the sheen budget goes to details/cart.)
  Widget _buildFeaturedHero(ProductEntity product) {
    final buttonKey = _addButtonKeyFor(product.id);
    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: ResponsiveUtils.padding(context)),
      child: PressScale(
        scale: 0.985,
        onTap: () => Navigator.pushNamed(
          context,
          '/product_details',
          arguments: product,
        ),
        child: AppTheme.glass(
          radius: M.rCard,
          child: Padding(
            padding: EdgeInsets.all(ResponsiveUtils.sw(context, 16)),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product.category,
                        style: TextStyle(
                          color: AppTheme.silver,
                          fontSize: ResponsiveUtils.sf(context, 11),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: ResponsiveUtils.sh(context, 6)),
                      Text(
                        product.name,
                        style: TextStyle(
                          color: AppTheme.fg,
                          fontSize: ResponsiveUtils.sf(context, 20),
                          fontWeight: FontWeight.bold,
                          height: 1.15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: ResponsiveUtils.sh(context, 10)),
                      PriceText(
                        price: product.price,
                        fontSize: ResponsiveUtils.sf(context, 24),
                        gold: true,
                      ),
                      // Gold underline (myazz-ui ProductCard price treatment)
                      SizedBox(height: ResponsiveUtils.sh(context, 6)),
                      Container(
                        width: ResponsiveUtils.sw(context, 34),
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: AppTheme.goldGradient,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.sh(context, 14)),
                      GoldButton(
                        key: buttonKey,
                        label: product.isAvailable
                            ? 'Add to Cart'
                            : 'Unavailable',
                        icon: product.isAvailable
                            ? Icons.add_shopping_cart
                            : Icons.block,
                        onTap: product.isAvailable
                            ? () => _onAddToCart(product, buttonKey)
                            : null,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: ResponsiveUtils.sw(context, 14)),
                // Transparent-PNG product shot on a raised pearl tile with
                // generous padding so it floats instead of touching edges.
                Expanded(
                  flex: 2,
                  child: Container(
                    height: ResponsiveUtils.sh(context, 150),
                    padding: EdgeInsets.all(ResponsiveUtils.sw(context, 14)),
                    decoration: BoxDecoration(
                      color: AppTheme.surface2,
                      borderRadius: BorderRadius.circular(M.rTile),
                      border: Border.all(color: AppTheme.lineSoft, width: 1),
                    ),
                    child: product.image.startsWith('assets/')
                        ? Image.asset(
                            product.image,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.watch,
                              color: AppTheme.dim,
                              size: 50,
                            ),
                          )
                        : CachedNetworkImage(
                            imageUrl: product.image,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.accent,
                                strokeWidth: 2,
                              ),
                            ),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.watch,
                              color: AppTheme.dim,
                              size: 50,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Graceful state for categories that have no products yet — one line,
  /// muted, on-brand. No blank voids.
  Widget _buildEmptyCategory() {
    return Padding(
      padding: EdgeInsets.only(
        top: ResponsiveUtils.sh(context, 72),
        bottom: ResponsiveUtils.sh(context, 48),
      ),
      child: Column(
        children: [
          Container(
            width: ResponsiveUtils.sw(context, 72),
            height: ResponsiveUtils.sw(context, 72),
            decoration: BoxDecoration(
              color: AppTheme.surface2,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.lineSoft, width: 1),
            ),
            child: Icon(
              Icons.watch_later_outlined,
              color: AppTheme.dim,
              size: ResponsiveUtils.sf(context, 30),
            ),
          ),
          SizedBox(height: ResponsiveUtils.sh(context, 16)),
          Text(
            'Bientôt disponible',
            style: TextStyle(
              color: AppTheme.silver,
              fontSize: ResponsiveUtils.sf(context, 14),
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

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
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Loading categories...',
                    style: TextStyle(
                      color: AppTheme.silver,
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
                    margin: EdgeInsets.only(right: ResponsiveUtils.sw(context, 20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          category,
                          style: TextStyle(
                            color: isSelected ? AppTheme.fg : AppTheme.silver,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: ResponsiveUtils.sf(context, 15),
                            fontFamily: 'Inter',
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.sh(context, 5)),
                        if (isSelected)
                          Container(
                            height: ResponsiveUtils.sh(context, 2.5),
                            width: ResponsiveUtils.sw(context, 25),
                            decoration: BoxDecoration(
                              color: AppTheme.accent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Breathing room below the rail — the frosted header's hairline
          // bottom border replaces the old in-flow divider.
          SizedBox(height: ResponsiveUtils.sh(context, 10)),
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
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: false,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: ResponsiveUtils.gridAspectRatio(context),
          crossAxisSpacing: ResponsiveUtils.sw(context, 12),
          mainAxisSpacing: ResponsiveUtils.sh(context, 12),
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          // myazz-ui entrance: staggered fade-up (40ms stagger, first 8
          // items only — later cards render instantly). Hand-rolled, no
          // flutter_animate; honors MediaQuery.disableAnimations.
          return _StaggerFadeUp(
            index: index,
            child: _buildProductCard(product),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(ProductEntity product) {
    return PressScale(
      scale: 0.97,
      onTap: () {
        Navigator.pushNamed(
          context,
          '/product_details',
          arguments: product,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          // Solid fill for list/grid items (skill rule: keep blur for
          // header/nav/sheets, not heavy card lists) + M-style soft shadow.
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.line, width: 1),
          borderRadius: BorderRadius.circular(M.rTile),
          boxShadow: AppTheme.cardShadows,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(M.rTile),
          child: Stack(
            children: [
              // Product Image on a raised ivory tile — padded so the
              // transparent-PNG shot floats with breathing room.
              Positioned.fill(
                child: Container(
                  color: AppTheme.surface2,
                  padding: EdgeInsets.fromLTRB(
                    ResponsiveUtils.sw(context, 10),
                    ResponsiveUtils.sw(context, 10),
                    ResponsiveUtils.sw(context, 10),
                    ResponsiveUtils.sh(context, 56),
                  ),
                  child: product.image.startsWith('assets/')
                      ? Image.asset(
                          product.image,
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.watch,
                            color: AppTheme.dim,
                            size: 50,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: product.image,
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.watch,
                            color: AppTheme.dim,
                            size: 50,
                          ),
                        ),
                ),
              ),
              // Light scrim at the bottom for text readability
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 80,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.surface2.withValues(alpha: 0.0),
                        AppTheme.surface2.withValues(alpha: 0.95),
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
                        color: AppTheme.fg,
                        fontSize: ResponsiveUtils.sf(context, 13),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: ResponsiveUtils.sh(context, 3)),
                    PriceText(
                      price: product.price,
                      fontSize: ResponsiveUtils.sf(context, 13),
                    ),
                  ],
                ),
              ),
              // Add to cart button (plus) at bottom right — flies to header cart
              Positioned(
                bottom: ResponsiveUtils.sh(context, 12),
                right: ResponsiveUtils.sw(context, 10),
                child: Builder(
                  builder: (context) {
                    final buttonKey = _addButtonKeyFor(product.id);
                    return PressScale(
                      key: buttonKey,
                      scale: 0.88,
                      onTap: () => _onAddToCart(product, buttonKey),
                      child: Container(
                        padding: EdgeInsets.all(ResponsiveUtils.sw(context, 6)),
                        decoration: BoxDecoration(
                          color: product.isAvailable
                              ? AppTheme.primaryColor
                              : AppTheme.dim,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          product.isAvailable ? Icons.add : Icons.block,
                          color: AppTheme.bg,
                          size: ResponsiveUtils.sf(context, 18),
                        ),
                      ),
                    );
                  },
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
                    color: product.isAvailable ? AppTheme.success : AppTheme.danger,
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

/// Hand-rolled staggered fade-up entrance (myazz-ui effect budget:
/// opacity 0→1 + translateY 16→0, 420ms, 40ms stagger, capped at 8 items;
/// later items and reduced-motion users get the final state instantly).
/// One-shot on first mount — data refreshes do not replay it.
class _StaggerFadeUp extends StatefulWidget {
  const _StaggerFadeUp({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_StaggerFadeUp> createState() => _StaggerFadeUpState();
}

class _StaggerFadeUpState extends State<_StaggerFadeUp>
    with SingleTickerProviderStateMixin {
  static const int _maxAnimated = 8;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  Timer? _delay;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion || widget.index >= _maxAnimated) {
      _controller.value = 1;
    } else {
      _delay = Timer(Duration(milliseconds: 40 * widget.index), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _delay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = M.easeOut.transform(_controller.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - t)),
            child: child,
          ),
        );
      },
      child: RepaintBoundary(child: widget.child),
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
              color: AppTheme.surface.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.line, width: 1),
            ),
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? AppTheme.danger : AppTheme.silver,
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
            style: TextStyle(color: AppTheme.silver),
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
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.watch,
                    color: AppTheme.dim,
                    size: ResponsiveUtils.sf(context, 50),
                  ),
                )
              : CachedNetworkImage(
                  imageUrl: product.image,
                  width: ResponsiveUtils.sw(context, 50),
                  height: ResponsiveUtils.sh(context, 50),
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Icon(
                    Icons.watch,
                    color: AppTheme.dim,
                    size: ResponsiveUtils.sf(context, 50),
                  ),
                  errorWidget: (context, url, error) => Icon(
                    Icons.watch,
                    color: AppTheme.dim,
                    size: ResponsiveUtils.sf(context, 50),
                  ),
                ),
          title: Text(
            product.name,
            style: const TextStyle(color: AppTheme.fg),
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
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.watch,
                    color: AppTheme.dim,
                    size: ResponsiveUtils.sf(context, 50),
                  ),
                )
              : CachedNetworkImage(
                  imageUrl: product.image,
                  width: ResponsiveUtils.sw(context, 50),
                  height: ResponsiveUtils.sh(context, 50),
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Icon(
                    Icons.watch,
                    color: AppTheme.dim,
                    size: ResponsiveUtils.sf(context, 50),
                  ),
                  errorWidget: (context, url, error) => Icon(
                    Icons.watch,
                    color: AppTheme.dim,
                    size: ResponsiveUtils.sf(context, 50),
                  ),
                ),
          title: Text(
            product.name,
            style: const TextStyle(color: AppTheme.fg),
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
