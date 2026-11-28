import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend/services/api_service.dart';

void main() {
  group('API Service Tests', () {
    // TEST 1
    test('GET request returns decoded JSON', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/health');

        return http.Response('{"status":"ok"}', 200);
      });

      final service = ApiService(client: client);
      addTearDown(service.dispose);

      final result = await service.get('/health');

      expect(result['status'], 'ok');
    });

    // TEST 2
    test('POST request sends correct JSON body', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/puvs/');

        final body = jsonDecode(request.body);

        expect(body['puv_type'], 'Jeepney');
        expect(body['capacity'], 20);

        return http.Response(
          '{"puv_id":1,"puv_type":"Jeepney","capacity":20}',
          201,
        );
      });

      final service = ApiService(client: client);
      addTearDown(service.dispose);

      final result = await service.post(
        '/puvs/',
        body: {'puv_type': 'Jeepney', 'capacity': 20},
      );

      expect(result['puv_id'], 1);
      expect(result['capacity'], 20);
    });

    // TEST 3
    test('PUT request sends updated JSON body', () async {
      final client = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/puvs/1');

        final body = jsonDecode(request.body);

        expect(body['puv_type'], 'Modern Jeepney');
        expect(body['capacity'], 30);

        return http.Response(
          '{"puv_id":1,"puv_type":"Modern Jeepney",'
          '"capacity":30}',
          200,
        );
      });

      final service = ApiService(client: client);
      addTearDown(service.dispose);

      final result = await service.put(
        '/puvs/1',
        body: {'puv_type': 'Modern Jeepney', 'capacity': 30},
      );

      expect(result['capacity'], 30);
    });

    // TEST 4
    test('DELETE request handles successful response', () async {
      final client = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/puvs/1');

        return http.Response('{"message":"PUV deleted successfully"}', 200);
      });

      final service = ApiService(client: client);
      addTearDown(service.dispose);

      final result = await service.delete('/puvs/1');

      expect(result['message'], 'PUV deleted successfully');
    });

    // TEST 5
    test('Backend health check returns true', () async {
      final client = MockClient((request) async {
        return http.Response('{"status":"ok"}', 200);
      });

      final service = ApiService(client: client);
      addTearDown(service.dispose);

      expect(await service.checkHealth(), isTrue);
    });

    // TEST 6
    test('Unexpected health response returns false', () async {
      final client = MockClient((request) async {
        return http.Response('{"status":"error"}', 200);
      });

      final service = ApiService(client: client);
      addTearDown(service.dispose);

      expect(await service.checkHealth(), isFalse);
    });

    // TEST 7
    test('Database health check returns true', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/db-health');

        return http.Response(
          '{"status":"connected",'
          '"database":"PostgreSQL","result":1}',
          200,
        );
      });

      final service = ApiService(client: client);
      addTearDown(service.dispose);

      expect(await service.checkDatabaseHealth(), isTrue);
    });

    // TEST 8
    test('Database connection failure returns false', () async {
      final client = MockClient((request) async {
        return http.Response(
          '{"status":"error",'
          '"message":"Database connection failed"}',
          200,
        );
      });

      final service = ApiService(client: client);
      addTearDown(service.dispose);

      expect(await service.checkDatabaseHealth(), isFalse);
    });

    // TEST 9
    test('404 response produces appropriate exception', () async {
      final client = MockClient((request) async {
        return http.Response('{"detail":"PUV not found"}', 404);
      });

      final service = ApiService(client: client);
      addTearDown(service.dispose);

      await expectLater(
        service.get('/puvs/999999'),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', 404)
              .having((error) => error.message, 'message', 'PUV not found'),
        ),
      );
    });

    // TEST 10
    test('422 response handles invalid input', () async {
      final client = MockClient((request) async {
        return http.Response('{"detail":[{"msg":"Invalid capacity"}]}', 422);
      });

      final service = ApiService(client: client);
      addTearDown(service.dispose);

      await expectLater(
        service.post('/puvs/', body: {'puv_type': 'Jeepney', 'capacity': 0}),
        throwsA(
          isA<ApiException>().having(
            (error) => error.statusCode,
            'statusCode',
            422,
          ),
        ),
      );
    });

    // TEST 11
    test('500 response handles server errors', () async {
      final client = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = ApiService(client: client);
      addTearDown(service.dispose);

      await expectLater(
        service.get('/puvs/'),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', 500)
              .having(
                (error) => error.message,
                'message',
                'A server error occurred. '
                    'Please try again later.',
              ),
        ),
      );
    });

    // TEST 12
    test('Invalid JSON response is rejected', () async {
      final client = MockClient((request) async {
        return http.Response('Invalid JSON response', 200);
      });

      final service = ApiService(client: client);
      addTearDown(service.dispose);

      await expectLater(service.get('/health'), throwsA(isA<ApiException>()));
    });

    // TEST 13
    test('Network connection error is handled', () async {
      final client = MockClient((request) async {
        throw http.ClientException('Connection refused');
      });

      final service = ApiService(client: client);
      addTearDown(service.dispose);

      await expectLater(
        service.get('/health'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            'Unable to connect to the server. '
                'Please check your connection.',
          ),
        ),
      );
    });

    // TEST 14
    test('401 response handles authentication errors', () async {
      final client = MockClient((request) async {
        return http.Response('{"detail":"Unauthorized"}', 401);
      });

      final service = ApiService(client: client);
      addTearDown(service.dispose);

      await expectLater(
        service.get('/health'),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', 401)
              .having(
                (error) => error.message,
                'message',
                'Authentication is required.',
              ),
        ),
      );
    });

    // TEST 15
    test('403 response handles permission errors', () async {
      final client = MockClient((request) async {
        return http.Response('{"detail":"Forbidden"}', 403);
      });

      final service = ApiService(client: client);
      addTearDown(service.dispose);

      await expectLater(
        service.get('/health'),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', 403)
              .having(
                (error) => error.message,
                'message',
                'You do not have permission to perform '
                    'this action.',
              ),
        ),
      );
    });

    // TEST 16
    test('Empty successful response returns null', () async {
      final client = MockClient((request) async {
        return http.Response('', 204);
      });

      final service = ApiService(client: client);
      addTearDown(service.dispose);

      final result = await service.delete('/puvs/1');

      expect(result, isNull);
    });
  });
}
