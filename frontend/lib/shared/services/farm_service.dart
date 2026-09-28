import '../api/api_client.dart';
import '../models/farm.dart';

class FarmService {
  FarmService._();
  static final FarmService instance = FarmService._();

  final _client = ApiClient.instance;

  Future<List<Farm>> listFarms() async {
    final data = await _client.get('/farms') as List<dynamic>;
    return data.map((e) => Farm.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Farm> getFarm(String farmId) async {
    final data = await _client.get('/farms/$farmId');
    return Farm.fromJson(data as Map<String, dynamic>);
  }

  Future<Farm> createFarm(Farm farm) async {
    final data = await _client.post('/farms', body: farm.toJson());
    return Farm.fromJson(data as Map<String, dynamic>);
  }

  Future<Farm> updateFarm(String farmId, Farm farm) async {
    final data = await _client.put('/farms/$farmId', body: farm.toJson());
    return Farm.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteFarm(String farmId) async {
    await _client.delete('/farms/$farmId');
  }
}
