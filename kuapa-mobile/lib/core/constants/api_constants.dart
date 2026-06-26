class ApiConstants {
  static const String baseUrl = 'http://10.0.2.2:3000/api/v1'; // Android emulator → localhost
  // static const String baseUrl = 'http://localhost:3000/api/v1'; // iOS simulator

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

  // WebSocket
  static const String wsUrl = 'http://10.0.2.2:3007'; // chat-service
}
