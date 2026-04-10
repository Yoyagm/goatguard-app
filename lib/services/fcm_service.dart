import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'api_service.dart';

/// Top-level handler for background/terminated FCM messages.
/// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background message: ${message.messageId}');
}

/// Manages Firebase Cloud Messaging lifecycle.
class FcmService {
  FirebaseMessaging? _messaging;
  final ApiService _api;

  String? _currentToken;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<String>? _tokenRefreshSub;

  VoidCallback? onForegroundAlert;
  VoidCallback? onNotificationTap;

  FcmService(this._api);

  String? get currentToken => _currentToken;

  Future<void> initialize() async {
    _messaging = FirebaseMessaging.instance;
    final settings = await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('FCM: user denied notification permission');
      return;
    }

    await _createNotificationChannel();

    _currentToken = await _messaging!.getToken();
    debugPrint('FCM token: $_currentToken');

    _tokenRefreshSub = _messaging!.onTokenRefresh.listen((newToken) {
      _currentToken = newToken;
      _registerTokenWithBackend(newToken);
    });

    _foregroundSub = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );

    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    final initial = await _messaging!.getInitialMessage();
    if (initial != null) {
      _handleNotificationTap(initial);
    }
  }

  Future<void> registerToken() async {
    if (_currentToken == null) return;
    await _registerTokenWithBackend(_currentToken!);
  }

  Future<void> unregisterToken() async {
    if (_currentToken == null) return;
    try {
      await _api.unregisterFcmToken(_currentToken!);
    } catch (e) {
      debugPrint('FCM: failed to unregister token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('FCM foreground: ${message.notification?.title}');
    onForegroundAlert?.call();
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('FCM notification tapped: ${message.data}');
    onNotificationTap?.call();
  }

  Future<void> _registerTokenWithBackend(String token) async {
    try {
      await _api.registerFcmToken(token);
    } catch (e) {
      debugPrint('FCM: failed to register token with backend: $e');
    }
  }

  Future<void> _createNotificationChannel() async {
    const channel = MethodChannel('com.goatguard.goatguard_app/notifications');
    try {
      await channel.invokeMethod('createNotificationChannel', {
        'id': 'goatguard_alerts',
        'name': 'GOATGuard Alerts',
        'description': 'Network security and anomaly alerts',
        'importance': 4,
      });
    } catch (e) {
      debugPrint('FCM: failed to create notification channel: $e');
    }
  }

  void dispose() {
    _foregroundSub?.cancel();
    _tokenRefreshSub?.cancel();
  }
}
