class PuvModel {
  final int puvId;
  final String puvType;
  final int capacity;
  final DateTime? createdAt;

  const PuvModel({
    required this.puvId,
    required this.puvType,
    required this.capacity,
    this.createdAt,
  });

  // Convert backend JSON into a Flutter object.
  factory PuvModel.fromJson(Map<String, dynamic> json) {
    final puvId = json['puv_id'];
    final puvType = json['puv_type'];
    final capacity = json['capacity'];
    final createdAt = json['created_at'];

    if (puvId is! int || puvId <= 0) {
      throw const FormatException('Invalid PUV ID.');
    }

    if (puvType is! String || puvType.trim().isEmpty) {
      throw const FormatException('Invalid PUV type.');
    }

    if (capacity is! int || capacity <= 0) {
      throw const FormatException('Invalid PUV capacity.');
    }

    DateTime? parsedCreatedAt;

    if (createdAt != null) {
      if (createdAt is! String) {
        throw const FormatException('Invalid PUV creation date.');
      }

      parsedCreatedAt = DateTime.tryParse(createdAt);

      if (parsedCreatedAt == null) {
        throw const FormatException('Invalid PUV creation date.');
      }
    }

    return PuvModel(
      puvId: puvId,
      puvType: puvType,
      capacity: capacity,
      createdAt: parsedCreatedAt,
    );
  }

  // Convert the Flutter object into JSON.
  Map<String, dynamic> toJson() {
    return {
      'puv_id': puvId,
      'puv_type': puvType,
      'capacity': capacity,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  // Prepare the request body for registration or updates.
  static Map<String, dynamic> requestBody({
    required String puvType,
    required int capacity,
  }) {
    final normalizedType = puvType.trim();

    if (normalizedType.isEmpty) {
      throw ArgumentError('PUV type is required.');
    }

    if (normalizedType.runes.length > 50) {
      throw ArgumentError('PUV type must not exceed 50 characters.');
    }

    if (capacity <= 0) {
      throw ArgumentError('Capacity must be greater than zero.');
    }

    if (capacity > 2147483647) {
      throw ArgumentError('Capacity exceeds the supported limit.');
    }

    return {'puv_type': normalizedType, 'capacity': capacity};
  }

  // Create an updated copy of an existing PUV.
  PuvModel copyWith({String? puvType, int? capacity}) {
    return PuvModel(
      puvId: puvId,
      puvType: puvType ?? this.puvType,
      capacity: capacity ?? this.capacity,
      createdAt: createdAt,
    );
  }
}
