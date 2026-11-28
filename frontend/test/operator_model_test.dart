import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/operator_model.dart';

void main() {
  Map<String, dynamic> validOperator() {
    return {
      'user_id': 5,
      'full_name': 'Test Operator',
      'email': 'operator@example.com',
      'role': 'operator',
      'created_at': '2026-11-28T12:00:00',
    };
  }

  test('Parses a valid operator', () {
    final result = OperatorModel.fromJson(validOperator());

    expect(result.user.userId, 5);
    expect(result.user.isOperator, isTrue);
  });

  test('Formats registration date', () {
    final result = OperatorModel.fromJson(validOperator());

    expect(result.registrationDate, '2026-11-28');
  });

  test('Rejects non-operator roles', () {
    final json = validOperator();
    json['role'] = 'admin';

    expect(() => OperatorModel.fromJson(json), throwsFormatException);
  });

  test('Accepts missing registration date', () {
    final json = validOperator();
    json.remove('created_at');

    final result = OperatorModel.fromJson(json);

    expect(result.registrationDate, 'Unavailable');
  });

  test('Rejects malformed registration date', () {
    final json = validOperator();
    json['created_at'] = 'invalid';

    expect(() => OperatorModel.fromJson(json), throwsFormatException);
  });

  test('Rejects missing operator identity', () {
    final json = validOperator();
    json.remove('user_id');

    expect(() => OperatorModel.fromJson(json), throwsFormatException);
  });
}
