class AppConfig {
  AppConfig._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const revenueCatKey = String.fromEnvironment('REVENUECAT_KEY');
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  static const mixpanelToken = String.fromEnvironment('MIXPANEL_TOKEN');

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
