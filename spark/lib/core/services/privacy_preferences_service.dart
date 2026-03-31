import 'secure_storage_service.dart';

class PrivacyPreferencesService {
  PrivacyPreferencesService._();

  static final PrivacyPreferencesService instance =
      PrivacyPreferencesService._();

  static const _showDistanceKey = 'privacy_show_distance';
  static const _showActivityKey = 'privacy_show_activity';

  Future<bool> getShowDistance() async {
    return SecureStorageService.instance.readBool(
      _showDistanceKey,
      fallback: true,
    );
  }

  Future<void> setShowDistance(bool value) async {
    await SecureStorageService.instance.writeBool(_showDistanceKey, value);
  }

  Future<bool> getShowActivity() async {
    return SecureStorageService.instance.readBool(
      _showActivityKey,
      fallback: true,
    );
  }

  Future<void> setShowActivity(bool value) async {
    await SecureStorageService.instance.writeBool(_showActivityKey, value);
  }
}
