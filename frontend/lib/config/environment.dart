import 'package:flutter/foundation.dart';

enum Environment { development, production }

class EnvironmentConfig {
  static Environment get current {
    if (kDebugMode) {
      return Environment.development;
    } else {
      return Environment.production;
    }
  }

  static String get _baseApiUrl {
    switch (current) {
      case Environment.development:
        return 'http://localhost:8080/api/v1';
      case Environment.production:
        return 'https://todo.ibotcloud.top/api/v1';
    }
  }

  static String get _baseFrontendUrl {
    switch (current) {
      case Environment.development:
        return 'https://todo.ibotcloud.top';
      case Environment.production:
        return 'https://todo.ibotcloud.top';
    }
  }

  static String get apiBaseUrl => _effectiveBackendUrl;
  static String get frontendBaseUrl => _effectiveFrontendUrl;

  static String get appleServiceId {
    switch (current) {
      case Environment.development:
        return 'top.ibotcloud.todo.service';
      case Environment.production:
        return 'top.ibotcloud.todo.service';
    }
  }

  static String get appleRedirectUri {
    return '$frontendBaseUrl/auth/apple/callback';
  }

  // Development helper to easily switch to ngrok URLs
  static void setDevelopmentUrls({
    required String frontendNgrokUrl,
    required String backendNgrokUrl,
  }) {
    if (current == Environment.development) {
      _devFrontendUrl = frontendNgrokUrl;
      _devBackendUrl = '$backendNgrokUrl/api/v1';
      debugPrint('🔗 Development URLs updated:');
      debugPrint('   Frontend: $frontendNgrokUrl');
      debugPrint('   Backend: $backendNgrokUrl/api/v1');
    }
  }

  // Reset to default URLs
  static void resetDevelopmentUrls() {
    _devFrontendUrl = null;
    _devBackendUrl = null;
    debugPrint('🔄 Reset to default development URLs');
  }

  // Private variables for ngrok URLs
  static String? _devFrontendUrl;
  static String? _devBackendUrl;

  // Effective URLs (use ngrok if set, otherwise use base URLs)
  static String get _effectiveFrontendUrl =>
      _devFrontendUrl ?? _baseFrontendUrl;
  static String get _effectiveBackendUrl => _devBackendUrl ?? _baseApiUrl;
}
