// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'features/onboarding/presentation/screens/splash_screen.dart';
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
import 'features/brand/presentation/screens/brand_screen.dart';
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

    // Credentials come only from .env (gitignored asset). No hardcoded secrets.
    final url = dotenv.env['SUPABASE_URL']?.trim() ?? '';
    final anonKey = dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';

    if (url.isEmpty || url.contains('localhost')) {
      throw Exception(
          '❌ CRITICAL: Invalid SUPABASE_URL. Copy .env.example → .env and set SUPABASE_URL.');
    }
    if (anonKey.isEmpty) {
      throw Exception(
          '❌ CRITICAL: SUPABASE_ANON_KEY is empty. Copy .env.example → .env and set the key.');
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
          if (currentRoute == '/login' || currentRoute == '/register') {
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

    // Password-reset tokens arrive with access_token=/code= and are handled above.
    // Product share: myazz://product/{productId}
    if (link.contains('myazz://product/')) {
      final productId = link.split('myazz://product/').last.split('?').first;
      debugPrint('Product ID from deep link: $productId');

      Future.delayed(const Duration(milliseconds: 500), () async {
        final navigator = _navigatorKey.currentState;
        final context = _navigatorKey.currentContext;
        if (navigator == null || context == null) return;

        try {
          final productsProvider = Provider.of<ProductsProvider>(
            context,
            listen: false,
          );

          await productsProvider.fetchProducts();

          ProductEntity? product;
          for (final p in productsProvider.products) {
            if (p.id.toString() == productId) {
              product = p;
              break;
            }
          }

          navigator.pushNamedAndRemoveUntil('/home', (route) => false);

          if (product == null) {
            debugPrint('Deep link product not found: $productId');
            return;
          }

          navigator.pushNamed(
            '/product_details',
            arguments: product,
          );
        } catch (e) {
          debugPrint('Error fetching product from deep link: $e');
          navigator.pushNamedAndRemoveUntil('/home', (route) => false);
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
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/forgot_password': (context) => const ForgotPasswordScreen(),
          '/home': (context) => const MainScreen(),
          '/admin': (context) =>
              const _AdminGate(child: AdminDashboardScreen()),
          '/admin/orders': (context) =>
              const _AdminGate(child: AdminOrdersScreen()),
          '/admin/products': (context) =>
              const _AdminGate(child: AdminProductListScreen()),
          '/admin/messages': (context) =>
              const _AdminGate(child: AdminConversationsScreen()),
          '/chat': (context) => const CustomerChatScreen(),
          '/notifications': (context) => const NotificationsScreen(),
          '/privacy_security': (context) => const PrivacySecurityScreen(),
          '/help_support': (context) => const HelpSupportScreen(),
          '/about': (context) => const AboutScreen(),
          '/cart': (context) => const CartScreen(),
          '/favorites': (context) => const FavoritesScreen(),
          '/support': (context) => const SupportScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/brand': (context) => const BrandScreen(),
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

/// Redirects non-admins away from admin routes (defense-in-depth; RLS still gates data).
class _AdminGate extends StatelessWidget {
  const _AdminGate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (!auth.isAuthenticated || !auth.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
      });
      return const Scaffold(
        backgroundColor: AppTheme.bg,
        body: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      );
    }
    return child;
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Default landing tab = Sport/Store (index 2), the raised center button.
  int _currentIndex = 2;

  // 5 tabs by position: Montre (smartwatch, watch-logo icon), Myazz (brand
  // placeholder, logo icon), Sport (Home/store — raised center button,
  // default landing), Messages (chat, unread badge), Profil.
  // UserOrdersScreen is detached from the nav — still reachable via the
  // '/my_orders' route (Profile → Mes commandes).
  final List<Widget> _screens = [
    const SmartWatchScreen(key: PageStorageKey('smartwatch')),
    const BrandScreen(key: PageStorageKey('brand')),
    const HomeScreen(key: PageStorageKey('home')),
    const CustomerChatScreen(key: PageStorageKey('chat')),
    const ProfileScreen(key: PageStorageKey('profile')),
  ];

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
                      color: isSelected ? AppTheme.accent : AppTheme.dim,
                      size: ResponsiveUtils.sf(context, 26),
                    ),
                    if (badge > 0)
                      Positioned(
                        top: -ResponsiveUtils.sh(context, 6),
                        right: -ResponsiveUtils.sw(context, 8),
                        child: Container(
                          padding: EdgeInsets.all(ResponsiveUtils.sw(context, 4)),
                          decoration: const BoxDecoration(
                            color: AppTheme.danger,
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
                    color: AppTheme.accent,
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

  /// Nav item rendered with a brand asset (watch.png / logo.jpeg) instead of a
  /// Material icon. Assets sit in a small ivory circle tile so non-transparent
  /// images (logo.jpeg) read cleanly on the glass bar. Active: accent ring +
  /// slight scale + full opacity; inactive: hairline ring + dimmed.
  Widget _buildAssetNavItem(
    BuildContext context, {
    required String assetPath,
    required int index,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    final double size = ResponsiveUtils.sw(context, 34);
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: size,
                height: size,
                padding: EdgeInsets.all(ResponsiveUtils.sw(context, 4)),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppTheme.accent : AppTheme.line,
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.accent.withValues(alpha: 0.25),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: ClipOval(
                  child: AnimatedOpacity(
                    opacity: isSelected ? 1.0 : 0.55,
                    duration: const Duration(milliseconds: 300),
                    child: Image.asset(assetPath, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
            if (isSelected) ...[
              SizedBox(height: ResponsiveUtils.sh(context, 4)),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: ResponsiveUtils.sw(context, 5),
                height: ResponsiveUtils.sh(context, 5),
                decoration: const BoxDecoration(
                  color: AppTheme.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
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

          // Floating frosted-glass Bottom Navigation Bar
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
                    // Frosted-glass floating navigation bar — content
                    // scrolls behind it, so the blur reads as real glass.
                    // Top padding reserves room for the raised center button
                    // so its full tap target stays inside the Stack bounds.
                    Padding(
                      padding: EdgeInsets.only(
                          top: ResponsiveUtils.sh(context, 16)),
                      child: Container(
                        height: ResponsiveUtils.sh(context, 70),
                        margin: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtils.sw(context, 20)),
                        child: AppTheme.glass(
                          radius: 24,
                          sigma: 16,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveUtils.sw(context, 10)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                // Montre (smartwatch) — watch-logo asset tab
                                _buildAssetNavItem(
                                  context,
                                  assetPath: 'assets/icons/watch.png',
                                  index: 0,
                                  label: 'Montre',
                                ),
                                // Myazz (brand) — logo asset tab
                                _buildAssetNavItem(
                                  context,
                                  assetPath: 'assets/images/logo.jpeg',
                                  index: 1,
                                  label: 'Myazz',
                                ),
                                // Sport (store) — slot reserved for the
                                // raised center button painted on top.
                                SizedBox(width: ResponsiveUtils.sw(context, 60)),
                                // Messagerie (chat) with unread badge. Selector
                                // keeps chat updates from rebuilding the whole
                                // MainScreen (same pattern as the cart badge).
                                Selector<ChatProvider, int>(
                                  selector: (_, chat) => chat.unreadCount,
                                  builder: (context, unread, _) =>
                                      _buildNavItem(
                                    context,
                                    icon: Icons.forum_outlined,
                                    activeIcon: Icons.forum,
                                    index: 3,
                                    label: 'Messages',
                                    badge: unread,
                                  ),
                                ),
                                // Profile
                                _buildNavItem(
                                  context,
                                  icon: Icons.person_outline,
                                  activeIcon: Icons.person,
                                  index: 4,
                                  label: 'Profil',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Raised center "Sport" tab (store) — floats above the
                    // glass bar like the old raised-cart pattern: accent gold
                    // filled circle, ivory icon, hairline ring + soft shadow.
                    Positioned(
                      top: 0,
                      child: GestureDetector(
                        onTap: () => _onItemTapped(2),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedScale(
                          scale: _currentIndex == 2 ? 1.06 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: Container(
                            width: ResponsiveUtils.sw(context, 60),
                            height: ResponsiveUtils.sw(context, 60),
                            decoration: BoxDecoration(
                              color: AppTheme.accent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _currentIndex == 2
                                    ? AppTheme.surface
                                    : AppTheme.surface.withValues(alpha: 0.7),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.fg.withValues(alpha: 0.18),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                                if (_currentIndex == 2)
                                  BoxShadow(
                                    color:
                                        AppTheme.accent.withValues(alpha: 0.35),
                                    blurRadius: 4,
                                    spreadRadius: 2,
                                  ),
                              ],
                            ),
                            child: Icon(
                              Icons.sports,
                              color: AppTheme.bg,
                              size: ResponsiveUtils.sf(context, 28),
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
