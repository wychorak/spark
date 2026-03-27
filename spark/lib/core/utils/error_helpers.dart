import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:spark/core/constants/app_strings.dart';

/// Converts a Supabase/Auth exception into a user-friendly Polish message.
String friendlyAuthError(Object error) {
  if (error is AuthException) {
    final code = error.code?.toLowerCase() ?? '';
    final msg = error.message.toLowerCase();

    if (code == 'invalid_credentials' || msg.contains('invalid login credentials')) {
      return AppStrings.errorInvalidCredentials;
    }
    if (code == 'user_already_exists' || msg.contains('already registered')) {
      return AppStrings.errorEmailTaken;
    }
    if (code == 'over_request_rate_limit' || msg.contains('rate limit')) {
      return AppStrings.errorTooManyRequests;
    }
    if (code == 'email_not_confirmed' || msg.contains('email not confirmed')) {
      return AppStrings.errorEmailNotConfirmed;
    }
    if (code == 'user_not_found' || msg.contains('user not found')) {
      return AppStrings.errorUserNotFound;
    }
    if (code == 'weak_password' || msg.contains('weak password')) {
      return AppStrings.errorWeakPassword;
    }
    if (msg.contains('network') || msg.contains('socket')) {
      return AppStrings.errorNetwork;
    }
  }

  final str = error.toString().toLowerCase();
  if (str.contains('invalid_credentials') || str.contains('invalid login')) {
    return AppStrings.errorInvalidCredentials;
  }
  if (str.contains('already registered') || str.contains('user_already_exists')) {
    return AppStrings.errorEmailTaken;
  }
  if (str.contains('network') || str.contains('socketexception')) {
    return AppStrings.errorNetwork;
  }
  if (str.contains('timeout')) {
    return AppStrings.errorTimeout;
  }

  return AppStrings.errorGeneral;
}
