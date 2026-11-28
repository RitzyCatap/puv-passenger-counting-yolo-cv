import '../constants/api_config.dart';
import '../models/auth_model.dart';
import '../models/operator_model.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService;
  final bool _ownsApiService;

  AuthService({ApiService? apiService})
    : _apiService = apiService ?? ApiService(),
      _ownsApiService = apiService == null;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedEmail.isEmpty || password.isEmpty) {
      throw const ApiException(
        message: 'Please enter your email and password.',
      );
    }

    if (normalizedEmail.length > 150 || password.length > 128) {
      throw const ApiException(
        message: 'Email or password exceeds the allowed length.',
      );
    }

    try {
      final data = await _apiService.post(
        ApiConfig.login,
        body: {'email': normalizedEmail, 'password': password},
      );

      if (data is! Map<String, dynamic>) {
        throw const FormatException('Invalid authentication response.');
      }

      return AuthSession.fromJson(data);
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        throw const ApiException(
          message: 'Invalid email or password.',
          statusCode: 401,
        );
      }

      rethrow;
    } on FormatException {
      throw const ApiException(message: 'Invalid authentication response.');
    }
  }

  Future<AuthUser> getCurrentUser(String accessToken) async {
    if (accessToken.isEmpty) {
      throw const ApiException(
        message: 'Authentication is required.',
        statusCode: 401,
      );
    }

    final data = await _apiService.get(
      ApiConfig.currentUser,
      accessToken: accessToken,
    );

    try {
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Invalid account response.');
      }

      return AuthUser.fromJson(data);
    } on FormatException {
      throw const ApiException(message: 'Invalid account information.');
    }
  }

  Future<void> logout(String accessToken) async {
    await _apiService.post(
      ApiConfig.logout,
      body: {},
      accessToken: accessToken,
    );
  }

  Future<AuthUser> createOperator({
    required String accessToken,
    required String fullName,
    required String email,
    required String password,
  }) async {
    final data = await _apiService.post(
      ApiConfig.operators,
      accessToken: accessToken,
      body: {
        'full_name': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );

    try {
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Invalid account response.');
      }

      return OperatorModel.fromJson(data).user;
    } on FormatException {
      throw const ApiException(message: 'Invalid account response.');
    }
  }

  Future<List<OperatorModel>> getOperators(String accessToken) async {
    final data = await _apiService.get(
      ApiConfig.operators,
      accessToken: accessToken,
    );

    if (data is! List) {
      throw const ApiException(message: 'Invalid account list.');
    }

    return data.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const ApiException(message: 'Invalid account information.');
      }

      return OperatorModel.fromJson(item);
    }).toList();
  }

  void dispose() {
    if (_ownsApiService) {
      _apiService.dispose();
    }
  }
}
