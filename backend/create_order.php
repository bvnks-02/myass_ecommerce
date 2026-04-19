<?php
require_once 'config.php';

// Get POST data
$json = file_get_contents('php://input');
$data = json_decode($json, true);

if (!$data) {
    error_response("Invalid JSON data");
}

// Validate required fields
$required_fields = ['phone', 'address', 'items'];
foreach ($required_fields as $field) {
    if (!isset($data[$field]) || empty($data[$field])) {
        error_response("Missing required field: " . $field);
    }
}

try {
    $database = new Database();
    $conn = $database->getConnection();
    
    // Authenticate user via token
    $user_id = authenticate($conn);
    
    // Calculate final total and get authoritative prices from database
    $total = 0;
    $processed_items = [];
    
    $price_stmt = $conn->prepare("SELECT price FROM products WHERE id = :product_id");
    
    foreach ($data['items'] as $item) {
        if (!isset($item['product_id']) || !isset($item['quantity'])) {
            error_response("Invalid items format");
        }
        
        $price_stmt->execute([':product_id' => $item['product_id']]);
        $product = $price_stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$product) {
            error_response("Product not found: " . $item['product_id']);
        }
        
        $price = $product['price'];
        $quantity = (int)$item['quantity'];
        
        if ($quantity <= 0) {
            error_response("Invalid quantity for product: " . $item['product_id']);
        }
        
        $total += ($price * $quantity);
        
        $processed_items[] = [
            'product_id' => $item['product_id'],
            'quantity' => $quantity,
            'price' => $price
        ];
    }
    
    // Start transaction
    $conn->beginTransaction();
    
    // Insert order
    $order_query = "INSERT INTO orders (user_id, total, phone, address, status) 
                   VALUES (:user_id, :total, :phone, :address, 'Pending')";
    
    $order_stmt = $conn->prepare($order_query);
    $order_stmt->execute([
        ':user_id' => $user_id,
        ':total' => $total,
        ':phone' => $data['phone'],
        ':address' => $data['address']
    ]);
    
    $order_id = $conn->lastInsertId();
    
    // Insert order items
    $item_query = "INSERT INTO order_items (order_id, product_id, quantity, price) 
                    VALUES (:order_id, :product_id, :quantity, :price)";
    
    $item_stmt = $conn->prepare($item_query);
    
    foreach ($processed_items as $item) {
        $item_stmt->execute([
            ':order_id' => $order_id,
            ':product_id' => $item['product_id'],
            ':quantity' => $item['quantity'],
            ':price' => $item['price']
        ]);
    }
    
    // Commit transaction
    $conn->commit();
    
    // Get order details for WhatsApp notification
    // Get order details for WhatsApp notification
    $order_details_query = "SELECT o.*, u.name as customer_name 
                          FROM orders o 
                          LEFT JOIN users u ON o.user_id = u.id 
                          WHERE o.id = :order_id";
    
    $details_stmt = $conn->prepare($order_details_query);
    $details_stmt->execute([':order_id' => $order_id]);
    $order_details = $details_stmt->fetch(PDO::FETCH_ASSOC);
    
    // Get order items for notification
    $items_query = "SELECT oi.*, p.name as product_name 
                    FROM order_items oi 
                    JOIN products p ON oi.product_id = p.id 
                    WHERE oi.order_id = :order_id";
    
    $items_stmt = $conn->prepare($items_query);
    $items_stmt->execute([':order_id' => $order_id]);
    $order_items = $items_stmt->fetchAll(PDO::FETCH_ASSOC);
    
    $order_details['items'] = $order_items;
    
    // Send WhatsApp notification
    $whatsapp = new WhatsAppConfig();
    $whatsapp->sendOrderNotification($order_details);
    
    json_response([
        'success' => true,
        'message' => 'Order created successfully',
        'order_id' => $order_id
    ]);
    
} catch (PDOException $e) {
    if (isset($conn) && $conn->inTransaction()) {
        $conn->rollBack();
    }
    error_response("Failed to create order: " . $e->getMessage());
} catch (Exception $e) {
    error_response("Error: " . $e->getMessage());
}
?>
