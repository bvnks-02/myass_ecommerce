// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'features/onboarding/presentation/screens/splash_screen.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';
import 'features/products/presentation/screens/home_screen.dart';
import 'features/products/presentation/screens/product_details_screen.dart';
import 'features/products/presentation/screens/watch_detail_screen.dart';
import 'features/orders/presentation/screens/user_orders_screen.dart';
import 'features/products/domain/entities/product_entity.dart';
import 'features/cart/presentation/screens/cart_screen.dart';
import 'features/favorites/presentation/screens/favorites_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/profile/presentation/screens/notifications_screen.dart';
import 'features/profile/presentation/screens/privacy_security_screen.dart';
import 'features/profile/presentation/screens/help_support_screen.dart';
import 'features/profile/presentation/screens/about_screen.dart';
import 'features/admin/presentation/screens/admin_orders_screen.dart';
import 'features/admin/presentation/screens/admin_product_list_screen.dart';
import 'features/admin/presentation/screens/admin_conversations_screen.dart';
import 'features/support/presentation/screens/support_screen.dart';
import 'features/support/presentation/providers/support_provider.dart';
import 'features/chat/presentation/providers/chat_provider.dart';
import 'features/chat/presentation/screens/customer_chat_screen.dart';
import 'features/smartwatch/presentation/providers/smartwatch_provider.dart';
import 'features/smartwatch/presentation/screens/smartwatch_screen.dart';
import 'features/smartwatch/presentation/screens/watch_pairing_screen.dart';
import 'features/smartwatch/presentation/screens/watch_faces_screen.dart';
import 'providers/cart_provider.dart';
import 'providers/favorites_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/auth_provider.dart';
import 'theme/app_theme.dart';
import 'core/utils/responsive_utils.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/screens/forgot_password_screen.dart';
import 'features/auth/presentation/screens/reset_password_screen.dart';
import 'features/products/presentation/providers/products_provider.dart';
import 'features/products/data/repositories/product_repository_impl.dart';
import 'features/products/domain/usecases/get_products.dart';
import 'features/products/domain/usecases/get_featured_products.dart';
import 'features/admin/presentation/screens/admin_dashboard_screen.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('Flutter Error: ${details.exception}');
      debugPrint('Stack: ${details.stack}');
    };

    // Load environment variables with error handling
    try {
      await dotenv.load(fileName: ".env");
      debugPrint('✓ .env file loaded successfully');
    } catch (e) {
      debugPrint(
          '⚠️  Failed to load .env file: $e - Using fallback credentials');
    }

    // Validate env vars and use hardcoded fallback if .env failed
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    final url = (supabaseUrl != null && supabaseUrl.isNotEmpty)
        ? supabaseUrl
        : 'https://ifosyvmoynhglyxcitvw.supabase.co';
    final anonKey = (supabaseAnonKey != null && supabaseAnonKey.isNotEmpty)
        ? supabaseAnonKey
        : 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imlmb3N5dm1veW5oZ2x5eGNpdHZ3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQwMzkwNTMsImV4cCI6MjA5OTYxNTA1M30.8zY8hFVZCqi2nq-nVx_ienLXDTH4wdeaA86AjtfSRUE';

    // Verify URLs are not empty or localhost
    if (url.isEmpty || url.contains('localhost')) {
      throw Exception(
          '❌ CRITICAL: Invalid SUPABASE_URL: $url. Check your .env file.');
    }
    if (anonKey.isEmpty) {
      throw Exception(
          '❌ CRITICAL: SUPABASE_ANON_KEY is empty. Check your .env file.');
    }

    // Initialize Supabase with error handling
    try {
      debugPrint('🔄 Initializing Supabase...');
      await Supabase.initialize(url: url, anonKey: anonKey);
      debugPrint('✓ Supabase initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ CRITICAL: Supabase initialization failed!');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow; // Rethrow to ensure the error is visible and handled
    }

    runApp(const MyApp());
  }, (error, stackTrace) {
    debugPrint('❌ UNCAUGHT ERROR: $error');
    debugPrint('Stack trace: $stackTrace');
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<String>? _appLinksSubscription;
  bool _isFirstAuthEvent = true;
  final AppLinks _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _handleAuthStateChanges();
    _handleDeepLinks();
  }

  void _handleAuthStateChanges() {
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      // Skip only the initial session restoration on app startup.
      // Do NOT skip a fresh signedIn event (e.g. OAuth cold-start).
      if (_isFirstAuthEvent) {
        _isFirstAuthEvent = false;
        if (data.event == AuthChangeEvent.initialSession) {
          return;
        }
      }

      final session = data.session;

      // Handle OAuth sign-in: navigate away from auth screens when login completes
      if (session != null && data.event == AuthChangeEvent.signedIn) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final navigator = _navigatorKey.currentState;
          if (navigator == null) return;

          final authProvider =
              Provider.of<AuthProvider>(navigator.context, listen: false);
          await authProvider.refreshRole();

          final targetRoute = authProvider.isAdmin ? '/admin' : '/home';
          // Only navigate if currently on an auth screen
          final currentRoute = ModalRoute.of(navigator.context)?.settings.name;
          if (currentRoute == '/login' ||
              currentRoute == '/register' ||
              currentRoute == '/onboarding') {
            navigator.pushReplacementNamed(targetRoute);
          }
        });
      }

      if (session != null && data.event == AuthChangeEvent.passwordRecovery) {
        // User clicked password reset link, navigate to reset password screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _navigatorKey.currentState
              ?.pushNamedAndRemoveUntil('/reset_password', (route) => false);
        });
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _appLinksSubscription?.cancel();
    super.dispose();
  }

  void _handleDeepLinks() async {
    // Handle deep links when app is already running
    _appLinksSubscription = _appLinks.stringLinkStream.listen((String link) {
      _processDeepLink(link);
    });

    // Handle deep link when app is opened from cold start
    final initialLink = await _appLinks.getInitialLinkString();
    if (initialLink != null) {
      _processDeepLink(initialLink);
    }
  }

  Future<void> _handleOAuthCallback(String link) async {
    try {
      await Supabase.instance.client.auth.getSessionFromUrl(Uri.parse(link));
      debugPrint('OAuth session established successfully from deep link');
    } catch (e, stackTrace) {
      debugPrint('Error processing OAuth deep link: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  void _processDeepLink(String link) {
    debugPrint('Received deep link: $link');

    // Handle OAuth/auth callback links so Supabase can complete sign-in
    if (link.contains('login-callback') ||
        link.contains('access_token=') ||
        link.contains('code=')) {
      debugPrint('OAuth callback detected, forwarding to Supabase auth...');
      _handleOAuthCallback(link);
      return;
    }

    // Handle password reset deep links
    if (link.contains('reset_password')) {
      debugPrint('Password reset deep link detected');
      return;
    }

    // Parse the deep link: myazz://product/{productId}
    if (link.contains('myazz://product/')) {
      final productId = link.split('myazz://product/').last;
      debugPrint('Product ID from deep link: $productId');
      
      // Navigate to product details after a short delay to ensure app is ready
      Future.delayed(const Duration(milliseconds: 500), () async {
        if (_navigatorKey.currentState != null) {
          try {
            // Fetch the product from the provider
            final productsProvider = Provider.of<ProductsProvider>(
              _navigatorKey.currentContext!,
              listen: false,
            );
            
            await productsProvider.fetchProducts();
            
            // Find the product by ID
            final product = productsProvider.products.firstWhere(
              (p) => p.id.toString() == productId,
              orElse: () => productsProvider.products.first,
            );
            
            // Navigate to product details
            _navigatorKey.currentState?.pushNamedAndRemoveUntil(
              '/home',
              (route) => false,
            );
            
            // Then navigate to product details
            _navigatorKey.currentState?.pushNamed(
              '/product_details',
              arguments: product,
            );
          } catch (e) {
            debugPrint('Error fetching product from deep link: $e');
            // Fallback to home screen
            _navigatorKey.currentState?.pushNamedAndRemoveUntil(
              '/home',
              (route) => false,
            );
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final productRepository = ProductRepositoryImpl();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => SupportProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => SmartWatchProvider()),
        ChangeNotifierProvider(
          create: (_) => ProductsProvider(
            getProductsUseCase: GetProducts(productRepository),
            getFeaturedProductsUseCase: GetFeaturedProducts(productRepository),
          ),
        ),
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'Myazz',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
        onGenerateRoute: (settings) {
          // Handle web hash routing for password reset
          if (settings.name == '/reset_password' ||
              settings.name?.contains('reset_password') == true) {
            return MaterialPageRoute(
              builder: (context) => const ResetPasswordScreen(),
              settings: settings,
            );
          }
          return null;
        },
        routes: {
          '/onboarding': (context) => const OnboardingScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/forgot_password': (context) => const ForgotPasswordScreen(),
          '/home': (context) => const MainScreen(),
          '/admin': (context) => const AdminDashboardScreen(),
          '/admin/orders': (context) => const AdminOrdersScreen(),
          '/admin/products': (context) => const AdminProductListScreen(),
          '/admin/messages': (context) => const AdminConversationsScreen(),
          '/chat': (context) => const CustomerChatScreen(),
          '/notifications': (context) => const NotificationsScreen(),
          '/privacy_security': (context) => const PrivacySecurityScreen(),
          '/help_support': (context) => const HelpSupportScreen(),
          '/about': (context) => const AboutScreen(),
          '/cart': (context) => const CartScreen(),
          '/favorites': (context) => const FavoritesScreen(),
          '/support': (context) => const SupportScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/product_details': (context) {
            final product =
                ModalRoute.of(context)?.settings.arguments as ProductEntity?;
            if (product == null) return const SizedBox.shrink();
            return ProductDetailsScreen(product: product);
          },
          '/my_orders': (context) => const UserOrdersScreen(),
          '/watch_details': (context) => const WatchDetailScreen(),
          '/smartwatch': (context) => const SmartWatchScreen(),
          '/watch_pairing': (context) => const WatchPairingScreen(),
          '/watch_faces': (context) => const WatchFacesScreen(),
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  // Default landing tab = Store (index 2), the natural home for the shop.
  int _currentIndex = 2;
  int _prevCartCount = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // 5 tabs (CDC order): Profile, Messagerie (chat), Store (Home — unchanged
  // logic), Ma Section (orders), Smart Watch. The floating cart button stays
  // separate and is not one of these tabs.
  final List<Widget> _screens = [
    const ProfileScreen(key: PageStorageKey('profile')),
    const CustomerChatScreen(key: PageStorageKey('chat')),
    const HomeScreen(key: PageStorageKey('home')),
    const UserOrdersScreen(key: PageStorageKey('orders')),
    const SmartWatchScreen(key: PageStorageKey('smartwatch')),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.28).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Bump the floating cart button (used on tap and when an item is added).
  void _playCartBump() {
    _animationController.forward(from: 0).then((_) {
      if (mounted) _animationController.reverse();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required int index,
    required String label,
    int badge = 0,
  }) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      isSelected ? activeIcon : icon,
                      color: isSelected ? Colors.white : Colors.grey[600],
                      size: ResponsiveUtils.sf(context, 26),
                    ),
                    if (badge > 0)
                      Positioned(
                        top: -ResponsiveUtils.sh(context, 6),
                        right: -ResponsiveUtils.sw(context, 8),
                        child: Container(
                          padding: EdgeInsets.all(ResponsiveUtils.sw(context, 4)),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: BoxConstraints(
                            minWidth: ResponsiveUtils.sw(context, 16),
                            minHeight: ResponsiveUtils.sw(context, 16),
                          ),
                          child: Text(
                            badge > 9 ? '9+' : '$badge',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: ResponsiveUtils.sf(context, 9),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (isSelected) ...[
                SizedBox(height: ResponsiveUtils.sh(context, 4)),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: ResponsiveUtils.sw(context, 5),
                  height: ResponsiveUtils.sh(context, 5),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // The main screen content - use conditional rendering instead of IndexedStack
          Positioned.fill(
            child: _screens[_currentIndex],
          ),

          // Floating Bottom Navigation Bar with curved design
          Positioned(
            bottom: ResponsiveUtils.sh(context, 35),
            left: 0,
            right: 0,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Navigation bar container with custom curve
                    Container(
                      height: ResponsiveUtils.sh(context, 70),
                      margin: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.sw(context, 20)),
                      child: CustomPaint(
                        painter: CurvedBottomBarPainter(),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveUtils.sw(context, 10)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              // Profile
                              _buildNavItem(
                                context,
                                icon: Icons.person_outline,
                                activeIcon: Icons.person,
                                index: 0,
                                label: 'Profil',
                              ),
                              // Messagerie (chat) with unread badge
                              _buildNavItem(
                                context,
                                icon: Icons.forum_outlined,
                                activeIcon: Icons.forum,
                                index: 1,
                                label: 'Messages',
                                badge: context
                                    .watch<ChatProvider>()
                                    .unreadCount,
                              ),
                              // Store (Home) — sits under the floating cart button
                              _buildNavItem(
                                context,
                                icon: Icons.storefront_outlined,
                                activeIcon: Icons.storefront,
                                index: 2,
                                label: 'Store',
                              ),
                              // Ma Section (orders)
                              _buildNavItem(
                                context,
                                icon: Icons.receipt_long_outlined,
                                activeIcon: Icons.receipt_long,
                                index: 3,
                                label: 'Commandes',
                              ),
                              // Smart Watch
                              _buildNavItem(
                                context,
                                icon: Icons.watch_outlined,
                                activeIcon: Icons.watch,
                                index: 4,
                                label: 'Montre',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Elevated cart button in center (always on top)
                    Positioned(
                      top: -ResponsiveUtils.sh(context, 35),
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: GestureDetector(
                          onTap: () {
                            _playCartBump();
                            Navigator.pushNamed(context, '/cart');
                          },
                          child: Container(
                            width: ResponsiveUtils.sw(context, 70),
                            height: ResponsiveUtils.sh(context, 70),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF2C2C2E),
                                  Color(0xFF1C1C1E),
                                ],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  blurRadius: 25,
                                  offset: const Offset(0, 10),
                                ),
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  blurRadius: 15,
                                  offset: const Offset(0, -5),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_cart,
                                  color: Colors.white,
                                  size: ResponsiveUtils.sf(context, 32),
                                ),
                                // Cart badge
                                Positioned(
                                  top: ResponsiveUtils.sh(context, 8),
                                  right: ResponsiveUtils.sw(context, 8),
                                  child: Selector<CartProvider, int>(
                                    selector: (context, cart) => cart.itemCount,
                                    builder: (context, itemCount, child) {
                                      // Confirmation bump whenever the cart count
                                      // grows (i.e. CartProvider added an item).
                                      if (itemCount > _prevCartCount) {
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                          if (mounted) _playCartBump();
                                        });
                                      }
                                      _prevCartCount = itemCount;
                                      if (itemCount == 0) {
                                        return const SizedBox.shrink();
                                      }
                                      return Container(
                                        padding: EdgeInsets.all(
                                            ResponsiveUtils.sw(context, 6)),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Colors.red,
                                              Colors.redAccent
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.red
                                                  .withValues(alpha: 0.5),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          '$itemCount',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize:
                                                ResponsiveUtils.sf(context, 12),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for curved bottom navigation bar
class CurvedBottomBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1C1C1E).withValues(alpha: 0.80)
      ..style = PaintingStyle.fill;

    final path = Path();

    // Start from bottom left
    path.moveTo(0, 20);

    // Top left corner curve
    path.quadraticBezierTo(0, 0, 20, 0);

    // Left side to the center curve
    path.lineTo(size.width * 0.35, 0);

    // Create the elevated curve for the cart button
    path.quadraticBezierTo(
      size.width * 0.40,
      0,
      size.width * 0.42,
      5,
    );
    path.quadraticBezierTo(
      size.width * 0.45,
      15,
      size.width * 0.50,
      15,
    );
    path.quadraticBezierTo(
      size.width * 0.55,
      15,
      size.width * 0.58,
      5,
    );
    path.quadraticBezierTo(
      size.width * 0.60,
      0,
      size.width * 0.65,
      0,
    );

    // Right side
    path.lineTo(size.width - 20, 0);

    // Top right corner curve
    path.quadraticBezierTo(size.width, 0, size.width, 20);

    // Bottom right corner
    path.lineTo(size.width, size.height - 20);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width - 20,
      size.height,
    );

    // Bottom side
    path.lineTo(20, size.height);

    // Bottom left corner
    path.quadraticBezierTo(0, size.height, 0, size.height - 20);

    path.close();

    // Draw the bar (removed shadow for performance)
    canvas.drawPath(path, paint);

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
