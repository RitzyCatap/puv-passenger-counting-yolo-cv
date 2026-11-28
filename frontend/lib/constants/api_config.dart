import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }

    if (!kDebugMode) {
      throw StateError('API_BASE_URL must be configured for production.');
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }

    return 'http://127.0.0.1:8000';
  }

  static const Duration requestTimeout = Duration(seconds: 30);

  static const Duration detectionTimeout = Duration(seconds: 120);

  // Existing verified backend endpoints.
  static const String health = '/health';
  static const String databaseHealth = '/db-health';
  static const String puvs = '/puvs/';
  static const String login = '/api/auth/login';
  static const String currentUser = '/api/auth/me';
  static const String logout = '/api/auth/logout';
  static const String operators = '/api/auth/operators';

  static String puvById(int puvId) {
    return '/puvs/$puvId';
  }

  static Uri endpoint(String path) {
    final normalizedBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final normalizedPath = path.startsWith('/') ? path : '/$path';

    return Uri.parse('$normalizedBaseUrl$normalizedPath');
  }
}
