# MYASS E-commerce Mobile App

A complete e-commerce mobile app for MYASS Smart Watches store with Flutter frontend and Supabase backend.

## Features

- **Dark Luxe Theme**: Modern, premium dark design with purple accents
- **Product Catalog**: Browse smart watches and fitness trackers
- **Shopping Cart**: Add to cart functionality with quantity management
- **Favorites**: Save favorite products
- **User Profile**: Manage account and view order history
- **Order Management**: Complete order flow
- **Search**: Product search functionality
- **Categories**: Filter by product categories (Sport, Luxury, Fitness)
- **Admin Dashboard**: Manage products and orders

## Tech Stack

### Frontend (Flutter)
- Flutter 3.0+
- Provider for state management
- Supabase Flutter SDK for authentication and database
- Cached Network Images for image loading
- Carousel Slider for product galleries
- Shimmer for loading animations

### Backend (Supabase)
- Supabase Authentication (Email/Password, Google, Facebook OAuth)
- PostgreSQL Database
- Row Level Security (RLS) policies
- Real-time subscriptions
- Storage for product images

### Database Schema (Supabase)
- `user_profiles` - User profiles with roles (customer/admin)
- `products` - Products with categories and featured flags
- `orders` - Order management
- `order_items` - Order items with price tracking

## Project Structure

```
myass_ecommerce/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── error/
│   │   ├── services/
│   │   ├── usecases/
│   │   └── utils/
│   ├── features/
│   │   ├── auth/
│   │   ├── products/
│   │   ├── cart/
│   │   ├── favorites/
│   │   ├── profile/
│   │   ├── admin/
│   │   └── onboarding/
│   ├── providers/
│   ├── services/
│   └── theme/
├── assets/
│   ├── images/
│   ├── icons/
│   └── lottie/
├── supabase_schema.sql
└── pubspec.yaml
```

## Installation

### Prerequisites
- Flutter SDK 3.0+
- Supabase account (free tier works)

### Frontend Setup

1. Clone the repository
```bash
git clone <repository-url>
cd myass_ecommerce
```

2. Install Flutter dependencies
```bash
flutter pub get
```

3. Configure Supabase
- Create a new project in [Supabase](https://supabase.com)
- Run the SQL from `supabase_schema.sql` in your Supabase SQL Editor
- Copy your Supabase URL and anon key
- Create a `.env` file in the project root:
```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

4. Run the app
```bash
flutter run
```

## Supabase Setup

### Database Tables
Run the SQL script `supabase_schema.sql` in your Supabase SQL Editor to create:
- `user_profiles` table with RLS policies
- `products` table with RLS policies
- `orders` table with RLS policies
- `order_items` table with RLS policies
- Triggers for new user registration
- Helper functions for admin role checking

### Storage Setup
Create a storage bucket named `product-images` in Supabase:
- Make it public
- Configure appropriate RLS policies for upload/download

## Theme Configuration

The app uses a Dark Luxe theme with:
- **Primary Color**: #9B59B6 (Purple gradient)
- **Background**: #000000 (Black)
- **Card Background**: #1E1E1E / #2C2C2C
- **Text**: #FFFFFF (White)
- **Border Radius**: 20px for cards

## Sample Data

The Supabase schema includes sample products:
- Apple Watch Series 9
- Samsung Galaxy Watch 6
- Garmin Fenix 7
- Fitbit Versa 4
- Fossil Gen 6
- And more...

## Development

### Adding New Products
1. Use the Admin Dashboard (requires admin role)
2. Or add directly via Supabase dashboard
3. Upload product images to Supabase Storage

### Setting Admin Role
To make a user an admin, update their role in Supabase:
```sql
UPDATE public.user_profiles 
SET role = 'admin' 
WHERE email = 'user@example.com';
```

### Customizing Theme
Edit `lib/theme/app_theme.dart` to modify colors and styles.

### Adding New Features
1. Create new screens in `lib/features/`
2. Add providers for state management if needed
3. Update navigation in `main.dart`

## Production Deployment

### Frontend
1. Build the release APK/AAB:
```bash
flutter build apk --release
flutter build appbundle --release
```

### Supabase
1. Enable proper RLS policies for production
2. Set up authentication providers (Google, Facebook)
3. Configure storage buckets with proper policies
4. Enable database backups

## Security Considerations

- Row Level Security (RLS) is enabled on all tables
- Authentication required for sensitive operations
- Admin-only operations protected by role checks
- Environment variables for sensitive data (.env file)
- Never commit .env file to version control

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For support and questions, please contact the development team or create an issue in the repository.

---

**MYASS** - Premium Smart Watches Store
*Quality smart watches and fitness trackers*

## Recent Changes

- Removed PHP backend - now using Supabase exclusively
- Fixed order history to fetch real data from Supabase
- Removed debug code from admin screens
- Updated documentation for Supabase-only architecture
