import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend/models/auth_model.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/session_manager.dart';

void main() {
  Map<String, dynamic> userJson({String role = 'admin'}) {
    return {
      'user_id': 2,
      'full_name': 'Test User',
      'email': 'admin@example.com',
      'role': role,
    };
  }

  Map<String, dynamic> sessionJson({String role = 'admin'}) {
    return {
      'access_token': 'mock-test-token',
      'token_type': 'bearer',
      'expires_in': 1800,
      'user': userJson(role: role),
    };
  }

  AuthService createService(MockClient client) {
    final api = ApiService(client: client);
    final auth = AuthService(apiService: api);

    addTearDown(() {
      auth.dispose();
      api.dispose();
    });

    return auth;
  }

  group('Authentication foundation', () {
    test('Admin user model is parsed correctly', () {
      final user = AuthUser.fromJson(userJson());

      expect(user.userId, 2);
      expect(user.isAdmin, isTrue);
      expect(user.isOperator, isFalse);
    });

    test('Operator user model is parsed correctly', () {
      final user = AuthUser.fromJson(userJson(role: 'operator'));

      expect(user.isOperator, isTrue);
      expect(user.isAdmin, isFalse);
    });

    test('Unsupported user role is rejected', () {
      expect(
        () => AuthUser.fromJson(userJson(role: 'unknown')),
        throwsFormatException,
      );
    });

    test('Invalid user ID is rejected', () {
      final json = userJson();
      json['user_id'] = 0;

      expect(() => AuthUser.fromJson(json), throwsFormatException);
    });

    test('Valid session response is parsed', () {
      final session = AuthSession.fromJson(sessionJson());

      expect(session.accessToken, 'mock-test-token');
      expect(session.user.isAdmin, isTrue);
      expect(session.isExpired, isFalse);
    });

    test('Missing access token is rejected', () {
      final json = sessionJson();
      json.remove('access_token');

      expect(() => AuthSession.fromJson(json), throwsFormatException);
    });

    test('Invalid token type is rejected', () {
      final json = sessionJson();
      json['token_type'] = 'refresh';

      expect(() => AuthSession.fromJson(json), throwsFormatException);
    });

    test('Invalid session duration is rejected', () {
      final json = sessionJson();
      json['expires_in'] = 0;

      expect(() => AuthSession.fromJson(json), throwsFormatException);
    });

    test('Login sends correct request data', () async {
      final auth = createService(
        MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/auth/login');

          expect(jsonDecode(request.body), {
            'email': 'admin@example.com',
            'password': 'TestPassword!',
          });

          expect(request.headers['authorization'], isNull);

          return http.Response(jsonEncode(sessionJson()), 200);
        }),
      );

      final session = await auth.login(
        email: ' ADMIN@EXAMPLE.COM ',
        password: 'TestPassword!',
      );

      expect(session.user.isAdmin, isTrue);
    });

    test('Incorrect credentials are handled', () async {
      final auth = createService(
        MockClient((request) async {
          return http.Response('{"detail":"Invalid email or password."}', 401);
        }),
      );

      await expectLater(
        auth.login(email: 'admin@example.com', password: 'incorrect'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            'Invalid email or password.',
          ),
        ),
      );
    });

    test('Empty credentials prevent HTTP requests', () async {
      final auth = createService(
        MockClient((request) async {
          fail('HTTP request should not be sent.');
        }),
      );

      await expectLater(
        auth.login(email: '', password: ''),
        throwsA(isA<ApiException>()),
      );
    });

    test('Malformed login response is rejected', () async {
      final auth = createService(
        MockClient((request) async {
          return http.Response('[]', 200);
        }),
      );

      await expectLater(
        auth.login(email: 'admin@example.com', password: 'TestPassword!'),
        throwsA(isA<ApiException>()),
      );
    });

    test('Current user request includes bearer token', () async {
      final auth = createService(
        MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/api/auth/me');

          expect(request.headers['authorization'], 'Bearer mock-test-token');

          return http.Response(jsonEncode(userJson()), 200);
        }),
      );

      final user = await auth.getCurrentUser('mock-test-token');

      expect(user.isAdmin, isTrue);
    });

    test('New session manager is unauthenticated', () {
      final manager = SessionManager();
      addTearDown(manager.dispose);

      expect(manager.isAuthenticated, isFalse);
      expect(manager.accessToken, isNull);
      expect(manager.user, isNull);
    });

    test('Admin session can be established', () {
      final manager = SessionManager();
      addTearDown(manager.dispose);

      manager.startSession(AuthSession.fromJson(sessionJson()));

      expect(manager.isAuthenticated, isTrue);
      expect(manager.isAdmin, isTrue);
      expect(manager.accessToken, 'mock-test-token');
    });

    test('Operator session preserves correct role', () {
      final manager = SessionManager();
      addTearDown(manager.dispose);

      manager.startSession(AuthSession.fromJson(sessionJson(role: 'operator')));

      expect(manager.isOperator, isTrue);
      expect(manager.isAdmin, isFalse);
    });

    test('Clear session removes account and token', () {
      final manager = SessionManager();
      addTearDown(manager.dispose);

      manager.startSession(AuthSession.fromJson(sessionJson()));

      manager.clearSession();

      expect(manager.isAuthenticated, isFalse);
      expect(manager.accessToken, isNull);
      expect(manager.user, isNull);
    });

    test('Expired session cannot be established', () {
      final manager = SessionManager();
      addTearDown(manager.dispose);

      final session = AuthSession(
        accessToken: 'expired-test-token',
        expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
        user: AuthUser.fromJson(userJson()),
      );

      expect(() => manager.startSession(session), throwsStateError);

      expect(manager.isAuthenticated, isFalse);
    });

    test('Session changes notify listeners', () {
      final manager = SessionManager();
      addTearDown(manager.dispose);

      int notifications = 0;

      manager.addListener(() {
        notifications++;
      });

      manager.startSession(AuthSession.fromJson(sessionJson()));

      manager.clearSession();

      expect(notifications, 2);
    });

    test('Session automatically expires', () async {
      final manager = SessionManager();
      addTearDown(manager.dispose);

      manager.startSession(
        AuthSession(
          accessToken: 'temporary-test-token',
          expiresAt: DateTime.now().add(const Duration(milliseconds: 100)),
          user: AuthUser.fromJson(userJson()),
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect(manager.isAuthenticated, isFalse);
      expect(manager.accessToken, isNull);
      expect(manager.user, isNull);
    });
  });
}
