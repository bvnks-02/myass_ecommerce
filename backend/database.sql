-- MYASS E-commerce Database Schema
-- Smart Watches Store

CREATE DATABASE IF NOT EXISTS myass_ecommerce;
USE myass_ecommerce;

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    password VARCHAR(255) NOT NULL,
    api_token VARCHAR(255) UNIQUE DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Categories table
CREATE TABLE IF NOT EXISTS categories (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Products table
CREATE TABLE IF NOT EXISTS products (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    image VARCHAR(255) NOT NULL,
    category_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
);

-- Orders table
CREATE TABLE IF NOT EXISTS orders (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    total DECIMAL(10,2) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    address TEXT NOT NULL,
    status ENUM('Pending','Confirmed','Delivered','Cancelled') DEFAULT 'Pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Order items table
CREATE TABLE IF NOT EXISTS order_items (
    id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

-- Cart table (for guest users or temporary storage)
CREATE TABLE IF NOT EXISTS cart (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    product_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    UNIQUE KEY unique_cart_item (user_id, product_id)
);

-- Insert sample categories
INSERT INTO categories (name) VALUES 
('Sport'),
('Luxury'),
('Fitness');

-- Insert sample products
INSERT INTO products (name, description, price, image, category_id) VALUES 
('Apple Watch Series 9', 'Advanced health features, ECG, blood oxygen monitoring. Always-on Retina display.', 399.00, 'https://images.unsplash.com/photo-1546868871-7041f2a55e12?w=400', 1),
('Samsung Galaxy Watch 6', 'Comprehensive health tracking, sleep analysis, fitness monitoring with GPS.', 349.99, 'https://images.unsplash.com/photo-1579586337278-3befd40fd17a?w=400', 1),
('Garmin Fenix 7', 'Premium multisport GPS watch with solar charging and advanced training features.', 699.99, 'https://images.unsplash.com/photo-1508685096489-7aacd43bd3b1?w=400', 1),
('Fitbit Versa 4', 'Health and fitness tracker with built-in GPS, sleep tracking, and smart notifications.', 229.99, 'https://images.unsplash.com/photo-1575311373937-040b8e1fd5b6?w=400', 3),
('Fossil Gen 6', 'Classic design with modern smart features. Heart rate, GPS, and Wear OS.', 299.00, 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400', 2),
('Casio G-Shock GBA-900', 'Rugged sport watch with step tracking and Bluetooth connectivity.', 149.99, 'https://images.unsplash.com/photo-1524592094714-0f0654e20314?w=400', 1),
('Huawei Watch GT 3', 'Long battery life up to 14 days. Health monitoring and 100+ workout modes.', 279.99, 'https://images.unsplash.com/photo-1508685096489-7aacd43bd3b1?w=400', 1),
('Amazfit GTS 4', 'Slim design with 150+ sports modes, blood oxygen, and stress monitoring.', 199.99, 'https://images.unsplash.com/photo-1546868871-7041f2a55e12?w=400', 3),
('Suunto 9 Peak Pro', 'Ultra-light sport watch with GPS, barometer, and 100m water resistance.', 599.00, 'https://images.unsplash.com/photo-1508685096489-7aacd43bd3b1?w=400', 1),
('TicWatch Pro 3', 'Dual-layer display for extended battery life. Health tracking and GPS.', 279.99, 'https://images.unsplash.com/photo-1579586337278-3befd40fd17a?w=400', 3);

-- Insert sample user
INSERT INTO users (name, email, phone, password, api_token) VALUES 
('John Doe', 'john.doe@example.com', '+1234567890', '$2y$10$abcdefghijklmnopqrstuvwxyz1234567890', 'test_api_token_12345');

-- Create indexes for better performance
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_cart_user ON cart(user_id);
