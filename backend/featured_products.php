<?php
require_once 'config.php';

try {
    database = new Database();
    conn = database->getConnection();
    
    // Get featured products (first 3 products as featured)
    query = "SELECT p.*, c.name as category 
              FROM products p 
              LEFT JOIN categories c ON p.category_id = c.id 
              ORDER BY p.created_at DESC 
              LIMIT 3";
    
    stmt = conn->prepare(query);
    stmt->execute();
    
    products = stmt->fetchAll(PDO::FETCH_ASSOC);
    
    json_response([
        'success' => true,
        'data' => products
    ]);
    
} catch (PDOException $e) {
    error_response("Failed to fetch featured products: " . $e->getMessage());
}
?>
