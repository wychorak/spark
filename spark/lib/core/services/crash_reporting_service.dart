import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../constants/app_config.dart';

class CrashReportingService {
  CrashReportingService._();

  static final CrashReportingService instance = CrashReportingService._();

  bool get isEnabled => AppConfig.sentryDsn.isNotEmpty;

  Future<void> init({
    required FutureOr<void> Function() appRunner,
  }) async {
    if (!isEnabled) {
      await appRunner();
      return;
    }

    await SentryFlutter.init(
      (options) {
        options.dsn = AppConfig.sentryDsn;
        options.environment = kReleaseMode ? 'production' : 'development';
        options.tracesSampleRate = kReleaseMode ? 0.1 : 1.0;
        options.profilesSampleRate = kReleaseMode ? 0.1 : 1.0;
      },
      appRunner: () async => appRunner(),
    );
  }

  Future<void> setUser({
    required String userId,
    String? email,
  }) async {
    if (!isEnabled) return;
    await Sentry.configureScope((scope) {
      scope.setUser(SentryUser(id: userId, email: email));
    });
  }

  Future<void> clearUser() async {
    if (!isEnabled) return;
    await Sentry.configureScope((scope) {
      scope.setUser(null);
    });
  }

  Future<void> captureException(
    Object exception, {
    StackTrace? stackTrace,
  }) async {
    if (!isEnabled) return;
    await Sentry.captureException(exception, stackTrace: stackTrace);
  }
}
