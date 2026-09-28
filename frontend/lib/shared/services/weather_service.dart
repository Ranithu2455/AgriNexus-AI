import '../api/api_client.dart';
import '../models/weather.dart';

class WeatherService {
  WeatherService._();
  static final WeatherService instance = WeatherService._();

  final _client = ApiClient.instance;

  Future<WeatherInfo> getWeather(String location) async {
    final data = await _client.get('/weather', query: {'location': location});
    return WeatherInfo.fromJson(data as Map<String, dynamic>);
  }
}
