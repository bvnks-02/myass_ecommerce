<?php
// Database configuration
class Database {
    private $host = defined('DB_HOST') ? DB_HOST : 'localhost';
    private $dbname = defined('DB_NAME') ? DB_NAME : 'myass_ecommerce';
    private $username = defined('DB_USER') ? DB_USER : 'root';
    private $password = defined('DB_PASS') ? DB_PASS : '';
    
    public function getConnection() {
        try {
            $conn = new PDO(
                "mysql:host={$this->host};dbname={$this->dbname};charset=utf8mb4",
                $this->username,
                $this->password
            );
            $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            return $conn;
        } catch (PDOException $e) {
            die("Connection failed: " . $e->getMessage());
        }
    }
}

// WhatsApp configuration
class WhatsAppConfig {
    private $apiKey = defined('WHATSAPP_API_KEY') ? WHATSAPP_API_KEY : 'YOUR_WHATSAPP_API_KEY'; // Replace with your actual API key
    private $phoneNumber = defined('WHATSAPP_PHONE') ? WHATSAPP_PHONE : '1234567890'; // Replace with your business phone number
    
    public function sendOrderNotification(orderData) {
        message = "🛍 *NEW ORDER RECEIVED*%0A";
        message .= "Order ID: #" . orderData['id'] . "%0A";
        message .= "Customer: " . orderData['customer_name'] . "%0A";
        message .= "Phone: " . orderData['phone'] . "%0A";
        message .= "Total: $" . number_format(orderData['total'], 2) . "%0A";
        message .= "Status: " . orderData['status'] . "%0A%0A";
        message .= "📦 *Items:*%0A";
        
        foreach (orderData['items'] as item) {
            message .= "• " . $item['quantity'] . "x " . $item['product_name'] . " - $" . number_format($item['price'], 2) . "%0A";
        }
        
        // This is a placeholder - implement actual WhatsApp API integration
        // You can use services like Twilio, WhatsApp Business API, etc.
        $url = "https://api.whatsapp.com/send?phone={$this->phoneNumber}&text=" . urlencode($message);
        
        // For demonstration, we'll just log the message
        error_log("WhatsApp notification: " . $message);
        
        return true;
    }
}

// Note: Best practice is to load sensitive credentials like DB password and WhatsApp API key
// from environment variables (e.g., using an env.php file) instead of hardcoding them here.

// CORS headers
$allowed_origin = '*'; // Consider changing this to your specific production frontend URL (e.g., 'https://yourdomain.com') instead of '*' for better security.
header("Access-Control-Allow-Origin: " . $allowed_origin);
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Helper function for JSON responses
function json_response(data, status_code = 200) {
    http_response_code(status_code);
    echo json_encode(data);
    exit();
}

// Authentication helper
function authenticate($conn) {
    $auth_header = '';
    
    if (isset($_SERVER['HTTP_AUTHORIZATION'])) {
        $auth_header = $_SERVER['HTTP_AUTHORIZATION'];
    } elseif (function_exists('apache_request_headers')) {
        $requestHeaders = apache_request_headers();
        if (isset($requestHeaders['Authorization'])) {
            $auth_header = $requestHeaders['Authorization'];
        }
    }

    if (preg_match('/Bearer\s(\S+)/', $auth_header, $matches)) {
        $token = $matches[1];
        
        $stmt = $conn->prepare("SELECT id FROM users WHERE api_token = :token");
        $stmt->execute([':token' => $token]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($user) {
            return $user['id'];
        }
    }
    
    error_response("Unauthorized: Invalid or missing API token", 401);
}

// Helper function for error responses
function error_response(message, status_code = 400) {
    json_response(['success' => false, 'message' => $message], $status_code);
}
?>
