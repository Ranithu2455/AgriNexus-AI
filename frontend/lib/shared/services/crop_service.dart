import '../api/api_client.dart';
import '../models/crop.dart';

class CropService {
  CropService._();
  static final CropService instance = CropService._();

  final _client = ApiClient.instance;

  Future<List<Crop>> listCrops({String? farmId}) async {
    final data = await _client.get(
      '/crops',
      query: farmId != null ? {'farm_id': farmId} : null,
    ) as List<dynamic>;
    return data.map((e) => Crop.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Crop> getCrop(String cropId) async {
    final data = await _client.get('/crops/$cropId');
    return Crop.fromJson(data as Map<String, dynamic>);
  }

  Future<Crop> createCrop(Crop crop) async {
    final data = await _client.post('/crops', body: crop.toCreateJson());
    return Crop.fromJson(data as Map<String, dynamic>);
  }

  Future<Crop> updateCrop(String cropId, Crop crop) async {
    final data = await _client.put('/crops/$cropId', body: crop.toUpdateJson());
    return Crop.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteCrop(String cropId) async {
    await _client.delete('/crops/$cropId');
  }
}
