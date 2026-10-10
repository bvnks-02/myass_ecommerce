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
import 'features/health/presentation/screens/health_screen.dart';
import 'core/widgets/liquid_nav_bar.dart';
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
        // Pearl gradient root background (myazz-ui): ONE gradient container
        // behind the whole app; scaffolds are transparent so glass reads.
        builder: (context, child) => DecoratedBox(
          decoration: const BoxDecoration(gradient: AppTheme.pearlGradient),
          child: child ?? const SizedBox.shrink(),
        ),
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
          '/health': (context) => const HealthScreen(),
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
  // Default landing tab = Home/store (index 0).
  int _currentIndex = 0;

  // 5 tabs by position (luxury liquid-glass navbar, left→right):
  // Home (store) · Health (placeholder) · Sports (center gold coin →
  // SmartWatchScreen, the watch's sport experience) · Messages (chat,
  // unread badge) · Profile.
  // BrandScreen and UserOrdersScreen are detached from the nav — still
  // reachable via '/brand' and '/my_orders' (Profile → Mes commandes).
  final List<Widget> _screens = [
    const HomeScreen(key: PageStorageKey('home')),
    const HealthScreen(key: PageStorageKey('health')),
    const SmartWatchScreen(key: PageStorageKey('smartwatch')),
    const CustomerChatScreen(key: PageStorageKey('chat')),
    const ProfileScreen(key: PageStorageKey('profile')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // The main screen content — conditional rendering (no IndexedStack).
          Positioned.fill(
            child: _screens[_currentIndex],
          ),

          // Floating luxury liquid-glass navbar (port of the myazz-ui
          // reference — lib/core/widgets/liquid_nav_bar.dart).
          Positioned(
            bottom: ResponsiveUtils.sh(context, 35),
            left: 0,
            right: 0,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.sw(context, 20)),
                  // Selector keeps chat notifications from rebuilding the
                  // whole MainScreen; tab switches rebuild through the
                  // parent (Selector invalidates when its widget changes).
                  child: Selector<ChatProvider, int>(
                    selector: (_, chat) => chat.unreadCount,
                    builder: (context, unread, _) => LuxuryGlassNavbar(
                      currentIndex: _currentIndex,
                      onTap: (index) =>
                          setState(() => _currentIndex = index),
                      badges: {3: unread},
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
