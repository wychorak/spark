import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:spark/core/services/notification_preferences_service.dart';

// ─── Background handler (top-level, required by Firebase) ───
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized in main.dart before this runs
  debugPrint('[FCM] Background message: ${message.messageId}');
}

// ─── Notification Service ────────────────────────────────────

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _fcm = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSub;
  bool _initialized = false;

  // Android notification channel
  static const _channel = AndroidNotificationChannel(
    'spark_notifications',
    'Spark Powiadomienia',
    description: 'Powiadomienia o matchach, wiadomościach i polubieniach.',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  // Global navigator key for routing from notification tap
  static final navigatorKey = GlobalKey<NavigatorState>();

  Future<void> init() async {
    if (_initialized) {
      await _registerToken();
      return;
    }

    // 1. Request permission (iOS asks user, Android 13+ asks user)
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

    // 2. Create Android channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 3. Init local notifications (for foreground display)
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // 4. iOS foreground presentation
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 5. Register FCM token with Supabase
    await _registerToken();

    // 6. Listen for token refreshes
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _fcm.onTokenRefresh.listen(_saveToken);

    // 7. Foreground message handler
    await _onMessageSub?.cancel();
    _onMessageSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // 8. App opened from background notification
    await _onMessageOpenedSub?.cancel();
    _onMessageOpenedSub =
        FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationOpenedApp);

    // 9. App opened from terminated state
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _onNotificationOpenedApp(initial);
    _initialized = true;
  }

  // ── Token management ─────────────────────────────────────

  Future<void> _registerToken() async {
    try {
      final token = Platform.isIOS
          ? await _fcm.getAPNSToken().then((_) => _fcm.getToken())
          : await _fcm.getToken();
      if (token != null) await _saveToken(token);
    } catch (e) {
      debugPrint('[FCM] Token registration error: $e');
    }
  }

  Future<void> _saveToken(String token) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      await Supabase.instance.client
          .from('push_tokens')
          .delete()
          .eq('user_id', userId)
          .eq('platform', platform);
      await Supabase.instance.client.from('push_tokens').insert({
        'user_id': userId,
        'token': token,
        'platform': platform,
      });
      debugPrint('[FCM] Token saved to Supabase');
    } catch (e) {
      debugPrint('[FCM] Token save error: $e');
    }
  }

  Future<void> deleteToken() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _fcm.deleteToken();
      await Supabase.instance.client
          .from('push_tokens')
          .delete()
          .eq('user_id', userId);
      _initialized = false;
    } catch (e) {
      debugPrint('[FCM] Token delete error: $e');
    }
  }

  // ── Message handlers ─────────────────────────────────────

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    debugPrint('[FCM] Foreground: ${message.notification?.title}');
    final notification = message.notification;
    if (notification == null) return;
    final type = message.data['type'] as String? ?? 'general';
    final isEnabled =
        await NotificationPreferencesService.instance.isEnabledForType(type);
    if (!isEnabled) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFFF6B9D),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: _buildPayload(message.data),
    );
  }

  void _onNotificationOpenedApp(RemoteMessage message) {
    debugPrint('[FCM] Opened app from notification: ${message.data}');
    _navigateFromData(message.data);
  }

  void _onNotificationTap(NotificationResponse response) {
    if (response.payload == null) return;
    final parts = response.payload!.split(':');
    if (parts.length < 2) return;
    _navigateFromData({'type': parts[0], 'id': parts[1]});
  }

  // ── Navigation logic ─────────────────────────────────────

  void _navigateFromData(Map<String, dynamic> data) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final type = data['type'] as String?;
    final id = data['id'] as String?;

    switch (type) {
      case 'new_match':
        // Go to matches tab
        context.go('/home/matches');
        break;
      case 'new_message':
        if (id != null) {
          final name = data['name'] as String? ?? '';
          final photo = data['photo'] as String? ?? '';
          final mode = data['mode'] as String? ?? 'relationship';
          final uid = data['uid'] as String? ?? '';
          context.push(
            '/chat/$id?name=${Uri.encodeComponent(name)}&photo=${Uri.encodeComponent(photo)}&mode=$mode&uid=${Uri.encodeComponent(uid)}',
          );
        }
        break;
      case 'super_like':
      case 'superlike':
        context.go('/home/matches');
        break;
      default:
        context.go('/home');
    }
  }

  String _buildPayload(Map<String, dynamic> data) {
    final type = data['type'] ?? 'general';
    final id = data['id'] ?? '';
    return '$type:$id';
  }
}
