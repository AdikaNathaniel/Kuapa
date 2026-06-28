import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/profile_setup_screen.dart';
import '../features/farmer/presentation/screens/farmer_dashboard.dart';
import '../features/farmer/presentation/screens/add_product_screen.dart';
import '../features/farmer/presentation/screens/farmer_orders_screen.dart';
import '../features/farmer/presentation/screens/my_listings_screen.dart';
import '../features/farmer/presentation/screens/request_transport_screen.dart';
import '../features/farmer/presentation/screens/my_transport_requests_screen.dart';
import '../features/buyer/presentation/screens/buyer_dashboard.dart';
import '../features/buyer/presentation/screens/marketplace_screen.dart';
import '../features/buyer/presentation/screens/product_detail_screen.dart';
import '../features/buyer/presentation/screens/order_history_screen.dart';
import '../features/buyer/presentation/screens/buyer_delivery_screen.dart';
import '../features/transporter/presentation/screens/transporter_dashboard.dart';
import '../features/transporter/presentation/screens/transport_requests_screen.dart';
import '../features/chat/presentation/screens/conversations_screen.dart';
import '../features/chat/presentation/screens/chat_screen.dart';
import '../features/logistics/presentation/screens/nearby_transporters_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),

    // Auth
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/profile-setup', builder: (_, __) => const ProfileSetupScreen()),

    // Farmer
    GoRoute(path: '/farmer/dashboard', builder: (_, __) => const FarmerDashboard()),
    GoRoute(path: '/farmer/add-product', builder: (_, __) => const AddProductScreen()),
    GoRoute(path: '/farmer/listings', builder: (_, __) => const MyListingsScreen()),
    GoRoute(path: '/farmer/orders', builder: (_, __) => const FarmerOrdersScreen()),
    GoRoute(path: '/farmer/request-transport', builder: (_, __) => const RequestTransportScreen()),
    GoRoute(path: '/farmer/transport', builder: (_, __) => const MyTransportRequestsScreen()),

    // Buyer
    GoRoute(path: '/buyer/dashboard', builder: (_, __) => const BuyerDashboard()),
    GoRoute(path: '/buyer/marketplace', builder: (_, __) => const MarketplaceScreen()),
    GoRoute(
      path: '/buyer/product/:id',
      builder: (_, state) => ProductDetailScreen(productId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/buyer/orders', builder: (_, __) => const OrderHistoryScreen()),
    GoRoute(path: '/buyer/deliveries', builder: (_, __) => const BuyerDeliveryScreen()),

    // Transporter
    GoRoute(path: '/transporter/dashboard', builder: (_, __) => const TransporterDashboard()),
    GoRoute(path: '/transporter/requests', builder: (_, __) => const TransportRequestsScreen()),

    // Logistics
    GoRoute(
      path: '/logistics/nearby',
      builder: (_, state) {
        final extra = state.extra as Map<String, double?>?;
        return NearbyTransportersScreen(
          pickupLat:   extra?['pickupLat'],
          pickupLng:   extra?['pickupLng'],
          deliveryLat: extra?['deliveryLat'],
          deliveryLng: extra?['deliveryLng'],
        );
      },
    ),

    // Chat
    GoRoute(path: '/chat', builder: (_, __) => const ConversationsScreen()),
    GoRoute(
      path: '/chat/:id',
      builder: (_, state) => ChatScreen(
        conversationId: state.pathParameters['id']!,
        otherName: state.extra as String? ?? 'Chat',
      ),
    ),
  ],
);
