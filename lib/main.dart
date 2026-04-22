// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/onboarding/presentation/screens/splash_screen.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';
import 'features/products/presentation/screens/home_screen.dart';
import 'features/products/presentation/screens/product_details_screen.dart';
import 'features/products/presentation/screens/watch_detail_screen.dart';
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
import 'features/support/presentation/screens/support_screen.dart';
import 'features/support/presentation/providers/support_provider.dart';
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
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _handlePasswordReset();
  }

  void _handlePasswordReset() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null && data.event == AuthChangeEvent.passwordRecovery) {
        // User clicked password reset link, navigate to reset password screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context, rootNavigator: true)
              .pushNamedAndRemoveUntil('/reset_password', (route) => false);
        });
      }
    });
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
        ChangeNotifierProvider(
          create: (_) => ProductsProvider(
            getProductsUseCase: GetProducts(productRepository),
            getFeaturedProductsUseCase: GetFeaturedProducts(productRepository),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Myazz',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
        initialRoute: '/',
        onGenerateRoute: (settings) {
          // Handle web hash routing for password reset
          if (settings.name == '/reset_password' || 
              settings.name?.contains('reset_password') == true) {
            return MaterialPageRoute(
              builder: (context) => const ResetPasswordScreen(),
            );
          }
          return null;
        },
        routes: {
          '/onboarding': (context) => const OnboardingScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/forgot_password': (context) => const ForgotPasswordScreen(),
          '/reset_password': (context) => const ResetPasswordScreen(),
          '/home': (context) => const MainScreen(),
          '/admin': (context) => const AdminDashboardScreen(),
          '/admin/orders': (context) => const AdminOrdersScreen(),
          '/admin/products': (context) => const AdminProductListScreen(),
          '/notifications': (context) => const NotificationsScreen(),
          '/privacy_security': (context) => const PrivacySecurityScreen(),
          '/help_support': (context) => const HelpSupportScreen(),
          '/about': (context) => const AboutScreen(),
          '/cart': (context) => const CartScreen(),
          '/favorites': (context) => const FavoritesScreen(),
          '/support': (context) => const SupportScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/product_details': (context) {
            final product = ModalRoute.of(context)?.settings.arguments as ProductEntity?;
            if (product == null) return const SizedBox.shrink();
            return ProductDetailsScreen(product: product);
          },
          '/watch_details': (context) => const WatchDetailScreen(),
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

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final List<Widget> _screens = [
    const HomeScreen(key: PageStorageKey('home')),
    const FavoritesScreen(key: PageStorageKey('favorites')),
    const WatchDetailScreen(key: PageStorageKey('watch')),
    const ProfileScreen(key: PageStorageKey('profile')),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildNavItem(
    BuildContext context,
    {
    required IconData icon,
    required IconData activeIcon,
    required int index,
    required String label,
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
                child: Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? Colors.white : Colors.grey[600],
                  size: ResponsiveUtils.sf(context, 26),
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
          // The main screen content
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
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
                      margin: EdgeInsets.symmetric(horizontal: ResponsiveUtils.sw(context, 20)),
                      child: CustomPaint(
                        painter: CurvedBottomBarPainter(),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.sw(context, 10)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              // Home
                              _buildNavItem(
                                context,
                                icon: Icons.home_outlined,
                                activeIcon: Icons.home,
                                index: 0,
                                label: 'Accueil',
                              ),
                              // Favorites
                              _buildNavItem(
                                context,
                                icon: Icons.favorite_outline,
                                activeIcon: Icons.favorite,
                                index: 1,
                                label: 'Favoris',
                              ),
                              // Spacer for elevated cart button
                              SizedBox(width: ResponsiveUtils.sw(context, 70)),
                              // Saved
                              _buildNavItem(
                                context,
                                icon: Icons.watch_outlined,
                                activeIcon: Icons.watch,
                                index: 2,
                                label: 'Watch',
                              ),
                              // Profile
                              _buildNavItem(
                                context,
                                icon: Icons.person_outline,
                                activeIcon: Icons.person,
                                index: 3,
                                label: 'Profil',
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
                            _animationController.forward().then((_) {
                              _animationController.reverse();
                            });
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
                                      if (itemCount == 0) {
                                        return const SizedBox.shrink();
                                      }
                                      return Container(
                                        padding: EdgeInsets.all(ResponsiveUtils.sw(context, 6)),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Colors.red, Colors.redAccent],
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.red.withValues(alpha: 0.5),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          '$itemCount',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: ResponsiveUtils.sf(context, 12),
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
      ..color = const Color(0xFF1C1C1E).withValues(alpha: 0.95)
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
      size.width * 0.40, 0,
      size.width * 0.42, 5,
    );
    path.quadraticBezierTo(
      size.width * 0.45, 15,
      size.width * 0.50, 15,
    );
    path.quadraticBezierTo(
      size.width * 0.55, 15,
      size.width * 0.58, 5,
    );
    path.quadraticBezierTo(
      size.width * 0.60, 0,
      size.width * 0.65, 0,
    );
    
    // Right side
    path.lineTo(size.width - 20, 0);
    
    // Top right corner curve
    path.quadraticBezierTo(size.width, 0, size.width, 20);
    
    // Bottom right corner
    path.lineTo(size.width, size.height - 20);
    path.quadraticBezierTo(
      size.width, size.height,
      size.width - 20, size.height,
    );
    
    // Bottom side
    path.lineTo(20, size.height);
    
    // Bottom left corner
    path.quadraticBezierTo(0, size.height, 0, size.height - 20);
    
    path.close();

    // Draw shadow
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.5), 15, true);
    
    // Draw the bar
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