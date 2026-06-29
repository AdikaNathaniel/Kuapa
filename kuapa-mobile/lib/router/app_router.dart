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
import '../features/logistics/presentation/screens/delivery_tracking_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/reviews/presentation/screens/write_review_screen.dart';
import '../core/services/notification_service.dart';
import '../shared/widgets/farmer_shell.dart';

final appRouter = _buildRouter();

GoRouter _buildRouter() {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),

      // ── Auth ────────────────────────────────────────────────────────────────
      GoRoute(path: '/login',         builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register',      builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/profile-setup', builder: (_, __) => const ProfileSetupScreen()),

      // ── Overlays (push over any shell — no bottom nav) ──────────────────────
      GoRoute(path: '/farmer/add-product', builder: (_, __) => const AddProductScreen()),
      GoRoute(path: '/farmer/request-transport', builder: (_, __) => const RequestTransportScreen()),
      GoRoute(
        path: '/buyer/product/:id',
        builder: (_, state) => ProductDetailScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/logistics/track/:id',
        builder: (_, state) => DeliveryTrackingScreen(requestId: state.pathParameters['id']!),
      ),
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
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
      GoRoute(
        path: '/reviews/write',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return WriteReviewScreen(
            revieweeId:   extra['revieweeId'] as String,
            revieweeName: extra['revieweeName'] as String,
            revieweeType: extra['revieweeType'] as String,
            orderId:      extra['orderId'] as String?,
          );
        },
      ),
      GoRoute(path: '/chat', builder: (_, __) => const ConversationsScreen()),
      GoRoute(
        path: '/chat/:id',
        builder: (_, state) => ChatScreen(
          conversationId: state.pathParameters['id']!,
          otherName: state.extra as String? ?? 'Chat',
        ),
      ),

      // ── Farmer shell (4 tabs) ───────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => FarmerShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/farmer/dashboard', builder: (_, __) => const FarmerDashboard()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/farmer/listings', builder: (_, __) => const MyListingsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/farmer/orders', builder: (_, __) => const FarmerOrdersScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/farmer/transport', builder: (_, __) => const MyTransportRequestsScreen()),
          ]),
        ],
      ),

      // ── Buyer shell (5 tabs) ────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => BuyerShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/buyer/dashboard', builder: (_, __) => const BuyerDashboard()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/buyer/marketplace', builder: (_, __) => const MarketplaceScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/buyer/orders', builder: (_, __) => const OrderHistoryScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/buyer/chat', builder: (_, __) => const ConversationsScreen()),
            GoRoute(
              path: '/buyer/chat/:id',
              builder: (_, state) => ChatScreen(
                conversationId: state.pathParameters['id']!,
                otherName: state.extra as String? ?? 'Chat',
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/buyer/deliveries', builder: (_, __) => const BuyerDeliveryScreen()),
          ]),
        ],
      ),

      // ── Transporter shell (3 tabs) ──────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => TransporterShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/transporter/dashboard', builder: (_, __) => const TransporterDashboard()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/transporter/requests', builder: (_, __) => const TransportRequestsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/transporter/map',
              builder: (_, __) => const NearbyTransportersScreen(
                pickupLat: null, pickupLng: null,
                deliveryLat: null, deliveryLng: null,
              ),
            ),
          ]),
        ],
      ),
    ],
  );

  NotificationService.instance.setRouter(router);
  return router;
}
