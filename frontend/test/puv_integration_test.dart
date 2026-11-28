import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend/models/puv_model.dart';
import 'package:frontend/models/puv_summary.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/puv_service.dart';

void main() {
  const records = [
    PuvModel(puvId: 1, puvType: 'Jeepney', capacity: 20),
    PuvModel(puvId: 2, puvType: 'jeepney', capacity: 25),
    PuvModel(puvId: 3, puvType: 'Bus', capacity: 40),
  ];

  test('Counts all registered vehicles', () {
    final summary = PuvSummary.fromRecords(records);

    expect(summary.registeredCount, 3);
  });

  test('Counts normalized vehicle categories', () {
    final summary = PuvSummary.fromRecords(records);

    expect(summary.vehicleTypeCount, 2);
  });

  test('Calculates actual total capacity', () {
    final summary = PuvSummary.fromRecords(records);

    expect(summary.totalCapacity, 85);
  });

  test('Empty records produce zero statistics', () {
    final summary = PuvSummary.fromRecords([]);

    expect(summary.registeredCount, 0);
    expect(summary.vehicleTypeCount, 0);
    expect(summary.totalCapacity, 0);
  });

  test('Search is case insensitive', () {
    expect(PuvSummary.search(records, 'JEEPNEY').length, 2);
  });

  test('Search accepts vehicle ID', () {
    expect(PuvSummary.search(records, '3').single.puvType, 'Bus');
  });

  test('Search trims whitespace', () {
    expect(PuvSummary.search(records, ' Bus ').length, 1);
  });

  test('Empty search returns all records', () {
    expect(PuvSummary.search(records, '').length, 3);
  });

  test('Unknown search returns no records', () {
    expect(PuvSummary.search(records, 'Unknown'), isEmpty);
  });

  test('Formats registration date', () {
    expect(PuvSummary.registrationDate(DateTime(2026, 11, 28)), '2026-11-28');
  });

  test('Handles unavailable registration date', () {
    expect(PuvSummary.registrationDate(null), 'Unavailable');
  });

  PuvService createService(MockClient client) {
    final api = ApiService(client: client);
    final service = PuvService(apiService: api);

    addTearDown(() {
      service.dispose();
      api.dispose();
    });

    return service;
  }

  test('PUV listing sends bearer token', () async {
    final service = createService(
      MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer test-token');
        expect(request.method, 'GET');

        return http.Response('[]', 200);
      }),
    );

    await service.getPuvs(accessToken: 'test-token');
  });

  test('PUV details send bearer token', () async {
    final service = createService(
      MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer test-token');

        expect(request.url.path, '/puvs/1');

        return http.Response(jsonEncode(records.first.toJson()), 200);
      }),
    );

    await service.getPuvById(1, accessToken: 'test-token');
  });

  test('PUV registration sends bearer token', () async {
    final service = createService(
      MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer test-token');

        expect(request.method, 'POST');

        return http.Response(jsonEncode(records.first.toJson()), 201);
      }),
    );

    await service.createPuv(
      puvType: 'Jeepney',
      capacity: 20,
      accessToken: 'test-token',
    );
  });

  test('PUV update sends bearer token', () async {
    final service = createService(
      MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer test-token');

        expect(request.method, 'PUT');

        return http.Response(jsonEncode(records.first.toJson()), 200);
      }),
    );

    await service.updatePuv(
      puvId: 1,
      puvType: 'Jeepney',
      capacity: 20,
      accessToken: 'test-token',
    );
  });

  test('Expired token preserves HTTP 401', () async {
    final service = createService(
      MockClient((request) async {
        return http.Response('{"detail":"Unauthorized"}', 401);
      }),
    );

    await expectLater(
      service.getPuvs(accessToken: 'expired-token'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.statusCode,
          'statusCode',
          401,
        ),
      ),
    );
  });

  test('Forbidden update preserves HTTP 403', () async {
    final service = createService(
      MockClient((request) async {
        return http.Response('{"detail":"Forbidden"}', 403);
      }),
    );

    await expectLater(
      service.updatePuv(
        puvId: 1,
        puvType: 'Bus',
        capacity: 40,
        accessToken: 'operator-token',
      ),
      throwsA(
        isA<ApiException>().having(
          (error) => error.statusCode,
          'statusCode',
          403,
        ),
      ),
    );
  });
}
