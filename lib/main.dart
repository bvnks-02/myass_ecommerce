// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/onboarding/presentation/screens/splash_screen.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';
import 'features/products/presentation/screens/home_screen.dart';
import 'features/products/presentation/screens/watch_detail_screen.dart';
import 'features/cart/presentation/screens/cart_screen.dart';
import 'features/favorites/presentation/screens/favorites_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'providers/cart_provider.dart';
import 'providers/favorites_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/auth_provider.dart';
import 'theme/app_theme.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/screens/forgot_password_screen.dart';
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final productRepository = ProductRepositoryImpl();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(
          create: (_) => ProductsProvider(
            getProductsUseCase: GetProducts(productRepository),
            getFeaturedProductsUseCase: GetFeaturedProducts(productRepository),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'MYASS - Boutique Tech & Musique',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
        routes: {
          '/onboarding': (context) => const OnboardingScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/forgot_password': (context) => const ForgotPasswordScreen(),
          '/home': (context) => const MainScreen(),
          '/admin': (context) => const AdminDashboardScreen(),
          '/cart': (context) => const CartScreen(),
          '/favorites': (context) => const FavoritesScreen(),
          '/profile': (context) => const ProfileScreen(),
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

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const FavoritesScreen(),
    const CartScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // The main screen content
          Positioned.fill(
            child: _screens[_currentIndex],
          ),

          // Floating Bottom Navigation Bar
          Positioned(
            bottom: 25,
            left: 0,
            right: 0,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Container(
                  height: 65,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E).withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(35),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(35),
                    child: BottomNavigationBar(
                      currentIndex: _currentIndex,
                      onTap: (index) async {
                        if (index == 2) {
                          // Watch icon - navigate to watch detail screen
                          if (mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const WatchDetailScreen(),
                              ),
                            );
                          }
                        } else {
                          setState(() {
                            _currentIndex = index;
                          });
                        }
                      },
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      type: BottomNavigationBarType.fixed,
                      selectedItemColor: Colors.white,
                      unselectedItemColor: Colors.grey[600],
                      showSelectedLabels: false,
                      showUnselectedLabels: false,
                      items: [
                        const BottomNavigationBarItem(
                          icon: Icon(Icons.home_outlined, size: 26),
                          activeIcon: Icon(Icons.home, size: 26),
                          label: 'Accueil',
                        ),
                        const BottomNavigationBarItem(
                          icon: Icon(Icons.favorite_outline, size: 26),
                          activeIcon: Icon(Icons.favorite, size: 26),
                          label: 'Favoris',
                        ),
                        BottomNavigationBarItem(
                          icon: Image.asset('assets/icons/watch.png', width: 26, height: 26),
                          activeIcon: Image.asset('assets/icons/watch.png', width: 26, height: 26),
                          label: 'Panier',
                        ),
                        const BottomNavigationBarItem(
                          icon: Icon(Icons.person_outline, size: 26),
                          activeIcon: Icon(Icons.person, size: 26),
                          label: 'Profil',
                        ),
                      ],
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
