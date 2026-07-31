import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Top-level background handler. Must be a top-level (not a class member) so it
/// can be invoked in its own isolate when the app is terminated / in background.
/// FCM already displays the system-tray notification for messages that carry a
/// `notification` payload, so here we only need to make sure Firebase is ready.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Nothing else to do: the OS shows the tray notification from the payload.
}

/// Wires up Firebase Cloud Messaging + a local-notification channel so the
/// teacher gets a system-tray notification when a tuition is posted in one of
/// their expected areas — even when the app is closed.
///
/// The ONLINE / app-open popup is handled separately by NearbyTuitionNotifier.
/// This service is the OFFLINE / app-closed half and depends on the cPanel
/// backend actually sending the push (see NOTIFICATIONS_SETUP.md).
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final ApiService _api = ApiService();
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'bdtuition_tuitions',
    'Tuition Alerts',
    description: 'Notifications about new tuitions near your area.',
    importance: Importance.high,
  );

  bool _initialised = false;
  String? _pendingToken;

  /// Call once at app startup (after Firebase.initializeApp()).
  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;

    try {
      // Local notifications: create the Android channel used for foreground alerts.
      const androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);
      await _local.initialize(initSettings);
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      final messaging = FirebaseMessaging.instance;

      // Ask permission (Android 13+ / iOS). Safe no-op on older Android.
      await messaging.requestPermission();

      // Show a local notification for foreground messages (FCM won't auto-display those).
      FirebaseMessaging.onMessage.listen(_showForeground);

      // Keep the backend token fresh if Firebase rotates it.
      messaging.onTokenRefresh.listen(_persistAndRegister);

      // Capture the current token. Registration with the backend happens once
      // the user is logged in (see registerWithBackendIfLoggedIn()).
      final token = await messaging.getToken();
      if (token != null) {
        _pendingToken = token;
        await _saveTokenLocally(token);
      }
    } catch (e) {
      // Never let notification setup crash the app.
      debugPrint('PushService init failed: $e');
    }
  }

  /// Send the token to the backend. Call after a successful login (token is set),
  /// so the interceptor can attach the auth header.
  Future<void> registerWithBackendIfLoggedIn() async {
    final token = _pendingToken ?? await _readTokenLocally();
    if (token == null) return;
    if (!_api.isLoggedIn) return;
    await _sendToBackend(token);
  }

  Future<void> _persistAndRegister(String token) async {
    _pendingToken = token;
    await _saveTokenLocally(token);
    if (_api.isLoggedIn) {
      await _sendToBackend(token);
    }
  }

  Future<void> _sendToBackend(String token) async {
    try {
      await _api.registerFcmToken(token);
    } catch (e) {
      // Backend endpoint may not be deployed yet — fail quietly, retry next launch.
      debugPrint('FCM token registration skipped: $e');
    }
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final n = message.notification;
    final title = n?.title ?? 'New Tuition Near You';
    final body = n?.body ?? _bodyFromData(message.data);
    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  String _bodyFromData(Map<String, dynamic> data) {
    final code = data['tuition_code'] ?? data['code'] ?? '';
    final area = data['area'] ?? data['location'] ?? '';
    return [code, area].where((s) => '$s'.isNotEmpty).join(' — ');
  }

  static const _kTokenKey = 'fcm_token_cached';

  Future<void> _saveTokenLocally(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTokenKey, token);
  }

  Future<String?> _readTokenLocally() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTokenKey);
  }
}
