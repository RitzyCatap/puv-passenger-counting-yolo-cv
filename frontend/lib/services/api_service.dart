import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  const ApiException({required this.message, this.statusCode, this.details});

  @override
  String toString() => message;
}

class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  // GET request
  Future<dynamic> get(String path) async {
    return _execute(
      () => _client.get(ApiConfig.endpoint(path), headers: _headers),
    );
  }

  // POST request
  Future<dynamic> post(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    return _execute(
      () => _client.post(
        ApiConfig.endpoint(path),
        headers: _headers,
        body: jsonEncode(body),
      ),
    );
  }

  // PUT request
  Future<dynamic> put(String path, {required Map<String, dynamic> body}) async {
    return _execute(
      () => _client.put(
        ApiConfig.endpoint(path),
        headers: _headers,
        body: jsonEncode(body),
      ),
    );
  }

  // DELETE request
  Future<dynamic> delete(String path) async {
    return _execute(
      () => _client.delete(ApiConfig.endpoint(path), headers: _headers),
    );
  }

  // Execute HTTP request
  Future<dynamic> _execute(Future<http.Response> Function() request) async {
    try {
      final response = await request().timeout(ApiConfig.requestTimeout);

      return _handleResponse(response);
    } on TimeoutException {
      throw const ApiException(
        message: 'The request timed out. Please try again.',
      );
    } on http.ClientException {
      throw const ApiException(
        message:
            'Unable to connect to the server. '
            'Please check your connection.',
      );
    } on FormatException {
      throw const ApiException(
        message: 'The server returned an invalid response.',
      );
    }
  }

  // Handle API responses
  dynamic _handleResponse(http.Response response) {
    dynamic data;

    if (response.bodyBytes.isNotEmpty) {
      try {
        data = jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          throw ApiException(
            message: 'Invalid server response.',
            statusCode: response.statusCode,
          );
        }
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    throw ApiException(
      message: _getErrorMessage(response.statusCode, data),
      statusCode: response.statusCode,
      details: data,
    );
  }

  // Convert HTTP errors into readable messages
  String _getErrorMessage(int statusCode, dynamic data) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';

      case 401:
        return 'Authentication is required.';

      case 403:
        return 'You do not have permission to perform '
            'this action.';

      case 404:
        if (data is Map && data['detail'] is String) {
          return data['detail'] as String;
        }

        return 'The requested record was not found.';

      case 409:
        return 'The request conflicts with an existing '
            'record.';

      case 422:
        return 'Invalid input. Please review the '
            'information provided.';

      case 429:
        return 'Too many requests. Please try again later.';

      case 500:
      case 502:
      case 503:
      case 504:
        return 'A server error occurred. '
            'Please try again later.';

      default:
        return 'Request failed. Please try again. '
            '(HTTP $statusCode)';
    }
  }

  // Backend health check
  Future<bool> checkHealth() async {
    final data = await get(ApiConfig.health);

    return data is Map && data['status'] == 'ok';
  }

  // Database health check
  Future<bool> checkDatabaseHealth() async {
    final data = await get(ApiConfig.databaseHealth);

    return data is Map && data['status'] == 'connected' && data['result'] == 1;
  }

  // Release HTTP client resources
  void dispose() {
    _client.close();
  }
}
