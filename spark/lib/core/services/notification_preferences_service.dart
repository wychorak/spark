import 'secure_storage_service.dart';

class NotificationPreferencesService {
  NotificationPreferencesService._();

  static final NotificationPreferencesService instance =
      NotificationPreferencesService._();

  static const _matchesKey = 'notify_matches';
  static const _messagesKey = 'notify_messages';
  static const _superlikesKey = 'notify_superlikes';
  static const _marketingKey = 'notify_marketing';

  Future<bool> isEnabledForType(String type) async {
    switch (type) {
      case 'new_match':
        return SecureStorageService.instance.readBool(_matchesKey, fallback: true);
      case 'new_message':
        return SecureStorageService.instance.readBool(_messagesKey, fallback: true);
      case 'super_like':
      case 'superlike':
        return SecureStorageService.instance.readBool(
          _superlikesKey,
          fallback: true,
        );
      case 'marketing':
        return SecureStorageService.instance.readBool(
          _marketingKey,
          fallback: false,
        );
      default:
        return true;
    }
  }

  Future<void> setMatchesEnabled(bool value) async {
    await SecureStorageService.instance.writeBool(_matchesKey, value);
  }

  Future<void> setMessagesEnabled(bool value) async {
    await SecureStorageService.instance.writeBool(_messagesKey, value);
  }

  Future<void> setSuperlikesEnabled(bool value) async {
    await SecureStorageService.instance.writeBool(_superlikesKey, value);
  }

  Future<void> setMarketingEnabled(bool value) async {
    await SecureStorageService.instance.writeBool(_marketingKey, value);
  }

  Future<bool> getMatchesEnabled() async {
    return SecureStorageService.instance.readBool(_matchesKey, fallback: true);
  }

  Future<bool> getMessagesEnabled() async {
    return SecureStorageService.instance.readBool(_messagesKey, fallback: true);
  }

  Future<bool> getSuperlikesEnabled() async {
    return SecureStorageService.instance.readBool(_superlikesKey, fallback: true);
  }

  Future<bool> getMarketingEnabled() async {
    return SecureStorageService.instance.readBool(_marketingKey, fallback: false);
  }
}
