# MYASS E-commerce Mobile App

A complete e-commerce mobile app for MYASS Smart Watches store with Flutter frontend, PHP backend, and MySQL database.

## Features

- **Dark Luxe Theme**: Modern, premium dark design with purple accents
- **Product Catalog**: Browse smart watches and fitness trackers
- **Shopping Cart**: Add to cart functionality with quantity management
- **Favorites**: Save favorite products
- **User Profile**: Manage account and view order history
- **Order Management**: Complete order flow with WhatsApp notifications
- **Search**: Product search functionality
- **Categories**: Filter by product categories (Sport, Luxury, Fitness)

## Tech Stack

### Frontend (Flutter)
- Flutter 3.0+
- Provider for state management
- HTTP for API calls
- Cached Network Images for image loading
- Carousel Slider for product galleries
- Shimmer for loading animations
- Shared Preferences for local storage

### Backend (PHP)
- PHP 8.0+ with PDO
- MySQL database
- RESTful API endpoints
- WhatsApp notifications integration
- CORS enabled for cross-origin requests

### Database (MySQL)
- Users table for customer management
- Products table with categories
- Orders and order items for order tracking
- Cart table for temporary storage

## Project Structure

```
myass_ecommerce/
├── lib/
│   ├── main.dart
│   ├── theme/
│   │   └── app_theme.dart
│   ├── screens/
│   │   ├── splash_screen.dart
│   │   ├── home_screen.dart
│   │   ├── product_details_screen.dart
│   │   ├── cart_screen.dart
│   │   ├── favorites_screen.dart
│   │   └── profile_screen.dart
│   ├── providers/
│   │   ├── cart_provider.dart
│   │   └── favorites_provider.dart
│   ├── models/
│   │   └── product.dart
│   └── services/
│       └── api_service.dart
├── backend/
│   ├── config.php
│   ├── database.sql
│   ├── products.php
│   ├── featured_products.php
│   └── create_order.php
└── assets/
    ├── images/
    └── icons/
```

## Installation

### Prerequisites
- Flutter SDK 3.0+
- PHP 8.0+
- MySQL 8.0+
- Web server (Apache/Nginx)

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

3. Run the app
```bash
flutter run
```

### Backend Setup

1. Set up the database
```bash
mysql -u root -p < backend/database.sql
```

2. Configure Database and Secrets
For security reasons, do not hardcode your credentials in `config.php`. Instead, create a new file named `env.php` (make sure it's added to `.gitignore`) in the `backend/` folder:

```php
<?php
// backend/env.php
define('DB_HOST', 'localhost');
define('DB_NAME', 'myass_ecommerce');
define('DB_USER', 'your_username');
define('DB_PASS', 'your_password');
define('WHATSAPP_API_KEY', 'your_api_key_here');
define('WHATSAPP_PHONE', '1234567890');
?>
```

Then update `backend/config.php` to use these constants.

3. Configure App Authentication
The API requires an authentication token to create orders. 
You must generate users with an `api_token` in the database. A sample user is already provided with the token: `test_api_token_12345`.

4. Deploy the backend
Place the `backend/` folder on your web server with PHP support and ensure you configure your domain in the `$allowed_origin` CORS variable inside `config.php`.

## API Endpoints

### GET /products.php
Returns all products with category information.

### GET /featured_products.php
Returns featured products (first 3 products).

### POST /create_order.php
Creates a new order with the following JSON payload:

```json
{
  "user_id": 1,
  "total": 349.99,
  "phone": "+1234567890",
  "address": "123 Main St, City, Country",
  "items": [
    {
      "product_id": 1,
      "quantity": 1,
      "price": 349.99
    }
  ]
}
```

## WhatsApp Notifications

The app automatically sends WhatsApp notifications for new orders containing:
- Order ID
- Customer information
- Order total
- Order status
- List of ordered items

**Note**: You need to integrate with a WhatsApp API service (Twilio, WhatsApp Business API, etc.) and update the `sendOrderNotification()` method in `config.php`.

## Theme Configuration

The app uses a Dark Luxe theme with:
- **Primary Color**: #9B59B6 (Purple gradient)
- **Background**: #000000 (Black)
- **Card Background**: #1E1E1E / #2C2C2C
- **Text**: #FFFFFF (White)
- **Border Radius**: 20px for cards

## Sample Data

The database includes sample products:
- Apple Watch Series 9
- Samsung Galaxy Watch 6
- Garmin Fenix 7
- Fitbit Versa 4
- Fossil Gen 6
- And more...

## Development

### Adding New Products
1. Add products to the database via SQL or admin panel
2. Product images should be accessible via URL
3. Assign appropriate categories

### Customizing Theme
Edit `lib/theme/app_theme.dart` to modify colors and styles.

### Adding New Features
1. Create new screens in `lib/screens/`
2. Add providers for state management if needed
3. Update navigation in `main.dart`

## Production Deployment

### Frontend
1. Build the release APK/AAB:
```bash
flutter build apk --release
flutter build appbundle --release
```

### Backend
1. Configure HTTPS
2. Set up proper error handling
3. Implement authentication/authorization
4. Optimize database with proper indexes

## Security Considerations

- Implement user authentication
- Add input validation and sanitization
- Use prepared statements (already implemented)
- Enable HTTPS in production
- Implement rate limiting for API endpoints
- Add CSRF protection

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
