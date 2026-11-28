import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/models/puv_model.dart';

void main() {
  Map<String, dynamic> validJson() {
    return {
      'puv_id': 1,
      'puv_type': 'Jeepney',
      'capacity': 20,
      'created_at': '2026-11-28T10:48:31.331985',
    };
  }

  group('PUV Model Tests', () {
    // TEST 1
    test('Valid JSON creates correct PUV model', () {
      final puv = PuvModel.fromJson(validJson());

      expect(puv.puvId, 1);
      expect(puv.puvType, 'Jeepney');
      expect(puv.capacity, 20);
      expect(puv.createdAt, DateTime.parse('2026-11-28T10:48:31.331985'));
    });

    // TEST 2
    test('Model converts correctly to JSON', () {
      final puv = PuvModel.fromJson(validJson());
      final json = puv.toJson();

      expect(json['puv_id'], 1);
      expect(json['puv_type'], 'Jeepney');
      expect(json['capacity'], 20);
      expect(json['created_at'], '2026-11-28T10:48:31.331985');
    });

    // TEST 3
    test('Null creation date is supported', () {
      final json = validJson();
      json['created_at'] = null;

      final puv = PuvModel.fromJson(json);

      expect(puv.createdAt, isNull);
      expect(puv.toJson()['created_at'], isNull);
    });

    // TEST 4
    test('Missing creation date is supported', () {
      final json = validJson();
      json.remove('created_at');

      final puv = PuvModel.fromJson(json);

      expect(puv.createdAt, isNull);
    });

    // TEST 5
    test('Zero PUV ID is rejected', () {
      final json = validJson();
      json['puv_id'] = 0;

      expect(() => PuvModel.fromJson(json), throwsA(isA<FormatException>()));
    });

    // TEST 6
    test('Invalid PUV ID type is rejected', () {
      final json = validJson();
      json['puv_id'] = '1';

      expect(() => PuvModel.fromJson(json), throwsA(isA<FormatException>()));
    });

    // TEST 7
    test('Empty PUV type is rejected', () {
      final json = validJson();
      json['puv_type'] = '';

      expect(() => PuvModel.fromJson(json), throwsA(isA<FormatException>()));
    });

    // TEST 8
    test('Whitespace-only PUV type is rejected', () {
      final json = validJson();
      json['puv_type'] = '   ';

      expect(() => PuvModel.fromJson(json), throwsA(isA<FormatException>()));
    });

    // TEST 9
    test('Invalid capacity is rejected', () {
      final json = validJson();
      json['capacity'] = 0;

      expect(() => PuvModel.fromJson(json), throwsA(isA<FormatException>()));
    });

    // TEST 10
    test('Non-integer capacity is rejected', () {
      final json = validJson();
      json['capacity'] = '20';

      expect(() => PuvModel.fromJson(json), throwsA(isA<FormatException>()));
    });

    // TEST 11
    test('Invalid creation date is rejected', () {
      final json = validJson();
      json['created_at'] = 'invalid-date';

      expect(() => PuvModel.fromJson(json), throwsA(isA<FormatException>()));
    });

    // TEST 12
    test('Invalid creation date type is rejected', () {
      final json = validJson();
      json['created_at'] = 12345;

      expect(() => PuvModel.fromJson(json), throwsA(isA<FormatException>()));
    });

    // TEST 13
    test('Request body contains correct fields', () {
      final body = PuvModel.requestBody(
        puvType: 'Modern Jeepney',
        capacity: 30,
      );

      expect(body, {'puv_type': 'Modern Jeepney', 'capacity': 30});

      expect(body.containsKey('puv_id'), isFalse);
      expect(body.containsKey('created_at'), isFalse);
    });

    // TEST 14
    test('Request body trims unnecessary whitespace', () {
      final body = PuvModel.requestBody(puvType: '  Jeepney  ', capacity: 20);

      expect(body['puv_type'], 'Jeepney');
    });

    // TEST 15
    test('Empty request PUV type is rejected', () {
      expect(
        () => PuvModel.requestBody(puvType: '', capacity: 20),
        throwsArgumentError,
      );
    });

    // TEST 16
    test('PUV type with exactly 50 characters is accepted', () {
      final type = List.filled(50, 'A').join();

      final body = PuvModel.requestBody(puvType: type, capacity: 20);

      expect(body['puv_type'], type);
    });

    // TEST 17
    test('PUV type exceeding 50 characters is rejected', () {
      final type = List.filled(51, 'A').join();

      expect(
        () => PuvModel.requestBody(puvType: type, capacity: 20),
        throwsArgumentError,
      );
    });

    // TEST 18
    test('Zero request capacity is rejected', () {
      expect(
        () => PuvModel.requestBody(puvType: 'Jeepney', capacity: 0),
        throwsArgumentError,
      );
    });

    // TEST 19
    test('Negative request capacity is rejected', () {
      expect(
        () => PuvModel.requestBody(puvType: 'Jeepney', capacity: -5),
        throwsArgumentError,
      );
    });

    // TEST 20
    test('Capacity exceeding integer limit is rejected', () {
      expect(
        () => PuvModel.requestBody(puvType: 'Jeepney', capacity: 2147483648),
        throwsArgumentError,
      );
    });

    // TEST 21
    test('Maximum supported capacity is accepted', () {
      final body = PuvModel.requestBody(
        puvType: 'Jeepney',
        capacity: 2147483647,
      );

      expect(body['capacity'], 2147483647);
    });

    // TEST 22
    test('copyWith updates selected PUV properties', () {
      final original = PuvModel.fromJson(validJson());

      final updated = original.copyWith(
        puvType: 'Modern Jeepney',
        capacity: 30,
      );

      expect(updated.puvId, original.puvId);
      expect(updated.puvType, 'Modern Jeepney');
      expect(updated.capacity, 30);
      expect(updated.createdAt, original.createdAt);

      expect(original.puvType, 'Jeepney');
      expect(original.capacity, 20);
    });
  });
}
