class ApiConstants {
  static const String baseUrl = 'https://kuapa-app.fly.dev/api/v1';

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';

  // Users
  static const String farmerProfile = '/users/farmer/profile';
  static const String buyerProfile = '/users/buyer/profile';
  static const String transporterProfile = '/users/transporter/profile';
  static const String farmers = '/users/farmers';
  static const String availableTransporters = '/users/transporters/available';
  static const String nearbyTransporters = '/users/transporters/nearby';
  static const String transporterLocation = '/users/transporter/location';

  // Products
  static const String products = '/products';
  static const String categories = '/products/categories';
  static const String myListings = '/products/my-listings';

  // Orders
  static const String orders = '/orders';
  static const String myOrders = '/orders/my-orders';
  static const String farmerOrders = '/orders/farmer-orders';
  static const String farmerStats = '/orders/farmer-stats';

  // Logistics
  static const String transportRequests = '/logistics/requests';
  static const String availableRequests = '/logistics/requests/available';
  static const String myRequests = '/logistics/requests/mine';
  static const String myAssignments = '/logistics/assignments/mine';
  static const String estimateCost = '/logistics/estimate-cost';

  // Notifications
  static const String notifications = '/notifications';
  static const String fcmToken = '/notifications/fcm-token';

  // Chat
  static const String conversations = '/chat/conversations';

  // Reviews
  static const String reviews = '/reviews';

  // Payments
  static const String initiatePayment = '/payments/initiate';
  static const String paymentHistory = '/payments/history';
  static const String verifyPayment = '/payments/verify';

  // Chat REST
  static const String chatMessages = '/chat/conversations';

  // WebSocket — connects directly to chat-service (not api-gateway)
  static const String wsUrl = 'https://kuapa-chat.fly.dev';
}
