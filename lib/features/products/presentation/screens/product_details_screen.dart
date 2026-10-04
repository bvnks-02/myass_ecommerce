// ignore_for_file: deprecated_member_use, unused_import, unused_field, prefer_final_fields, prefer_const_constructors, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/gold_cta.dart';
import '../../../../theme/myazz_tokens.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../core/widgets/add_to_cart_animation.dart';
import '../../../../core/widgets/press_scale.dart';
import '../../../../core/widgets/price_text.dart';
import '../../domain/entities/product_entity.dart';
import '../../../../providers/cart_provider.dart';
import '../../../../providers/favorites_provider.dart';

class ProductDetailsScreen extends StatefulWidget {
  final ProductEntity product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen>
    with TickerProviderStateMixin {
  int _quantity = 1;
  int _currentImageIndex = 0;
  int _selectedColorIndex = 0;
  int _selectedSizeIndex = 0;
  int _selectedTabIndex = 0;
  final PageController _pageController = PageController();
  final GlobalKey _cartKey = GlobalKey();
  final GlobalKey _addToCartButtonKey = GlobalKey();

  // ── Palette (myazz-ui "Luminous Glass & Gold" tokens) ──
  static const _bg      = AppTheme.bg;      // pearl #F4F3F1 (ivory-on-dark text)
  static const _surface = Color(0xFFFFFFFF); // white cards
  static const _card    = Color(0xFFF1F0EE); // pearl raised tiles (M.bgBottom)
  static const _divider = Color(0xFFE4E2DB); // hairline borders
  static const _accent  = Color(0xFF14161A); // M.ink: dark pills / primary emphasis
  static const _gold    = Color(0xFFC99A3C); // M.gold3: champagne gold (stars, active rings)

  List<Color> get _colorValues {
    return widget.product.colors.map((colorName) {
      switch (colorName.toLowerCase()) {
        case 'midnight':
        case 'black':
          return const Color(0xFF1A1A1A);
        case 'starlight':
        case 'silver':
        case 'white':
          return const Color(0xFFD3D3D3);
        case 'red':
          return const Color(0xFF8B0000);
        case 'blue':
        case 'slate blue':
          return const Color(0xFF1E3A8A);
        case 'brown':
        case 'carbon gray':
          return const Color(0xFF8B4513);
        case 'gold':
          return const Color(0xFFFFD700);
        case 'rose gold':
        case 'rose pink':
          return const Color(0xFFB76E79);
        case 'grey':
        case 'gray':
          return const Color(0xFF808080);
        case 'waterfall blue':
          return const Color(0xFF4682B4);
        default:
          return const Color(0xFF1A1A1A);
      }
    }).toList();
  }

  final List<String> _tabs = const ['Description', 'Specifications', 'Reviews'];

  List<String> get _productImages {
    if (widget.product.images.isNotEmpty) {
      return widget.product.images;
    }
    if (widget.product.image.isNotEmpty) {
      return [widget.product.image];
    }
    return ['https://via.placeholder.com/400x400/1A1A1A/FF6B00?text=No+Image'];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Transparent — the root pearl gradient (MaterialApp builder) shows.
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            // Scrollable content — passes UNDER the frosted CTA bar so the
            // blur reads as real glass.
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(),
                    _buildImageZone(),
                    const SizedBox(height: 16),
                    _buildProductInfo(),
                    _buildDivider(),
                    if (widget.product.colors.isNotEmpty) _buildColorSection(),
                    if (widget.product.sizes.isNotEmpty) _buildSizeSection(),
                    _buildDivider(),
                    _buildTabSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Floating frosted add-to-cart bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomBar(),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TOP BAR
  // ─────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _iconBtn(
            Icons.arrow_back_ios_new_rounded,
            () => Navigator.pop(context),
          ),
          const Text(
            'Product Details',
            style: TextStyle(
              color: _accent,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              _iconBtn(
                Icons.share,
                () => _showShareBottomSheet(),
              ),
              const SizedBox(width: 4),
              Selector<CartProvider, int>(
                selector: (_, cart) => cart.itemCount,
                builder: (context, itemCount, _) {
                  return AnimatedCartIcon(
                    key: _cartKey,
                    itemCount: itemCount,
                    iconSize: 20,
                    iconColor: _accent,
                    onPressed: () {
                      Navigator.pushNamed(context, '/cart');
                    },
                  );
                },
              ),
              Consumer<FavoritesProvider>(
                builder: (context, favorites, _) {
                  final isFav = favorites.isFavorite(widget.product.id);
                  return _iconBtn(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    () => favorites.toggleFavorite(widget.product),
                    iconColor: isFav ? AppTheme.danger : _accent,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap,
      {Color iconColor = _accent}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _divider, width: 1),
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }

  void _showShareBottomSheet() {
    final deepLink = 'myazz://product/${widget.product.id}';
    // Web fallback URL - replace with your actual web store URL when available
    final webUrl = 'https://myazz-store.com/product/${widget.product.id}';
    final shareText = 'Check out this ${widget.product.name}!\n\nPrice: ${CurrencyService.formatPrice(widget.product.price)}\n\n${widget.product.description}\n\nOpen in app: $deepLink\n\nOr view online: $webUrl';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share via',
              style: TextStyle(
                color: _accent,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _shareOption(
                  icon: FaIcon(FontAwesomeIcons.whatsapp, size: 28, color: const Color(0xFF25D366)),
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () {
                    final whatsappUrl = 'https://wa.me/?text=${Uri.encodeComponent(shareText)}';
                    _launchUrl(whatsappUrl);
                  },
                ),
                _shareOption(
                  icon: FaIcon(FontAwesomeIcons.facebook, size: 28, color: const Color(0xFF1877F2)),
                  label: 'Facebook',
                  color: const Color(0xFF1877F2),
                  onTap: () {
                    Share.share(shareText, subject: widget.product.name);
                  },
                ),
                _shareOption(
                  icon: FaIcon(FontAwesomeIcons.xTwitter, size: 28, color: const Color(0xFF000000)),
                  label: 'X (Twitter)',
                  color: const Color(0xFF000000),
                  onTap: () {
                    final twitterUrl = 'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(shareText)}';
                    _launchUrl(twitterUrl);
                  },
                ),
                _shareOption(
                  icon: FaIcon(FontAwesomeIcons.instagram, size: 28, color: const Color(0xFFE4405F)),
                  label: 'Instagram',
                  color: const Color(0xFFE4405F),
                  onTap: () {
                    Share.share(shareText, subject: widget.product.name);
                  },
                ),
                _shareOption(
                  icon: FaIcon(FontAwesomeIcons.link, size: 28, color: const Color(0xFF666666)),
                  label: 'Copy Link',
                  color: const Color(0xFF666666),
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: deepLink));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Link copied to clipboard!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _shareOption({
    required Widget icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(child: icon),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: _accent,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // ─────────────────────────────────────────────
  // IMAGE ZONE  (rounded container + badge + gallery)
  // ─────────────────────────────────────────────
  Widget _buildImageZone() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _divider, width: 1),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge Meilleure vente — champagne gold, ink text (skill rule)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: AppTheme.goldGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Best Seller',
                style: TextStyle(
                  color: M.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Image Gallery with PageView — transparent-PNG product shots
            // sit on a raised ivory tile with generous padding.
            Container(
              height: 320,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _divider, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _productImages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final imageUrl = _productImages[index];
                    return imageUrl.startsWith('assets/')
                        ? Image.asset(
                            imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Icon(
                                Icons.watch_rounded,
                                color: _accent,
                                size: 90,
                              ),
                            ),
                          )
                        : CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(
                                color: _accent,
                                strokeWidth: 2,
                              ),
                            ),
                            errorWidget: (context, url, error) => const Center(
                              child: Icon(
                                Icons.watch_rounded,
                                color: _accent,
                                size: 90,
                              ),
                            ),
                            memCacheWidth: 800,
                            memCacheHeight: 800,
                          );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Image indicators (dots)
            if (_productImages.length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_productImages.length, (index) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImageIndex == index
                          ? _gold
                          : _divider,
                    ),
                  );
                }),
              ),
            const SizedBox(height: 12),
            // Thumbnail gallery (show all images as thumbnails)
            if (_productImages.length > 1)
              SizedBox(
                height: 70,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _productImages.length,
                  itemBuilder: (context, index) {
                    final imageUrl = _productImages[index];
                    final isSelected = _currentImageIndex == index;
                    return GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        width: 70,
                        height: 70,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? _gold : _divider,
                            width: 2,
                          ),
                          color: _card,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: imageUrl.startsWith('assets/')
                              ? Image.asset(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.image, color: AppTheme.dim, size: 30),
                                )
                              : CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(
                                      color: _gold,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.image, color: AppTheme.dim, size: 30),
                                  memCacheWidth: 200,
                                  memCacheHeight: 200,
                                ),
                        ),
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

  // ─────────────────────────────────────────────
  // PRODUCT INFO
  // ─────────────────────────────────────────────
  Widget _buildProductInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nom + prix
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      color: _accent,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'by ${widget.product.category}',
                    style: const TextStyle(
                      color: AppTheme.silver,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  PriceText(
                    price: widget.product.price,
                    fontSize: 24,
                    gold: true,
                  ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyService.formatPrice(widget.product.price * 1.2),
                      style: const TextStyle(
                        color: AppTheme.dim,
                        fontSize: 11,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppTheme.dim,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Note + stock
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: _gold, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      widget.product.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: _accent,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${widget.product.reviewCount} Reviews',
                style: const TextStyle(color: AppTheme.silver, fontSize: 12),
              ),
              const Spacer(),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.product.isAvailable
                          ? AppTheme.success
                          : AppTheme.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    widget.product.isAvailable ? 'In Stock' : 'Unavailable',
                    style: TextStyle(
                      color: widget.product.isAvailable
                          ? AppTheme.success
                          : AppTheme.danger,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Cartes stats rapides
          Row(
            children: [
              _statCard('8h', 'Battery'),
              const SizedBox(width: 8),
              _statCard('IPX5', 'Water Resistance'),
              const SizedBox(width: 8),
              _statCard('5.3', 'Bluetooth'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _divider, width: 1),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: _accent,
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.dim,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        color: _divider,
      );

  // ─────────────────────────────────────────────
  // SECTION COULEUR
  // ─────────────────────────────────────────────
  Widget _buildColorSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Color',
                style: TextStyle(
                  color: _accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${widget.product.colors.length} options',
                style: const TextStyle(
                    color: AppTheme.dim, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(widget.product.colors.length, (index) {
              final isSelected = _selectedColorIndex == index;
              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedColorIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 10),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _colorValues[index],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? _gold : _divider,
                      width: 2.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: _gold.withValues(alpha: 0.35),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : [],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            widget.product.colors[_selectedColorIndex],
            style: const TextStyle(
              color: AppTheme.silver,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Size',
                style: TextStyle(
                  color: _accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${widget.product.sizes.length} options',
                style: const TextStyle(
                    color: AppTheme.dim, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(widget.product.sizes.length, (index) {
              final isSelected = _selectedSizeIndex == index;
              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedSizeIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? _accent : _surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? _accent : _divider,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    widget.product.sizes[index],
                    style: TextStyle(
                      color: isSelected ? _bg : AppTheme.silver,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SECTION ONGLETS
  // ─────────────────────────────────────────────
  Widget _buildTabSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Container(
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _divider, width: 1),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: List.generate(_tabs.length, (index) {
                final isSelected = _selectedTabIndex == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _selectedTabIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding:
                          const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _accent
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _tabs[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected
                              ? _bg
                              : AppTheme.silver,
                          fontWeight: isSelected
                              ? FontWeight.w500
                              : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _buildTabContent(),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // CONTENU ONGLETS
  // ─────────────────────────────────────────────
  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            widget.product.description.isNotEmpty
                ? widget.product.description
                : 'Premium smart watch with advanced health tracking, '
                    'GPS, heart rate monitoring, and long battery life. '
                    'Water-resistant design with seamless connectivity '
                    'to all your devices.',
            style: const TextStyle(
              color: AppTheme.silver,
              fontSize: 13,
              height: 1.7,
            ),
          ),
        );
      case 1:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: _specRows.map((spec) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: _gold,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        spec,
                        style: const TextStyle(
                          color: AppTheme.silver,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      case 2:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: _reviewRows.map((review) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: _gold,
                      child: Icon(Icons.person,
                          color: _surface, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(
                              review.stars,
                              (_) => const Icon(Icons.star_rounded,
                                  color: _gold, size: 13),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            review.text,
                            style: const TextStyle(
                              color: AppTheme.silver,
                              fontSize: 12.5,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  static const List<String> _specRows = [
    'Display: Always-on AMOLED',
    'Battery: Up to 14 days',
    'Connectivity: Bluetooth 5.3, GPS',
    'Water Resistance: 5ATM',
    'Sensors: Heart rate, SpO2, ECG',
    'Compatibility: iOS & Android',
  ];

  List<ReviewEntity> get _reviewRows {
    if (widget.product.reviews.isNotEmpty) {
      return widget.product.reviews;
    }
    // Fallback to default reviews if none provided
    return const [
      ReviewEntity(stars: 5, text: 'Excellent health tracking! Really impressed.'),
      ReviewEntity(stars: 4, text: 'Very comfortable, great battery life.'),
      ReviewEntity(stars: 5, text: 'The best smart watch I\'ve ever had. Worth every penny!'),
    ];
  }

  // ─────────────────────────────────────────────
  // BARRE DU BAS
  // ─────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        // Frosted CTA strip — myazz-ui "strong" glass (fill .82, blur 32);
        // product details scroll behind it.
        return AppTheme.glass(
          corners: const BorderRadius.vertical(top: Radius.circular(28)),
          strong: true,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
            children: [
              // Sélecteur de quantité
              Container(
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(32),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bouton moins — cercle gris
                    PressScale(
                      scale: 0.88,
                      onTap: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _quantity > 1 ? _surface : _card,
                          shape: BoxShape.circle,
                          border: Border.all(color: _divider, width: 1),
                        ),
                        child: Icon(
                          Icons.remove,
                          size: 16,
                          color: _quantity > 1
                              ? _accent
                              : AppTheme.dim,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14),
                      child: Text(
                        '$_quantity',
                        style: const TextStyle(
                          color: _accent,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    // Bouton plus — cercle sombre (pill CTA)
                    PressScale(
                      scale: 0.88,
                      onTap: () => setState(() => _quantity++),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: _accent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add,
                            size: 16, color: _bg),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Ajouter au panier — myazz-ui StartButton language: gold
              // gradient ring, dark-navy fill, white label, slow sheen sweep
              // (the ONE sheen on this screen). Flies to header cart.
              Expanded(
                child: GoldCta(
                  key: _addToCartButtonKey,
                  label: widget.product.isAvailable
                      ? 'Add to Cart'
                      : 'Unavailable',
                  height: 50,
                  onTap: widget.product.isAvailable
                      ? () {
                          final selectedColor = widget.product.colors.isNotEmpty
                              ? widget.product.colors[_selectedColorIndex]
                              : null;
                          final selectedSize = widget.product.sizes.isNotEmpty
                              ? widget.product.sizes[_selectedSizeIndex]
                              : null;

                          AddToCartAnimation.run(
                            context: context,
                            vsync: this,
                            sourceKey: _addToCartButtonKey,
                            cartKey: _cartKey,
                            flyColor: _accent,
                            iconColor: _bg,
                            onComplete: () {
                              if (!mounted) return;
                              final added = cart.addToCart(
                                widget.product,
                                _quantity,
                                selectedColor: selectedColor,
                                selectedSize: selectedSize,
                              );
                                if (added) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '$_quantity × ${widget.product.name}${selectedColor != null ? ' ($selectedColor)' : ''}${selectedSize != null ? ' - $selectedSize' : ''} added to cart',
                                      ),
                                      // Semantic success stays muted (gold is
                                      // accent-only in myazz-ui).
                                      backgroundColor: AppTheme.success,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'This product is currently unavailable'),
                                    backgroundColor: AppTheme.danger,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          );
                        }
                      : null,
                ),
              ),
            ],
            ),
          ),
        );
      },
    );
  }
}