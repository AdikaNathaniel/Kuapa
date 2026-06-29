import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _fcm = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();
  GoRouter? _router;

  static const _channelId   = 'kuapa_notifications';
  static const _channelName = 'Kuapa Notifications';
  static const _channelDesc = 'Delivery updates, order alerts, and messages';

  void setRouter(GoRouter router) => _router = router;

  Future<void> init() async {
    // Permission
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // Android foreground notification channel
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId, _channelName,
          description: _channelDesc,
          importance: Importance.high,
        ));

    // Local notifications init
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _local.initialize(settings, onDidReceiveNotificationResponse: _onLocalTap);

    // Show banner when message arrives while app is open
    FirebaseMessaging.onMessage.listen(_showForegroundNotif);

    // User tapped a notification while app was in background
    FirebaseMessaging.onMessageOpenedApp.listen(_onRemoteTap);

    // User tapped a notification that launched the app from terminated state
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _onRemoteTap(initial);

    // Register this device's token with the backend (best-effort; may fail if not yet logged in)
    _refreshAndRegister();
    _fcm.onTokenRefresh.listen(_registerToken);
  }

  /// Call this explicitly after a successful login so the token is registered
  /// even if the silent attempt in [init] fired before the JWT was available.
  Future<void> registerTokenAfterLogin() => _refreshAndRegister();

  Future<void> _refreshAndRegister() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) await _registerToken(token);
    } catch (_) {}
  }

  Future<void> _registerToken(String token) async {
    try {
      await ApiClient.instance.post(ApiConstants.fcmToken, data: {
        'token': token,
        'deviceType': 'ANDROID',
      });
    } catch (_) {}
  }

  void _showForegroundNotif(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    _local.show(
      message.hashCode,
      n.title,
      n.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId, _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _onRemoteTap(RemoteMessage message) => _navigate(message.data);

  void _onLocalTap(NotificationResponse r) {
    if (r.payload == null) return;
    try {
      _navigate(jsonDecode(r.payload!) as Map<String, dynamic>);
    } catch (_) {}
  }

  void _navigate(Map<String, dynamic> data) {
    final route = _routeFromData(data);
    if (route != null) _router?.push(route);
  }

  String? _routeFromData(Map<String, dynamic> data) {
    final type  = data['type']?.toString();
    final refId = data['referenceId']?.toString();
    switch (type) {
      case 'TRANSPORT': return refId != null ? '/logistics/track/$refId' : '/notifications';
      case 'ORDER':     return '/buyer/orders';
      case 'MESSAGE':   return refId != null ? '/chat/$refId' : '/chat';
      default:          return '/notifications';
    }
  }
}
