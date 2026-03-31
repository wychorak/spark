import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/constants/app_config.dart';
import 'core/services/analytics_service.dart';
import 'core/services/crash_reporting_service.dart';
import 'features/notifications/notification_service.dart';

/// In-memory session storage avoids localStorage/SharedPreferences errors on web.
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
  await CrashReportingService.instance.init(
    appRunner: () async {
      WidgetsFlutterBinding.ensureInitialized();

      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );

      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      try {
        await Firebase.initializeApp();
        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );
      } catch (e, stackTrace) {
        debugPrint('[Firebase] Init error (add config files): $e');
        await CrashReportingService.instance.captureException(
          e,
          stackTrace: stackTrace,
        );
      }

      await AnalyticsService.instance.init();

      if (!AppConfig.hasSupabaseConfig) {
        runApp(
          const _BootstrapErrorApp(
            message:
                'Brakuje konfiguracji aplikacji. Ustaw SUPABASE_URL i SUPABASE_ANON_KEY w --dart-define.',
          ),
        );
        return;
      }

      if (AppConfig.revenueCatKey.isNotEmpty) {
        try {
          await Purchases.setLogLevel(LogLevel.error);
          await Purchases.configure(
            PurchasesConfiguration(AppConfig.revenueCatKey),
          );
          debugPrint('[RevenueCat] Configured');
        } catch (e, stackTrace) {
          debugPrint('[RevenueCat] Init error: $e');
          await CrashReportingService.instance.captureException(
            e,
            stackTrace: stackTrace,
          );
        }
      } else {
        debugPrint('[RevenueCat] Skipped: REVENUECAT_KEY not provided');
      }

      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
        authOptions: FlutterAuthClientOptions(
          authFlowType: AuthFlowType.implicit,
          localStorage: kIsWeb ? _InMemoryLocalStorage() : null,
        ),
      );

      await AnalyticsService.instance.track('app_started');

      runApp(
        const ProviderScope(
          child: SparkApp(),
        ),
      );
    },
  );
}

class _BootstrapErrorApp extends StatelessWidget {
  const _BootstrapErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
