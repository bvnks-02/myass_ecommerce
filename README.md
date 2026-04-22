<div align="center">

# MYASS E-Commerce Mobile App

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-lightgrey?style=for-the-badge)](https://flutter.dev/multi-platform)

**A premium e-commerce mobile application for MYASS Smart Watches store**

Built with Flutter and Supabase, featuring a modern dark luxe design and comprehensive security measures.

[Features](#-features) • [Installation](#-installation) • [Architecture](#-architecture) • [Security](#-security) • [Contributing](#-contributing)

</div>

---

## 📱 Features

### User Experience
- **🎨 Dark Luxe Theme** - Premium dark design with purple accents and glassmorphic UI elements
- **🔍 Advanced Search** - Real-time product search with sanitization
- **📂 Category Filtering** - Filter by Sport, Luxury, Fitness, Classic, and New arrivals
- **❌ Favorites System** - Save and manage favorite products
- **🛒 Shopping Cart** - Full cart management with quantity controls
- **👤 User Profile** - Account management and order history
- **📦 Order Tracking** - Complete order lifecycle management
- **💬 Customer Support** - Integrated support system with FAQ and contact form

### Authentication
- **📧 Email/Password** - Secure authentication with email verification
- **🔐 OAuth Providers** - Google and Facebook social login
- **🔑 Password Reset** - Secure password recovery flow
- **👑 Role-Based Access** - Customer and Admin roles with granular permissions

### Admin Dashboard
- **📊 Analytics Overview** - Dashboard with key metrics
- **📦 Product Management** - Create, update, and delete products
- **📋 Order Management** - View and manage customer orders
- **👥 User Management** - Monitor and manage user accounts

---

## 🏗️ Architecture

### Tech Stack

#### Frontend
```
Flutter 3.0+
├── UI Framework
├── Provider (State Management)
├── Supabase Flutter SDK
├── Cached Network Images
├── Carousel Slider
├── Shimmer (Loading States)
└── Lottie Animations
```

#### Backend
```
Supabase
├── PostgreSQL Database
├── Authentication Service
├── Row Level Security (RLS)
├── Real-time Subscriptions
├── Storage Service
└── Edge Functions
```

### Project Structure

```
myass_ecommerce/
├── lib/
│   ├── main.dart                          # App entry point
│   ├── core/
│   │   ├── security/                      # Security utilities
│   │   │   ├── input_sanitizer.dart
│   │   │   ├── input_validator.dart
│   │   │   └── rate_limiter.dart
│   │   ├── services/                      # Core services
│   │   ├── utils/                         # Utility functions
│   │   └── error/                        # Error handling
│   ├── features/
│   │   ├── auth/                          # Authentication flow
│   │   │   ├── presentation/
│   │   │   ├── domain/
│   │   │   └── data/
│   │   ├── products/                      # Product management
│   │   ├── cart/                          # Shopping cart
│   │   ├── favorites/                     # Favorites system
│   │   ├── profile/                       # User profile
│   │   ├── admin/                         # Admin dashboard
│   │   ├── support/                       # Customer support
│   │   └── onboarding/                    # Onboarding flow
│   ├── providers/                         # State management
│   ├── theme/                            # App theming
│   └── services/                         # External services
├── assets/
│   ├── images/                           # App images
│   ├── icons/                            # Custom icons
│   └── lottie/                           # Lottie animations
├── android/                             # Android configuration
├── web/                                 # Web configuration
├── supabase_schema.sql                  # Database schema
├── .env.example                         # Environment template
├── .gitignore                           # Git ignore rules
├── pubspec.yaml                         # Dependencies
└── SECURITY_IMPLEMENTATION.md           # Security documentation
```

### Database Schema

| Table | Description | Key Features |
|-------|-------------|--------------|
| `user_profiles` | User accounts with roles | RLS enabled, role-based access |
| `products` | Product catalog | Categories, pricing, featured flags |
| `orders` | Order management | Status tracking, timestamps |
| `order_items` | Order line items | Price snapshot, quantity |

---

## 🚀 Installation

### Prerequisites

- **Flutter SDK** 3.0 or higher
- **Dart SDK** 3.0 or higher
- **Supabase Account** (Free tier available)
- **Android Studio** / **VS Code** with Flutter extension
- **Git**

### Quick Start

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/myass_ecommerce.git
cd myass_ecommerce
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure environment variables**
```bash
cp .env.example .env
```

Edit `.env` with your Supabase credentials:
```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

4. **Set up Supabase**
- Create a new project at [supabase.com](https://supabase.com)
- Run `supabase_schema.sql` in the SQL Editor
- Create a storage bucket named `product-images`
- Configure RLS policies

5. **Run the app**
```bash
flutter run
```

### Platform-Specific Setup

#### iOS
```bash
cd ios
pod install
cd ..
flutter run
```

#### Android
Ensure `minSdkVersion` is set to 21 or higher in `android/app/build.gradle`

#### Web
```bash
flutter run -d chrome
```

---

## 🔒 Security

This application implements comprehensive OWASP-compliant security measures:

### Input Sanitization
- ✅ All user inputs sanitized (XSS prevention)
- ✅ HTML tag removal
- ✅ Script pattern detection
- ✅ SQL injection pattern removal
- ✅ URL sanitization (open redirect prevention)

### Input Validation
- ✅ RFC 5322 compliant email validation
- ✅ Strong password requirements (8+ chars, mixed case, numbers, symbols)
- ✅ Length limits on all inputs
- ✅ Character restrictions
- ✅ Dangerous pattern detection

### Rate Limiting
| Endpoint | Limit | Window |
|----------|-------|--------|
| Authentication | 5 requests | 15 minutes |
| Password Reset | 3 requests | 1 hour |
| Search | 30 requests | 1 minute |
| Contact Form | 5 submissions | 1 hour |
| General API | 100 requests | 1 minute |
| Cart Operations | 50 requests | 1 minute |

### Data Protection
- ✅ Row Level Security (RLS) on all tables
- ✅ Parameterized queries (SQL injection prevention)
- ✅ Environment variables for secrets
- ✅ `.env` excluded from version control
- ✅ Role-based access control

### Security Utilities
- `lib/core/security/input_sanitizer.dart` - Sanitization functions
- `lib/core/security/input_validator.dart` - Validation functions
- `lib/core/security/rate_limiter.dart` - Rate limiting implementation

📖 **Detailed security documentation**: See [SECURITY_IMPLEMENTATION.md](SECURITY_IMPLEMENTATION.md)

---

## 🎨 Theme Configuration

### Color Palette
```dart
Primary:      #9B59B6 (Purple Gradient)
Secondary:    #8E44AD
Background:   #000000 (Black)
Card:         #1E1E1E / #2C2C2E
Text:         #FFFFFF (White)
Accent:       #E74C3C (Red for cart)
```

### Typography
- **Font Family**: Inter (default)
- **Headings**: Bold, 24-32px
- **Body**: Regular, 14-16px
- **Captions**: Light, 12px

---

## 📊 Development

### Adding New Features

1. **Create feature structure**
```bash
lib/features/your_feature/
├── presentation/
│   ├── screens/
│   └── widgets/
├── domain/
│   ├── entities/
│   └── usecases/
└── data/
    ├── models/
    └── repositories/
```

2. **Add state management** (if needed)
```dart
// lib/providers/your_provider.dart
class YourProvider extends ChangeNotifier {
  // Implementation
}
```

3. **Update navigation** in `main.dart`
```dart
routes: {
  '/your_route': (context) => YourScreen(),
}
```

### Setting Admin Role

```sql
UPDATE public.user_profiles 
SET role = 'admin' 
WHERE email = 'admin@example.com';
```

### Running Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/auth_test.dart
```

---

## 📦 Production Deployment

### Android

```bash
# Build APK
flutter build apk --release

# Build App Bundle (Play Store)
flutter build appbundle --release
```

### iOS

```bash
# Build IPA
flutter build ios --release
```

### Web

```bash
# Build web app
flutter build web --release
```

### Supabase Production Checklist

- [ ] Enable production RLS policies
- [ ] Configure authentication providers
- [ ] Set up storage bucket policies
- [ ] Enable database backups
- [ ] Configure custom domain
- [ ] Set up monitoring and alerts
- [ ] Review API rate limits
- [ ] Enable audit logging

---

## 🤝 Contributing

We welcome contributions! Please follow these guidelines:

### Development Workflow

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style

- Follow Dart effective Dart guidelines
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions small and focused
- Write tests for new features

### Commit Messages

```
feat: add user profile screen
fix: resolve cart calculation bug
docs: update README with security info
refactor: improve auth provider structure
test: add unit tests for sanitization
```

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📞 Support

- 📧 Email: support@myazz.com
- 🐛 Issues: [GitHub Issues](https://github.com/yourusername/myass_ecommerce/issues)
- 📖 Documentation: [SECURITY_IMPLEMENTATION.md](SECURITY_IMPLEMENTATION.md)

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Supabase for the excellent backend-as-a-service
- Open source community for various packages

---

<div align="center">

**Built with ❤️ by MYASS Team**

[⬆ Back to Top](#myass-ecommerce-mobile-app)

</div>
