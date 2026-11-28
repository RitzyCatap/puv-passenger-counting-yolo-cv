import '../constants/api_config.dart';
import '../models/puv_model.dart';
import 'api_service.dart';

class PuvService {
  final ApiService _apiService;
  final bool _ownsApiService;

  PuvService({ApiService? apiService})
    : _apiService = apiService ?? ApiService(),
      _ownsApiService = apiService == null;

  // Retrieve all registered PUV records.
  Future<List<PuvModel>> getPuvs({String? accessToken}) async {
    final data = await _apiService.get(
      ApiConfig.puvs,
      accessToken: accessToken,
    );

    if (data is! List) {
      throw const ApiException(message: 'Invalid PUV records response.');
    }

    return data.map<PuvModel>((item) {
      return _parsePuv(item);
    }).toList();
  }

  // Retrieve a specific PUV record.
  Future<PuvModel> getPuvById(int puvId, {String? accessToken}) async {
    _validatePuvId(puvId);

    final data = await _apiService.get(
      ApiConfig.puvById(puvId),
      accessToken: accessToken,
    );

    return _parsePuv(data);
  }

  // Register a new PUV.
  Future<PuvModel> createPuv({
    required String puvType,
    required int capacity,
    String? accessToken,
  }) async {
    final body = PuvModel.requestBody(puvType: puvType, capacity: capacity);

    final data = await _apiService.post(
      ApiConfig.puvs,
      body: body,
      accessToken: accessToken,
    );

    return _parsePuv(data);
  }

  // Update an existing PUV.
  Future<PuvModel> updatePuv({
    required int puvId,
    required String puvType,
    required int capacity,
    String? accessToken,
  }) async {
    _validatePuvId(puvId);

    final body = PuvModel.requestBody(puvType: puvType, capacity: capacity);

    final data = await _apiService.put(
      ApiConfig.puvById(puvId),
      body: body,
      accessToken: accessToken,
    );

    return _parsePuv(data);
  }

  // Convert API response into a validated PUV model.
  PuvModel _parsePuv(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw const ApiException(message: 'Invalid PUV record response.');
    }

    try {
      return PuvModel.fromJson(data);
    } on FormatException {
      throw const ApiException(
        message: 'The server returned invalid PUV data.',
      );
    }
  }

  // Validate the PUV ID before sending a request.
  void _validatePuvId(int puvId) {
    if (puvId <= 0 || puvId > 2147483647) {
      throw ArgumentError('Invalid PUV ID.');
    }
  }

  // Release owned API service resources.
  void dispose() {
    if (_ownsApiService) {
      _apiService.dispose();
    }
  }
}
