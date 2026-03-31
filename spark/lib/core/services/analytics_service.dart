import 'package:flutter/foundation.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';

import '../constants/app_config.dart';
import 'crash_reporting_service.dart';

class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  Mixpanel? _mixpanel;

  bool get isEnabled => _mixpanel != null;

  Future<void> init() async {
    if (_mixpanel != null || AppConfig.mixpanelToken.isEmpty || kIsWeb) return;

    try {
      _mixpanel = await Mixpanel.init(
        AppConfig.mixpanelToken,
        trackAutomaticEvents: false,
      );
    } catch (e, stackTrace) {
      debugPrint('[Mixpanel] Init error: $e');
      await CrashReportingService.instance.captureException(
        e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> identifyUser({
    required String userId,
    String? email,
  }) async {
    final mixpanel = _mixpanel;
    if (mixpanel == null) return;

    mixpanel.identify(userId);
    if (email != null && email.isNotEmpty) {
      mixpanel.getPeople().set(r'$email', email);
    }
  }

  Future<void> clearUser() async {
    final mixpanel = _mixpanel;
    if (mixpanel == null) return;
    mixpanel.reset();
  }

  Future<void> track(
    String eventName, {
    Map<String, Object?>? properties,
  }) async {
    final mixpanel = _mixpanel;
    if (mixpanel == null) return;

    final safeProperties = <String, dynamic>{};
    properties?.forEach((key, value) {
      if (value == null || value is num || value is bool || value is String) {
        safeProperties[key] = value;
      } else {
        safeProperties[key] = value.toString();
      }
    });

    mixpanel.track(eventName, properties: safeProperties);
  }
}
