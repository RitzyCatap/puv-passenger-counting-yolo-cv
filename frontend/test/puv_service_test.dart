import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend/models/puv_model.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/puv_service.dart';

void main() {
  Map<String, dynamic> samplePuv({
    int id = 1,
    String type = 'Jeepney',
    int capacity = 20,
  }) {
    return {
      'puv_id': id,
      'puv_type': type,
      'capacity': capacity,
      'created_at': '2026-11-28T10:48:31.331985',
    };
  }

  PuvService createService(MockClient client) {
    final apiService = ApiService(client: client);

    final puvService = PuvService(apiService: apiService);

    addTearDown(() {
      puvService.dispose();
      apiService.dispose();
    });

    return puvService;
  }

  group('PUV Service Tests', () {
    // TEST 1
    test('Retrieve multiple PUV records', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/puvs/');

        return http.Response(
          jsonEncode([
            samplePuv(),
            samplePuv(id: 2, type: 'Modern Jeepney', capacity: 30),
          ]),
          200,
        );
      });

      final service = createService(client);
      final records = await service.getPuvs();

      expect(records.length, 2);
      expect(records.first, isA<PuvModel>());
      expect(records.first.puvType, 'Jeepney');
      expect(records.last.puvId, 2);
      expect(records.last.capacity, 30);
    });

    // TEST 2
    test('Retrieve empty PUV records', () async {
      final client = MockClient((request) async {
        return http.Response('[]', 200);
      });

      final service = createService(client);
      final records = await service.getPuvs();

      expect(records, isEmpty);
    });

    // TEST 3
    test('Retrieve specific PUV by ID', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/puvs/1');

        return http.Response(jsonEncode(samplePuv()), 200);
      });

      final service = createService(client);
      final record = await service.getPuvById(1);

      expect(record.puvId, 1);
      expect(record.puvType, 'Jeepney');
      expect(record.capacity, 20);
    });

    // TEST 4
    test('Nonexistent PUV returns API exception', () async {
      final client = MockClient((request) async {
        return http.Response('{"detail":"PUV not found"}', 404);
      });

      final service = createService(client);

      await expectLater(
        service.getPuvById(999999),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', 404)
              .having((error) => error.message, 'message', 'PUV not found'),
        ),
      );
    });

    // TEST 5
    test('Register a new PUV successfully', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/puvs/');

        final body = jsonDecode(request.body);

        expect(body, {'puv_type': 'Jeepney', 'capacity': 25});

        return http.Response(jsonEncode(samplePuv(capacity: 25)), 201);
      });

      final service = createService(client);

      final record = await service.createPuv(puvType: 'Jeepney', capacity: 25);

      expect(record.puvId, 1);
      expect(record.capacity, 25);
    });

    // TEST 6
    test('Registration trims PUV type whitespace', () async {
      final client = MockClient((request) async {
        final body = jsonDecode(request.body);

        expect(body['puv_type'], 'Jeepney');

        return http.Response(jsonEncode(samplePuv()), 201);
      });

      final service = createService(client);

      final record = await service.createPuv(
        puvType: '  Jeepney  ',
        capacity: 20,
      );

      expect(record.puvType, 'Jeepney');
    });

    // TEST 7
    test('Update existing PUV successfully', () async {
      final client = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/puvs/1');

        final body = jsonDecode(request.body);

        expect(body, {'puv_type': 'Modern Jeepney', 'capacity': 30});

        return http.Response(
          jsonEncode(samplePuv(type: 'Modern Jeepney', capacity: 30)),
          200,
        );
      });

      final service = createService(client);

      final record = await service.updatePuv(
        puvId: 1,
        puvType: 'Modern Jeepney',
        capacity: 30,
      );

      expect(record.puvId, 1);
      expect(record.puvType, 'Modern Jeepney');
      expect(record.capacity, 30);
    });

    // TEST 8
    test('Invalid PUV ID is rejected before request', () async {
      final client = MockClient((request) async {
        fail('HTTP request should not be sent.');
      });

      final service = createService(client);

      await expectLater(service.getPuvById(0), throwsArgumentError);
    });

    // TEST 9
    test('Negative PUV ID is rejected', () async {
      final client = MockClient((request) async {
        fail('HTTP request should not be sent.');
      });

      final service = createService(client);

      await expectLater(service.getPuvById(-1), throwsArgumentError);
    });

    // TEST 10
    test('Invalid capacity prevents registration', () async {
      final client = MockClient((request) async {
        fail('HTTP request should not be sent.');
      });

      final service = createService(client);

      await expectLater(
        service.createPuv(puvType: 'Jeepney', capacity: 0),
        throwsArgumentError,
      );
    });

    // TEST 11
    test('Empty PUV type prevents registration', () async {
      final client = MockClient((request) async {
        fail('HTTP request should not be sent.');
      });

      final service = createService(client);

      await expectLater(
        service.createPuv(puvType: '', capacity: 20),
        throwsArgumentError,
      );
    });

    // TEST 12
    test('Invalid update capacity is rejected', () async {
      final client = MockClient((request) async {
        fail('HTTP request should not be sent.');
      });

      final service = createService(client);

      await expectLater(
        service.updatePuv(puvId: 1, puvType: 'Jeepney', capacity: -5),
        throwsArgumentError,
      );
    });

    // TEST 13
    test('Invalid PUV list response is rejected', () async {
      final client = MockClient((request) async {
        return http.Response('{"status":"ok"}', 200);
      });

      final service = createService(client);

      await expectLater(
        service.getPuvs(),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            'Invalid PUV records response.',
          ),
        ),
      );
    });

    // TEST 14
    test('Invalid single PUV response is rejected', () async {
      final client = MockClient((request) async {
        return http.Response('[]', 200);
      });

      final service = createService(client);

      await expectLater(
        service.getPuvById(1),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            'Invalid PUV record response.',
          ),
        ),
      );
    });

    // TEST 15
    test('Invalid PUV field values are rejected', () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode([samplePuv(capacity: 0)]), 200);
      });

      final service = createService(client);

      await expectLater(
        service.getPuvs(),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            'The server returned invalid PUV data.',
          ),
        ),
      );
    });

    // TEST 16
    test('Backend server error is propagated', () async {
      final client = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = createService(client);

      await expectLater(
        service.getPuvs(),
        throwsA(
          isA<ApiException>().having(
            (error) => error.statusCode,
            'statusCode',
            500,
          ),
        ),
      );
    });

    // TEST 17
    test('Network connection failure is handled', () async {
      final client = MockClient((request) async {
        throw http.ClientException('Connection refused');
      });

      final service = createService(client);

      await expectLater(
        service.getPuvs(),
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

    // TEST 18
    test('Unauthorized registration is handled', () async {
      final client = MockClient((request) async {
        return http.Response('{"detail":"Forbidden"}', 403);
      });

      final service = createService(client);

      await expectLater(
        service.createPuv(puvType: 'Jeepney', capacity: 20),
        throwsA(
          isA<ApiException>().having(
            (error) => error.statusCode,
            'statusCode',
            403,
          ),
        ),
      );
    });
  });
}
