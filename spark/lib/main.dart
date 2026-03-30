import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'features/notifications/notification_service.dart';

/// In-memory session storage — avoids localStorage/SharedPreferences errors
/// on web (Edge Tracking Prevention on localhost). Session lasts for the tab lifetime.
class _InMemoryLocalStorage extends LocalStorage {
  String? _value;

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> accessToken() async => _value;

  @override
  Future<bool> hasAccessToken() async => _value != null;

  @override
  Future<void> persistSession(String persistSessionString) async {
    _value = persistSessionString;
  }

  @override
  Future<void> removePersistedSession() async {
    _value = null;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Firebase — must init before NotificationService
  // NOTE: Requires google-services.json (Android) and GoogleService-Info.plist (iOS)
  // See setup instructions in CLAUDE.md
  try {
    await Firebase.initializeApp();
    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('[Firebase] Init error (add config files): $e');
  }

  // RevenueCat — pass real key via --dart-define=REVENUECAT_KEY=...
  // Public key (test): appl_test_sfvqsszHhURDKKsCbPgTAIkDhTJ
  const revenueCatKey = String.fromEnvironment(
    'REVENUECAT_KEY',
    defaultValue: 'appl_test_sfvqsszHhURDKKsCbPgTAIkDhTJ',
  );
  try {
    await Purchases.setLogLevel(LogLevel.error);
    final config = PurchasesConfiguration(revenueCatKey);
    await Purchases.configure(config);
    debugPrint('[RevenueCat] Configured');
  } catch (e) {
    debugPrint('[RevenueCat] Init error: $e');
  }

  // Supabase
  await Supabase.initialize(
    url: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://fildemavidnskmhcyqin.supabase.co',
    ),
    anonKey: const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZpbGRlbWF2aWRuc2ttaGN5cWluIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQxMjA4NDIsImV4cCI6MjA4OTY5Njg0Mn0.RMvXg1oy3ZC2z4KJb6BI0OcxBaS6yhk5jdnQWTp8yRk',
    ),
    // On web: in-memory storage avoids localStorage/SharedPreferences errors
    // caused by Edge Tracking Prevention on localhost.
    // On native: default SharedPreferences storage is used.
    authOptions: FlutterAuthClientOptions(
      authFlowType: AuthFlowType.implicit,
      localStorage: kIsWeb ? _InMemoryLocalStorage() : null,
    ),
  );

  runApp(
    const ProviderScope(
      child: SparkApp(),
    ),
  );
}
