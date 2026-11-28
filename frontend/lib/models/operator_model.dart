import 'auth_model.dart';

class OperatorModel {
  final AuthUser user;
  final DateTime? createdAt;

  const OperatorModel({required this.user, this.createdAt});

  factory OperatorModel.fromJson(Map<String, dynamic> json) {
    final user = AuthUser.fromJson(json);

    if (!user.isOperator) {
      throw const FormatException('Invalid operator role.');
    }

    final registered = json['created_at'];

    DateTime? createdAt;

    if (registered != null) {
      if (registered is! String) {
        throw const FormatException('Invalid registration date.');
      }

      createdAt = DateTime.tryParse(registered);

      if (createdAt == null) {
        throw const FormatException('Invalid registration date.');
      }
    }

    return OperatorModel(user: user, createdAt: createdAt);
  }

  String get registrationDate {
    final date = createdAt;

    if (date == null) return 'Unavailable';

    final month = date.month.toString().padLeft(2, '0');

    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }
}
