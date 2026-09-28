import '../api/api_client.dart';
import '../models/recommendation.dart';

class RecommendationService {
  RecommendationService._();
  static final RecommendationService instance = RecommendationService._();

  final _client = ApiClient.instance;

  Future<CropRecommendationResult> getRecommendations({
    required double soilPh,
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    required double temperatureC,
    required double humidityPct,
    required double rainfallMm,
    String? location,
    String? season,
    required String waterAvailability,
  }) async {
    final data = await _client.post('/crop-recommendations', body: {
      'soil_ph': soilPh,
      'nitrogen': nitrogen,
      'phosphorus': phosphorus,
      'potassium': potassium,
      'temperature_c': temperatureC,
      'humidity_pct': humidityPct,
      'rainfall_mm': rainfallMm,
      if (location != null && location.isNotEmpty) 'location': location,
      if (season != null) 'season': season,
      'water_availability': waterAvailability,
    });
    return CropRecommendationResult.fromJson(data as Map<String, dynamic>);
  }
}
