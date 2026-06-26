import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/farmer/presentation/screens/farmer_dashboard.dart';
import '../features/farmer/presentation/screens/add_product_screen.dart';
import '../features/farmer/presentation/screens/farmer_orders_screen.dart';
import '../features/farmer/presentation/screens/my_listings_screen.dart';
import '../features/buyer/presentation/screens/buyer_dashboard.dart';
import '../features/buyer/presentation/screens/marketplace_screen.dart';
import '../features/buyer/presentation/screens/product_detail_screen.dart';
import '../features/buyer/presentation/screens/order_history_screen.dart';
import '../features/transporter/presentation/screens/transporter_dashboard.dart';
import '../features/transporter/presentation/screens/transport_requests_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),

    // Auth
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

    // Farmer
    GoRoute(path: '/farmer/dashboard', builder: (_, __) => const FarmerDashboard()),
    GoRoute(path: '/farmer/add-product', builder: (_, __) => const AddProductScreen()),
    GoRoute(path: '/farmer/listings', builder: (_, __) => const MyListingsScreen()),
    GoRoute(path: '/farmer/orders', builder: (_, __) => const FarmerOrdersScreen()),

    // Buyer
    GoRoute(path: '/buyer/dashboard', builder: (_, __) => const BuyerDashboard()),
    GoRoute(path: '/buyer/marketplace', builder: (_, __) => const MarketplaceScreen()),
    GoRoute(
      path: '/buyer/product/:id',
      builder: (_, state) => ProductDetailScreen(productId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/buyer/orders', builder: (_, __) => const OrderHistoryScreen()),

    // Transporter
    GoRoute(path: '/transporter/dashboard', builder: (_, __) => const TransporterDashboard()),
    GoRoute(path: '/transporter/requests', builder: (_, __) => const TransportRequestsScreen()),
  ],
);
