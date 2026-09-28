class WeatherInfo {
  final String location;
  final double temperatureC;
  final double humidityPct;
  final String condition;
  final String description;
  final double rainfallMmLastHour;
  final double windSpeedMs;
  final bool isMockResult;
  final List<String> advisories;

  WeatherInfo({
    required this.location,
    required this.temperatureC,
    required this.humidityPct,
    required this.condition,
    required this.description,
    required this.rainfallMmLastHour,
    required this.windSpeedMs,
    required this.isMockResult,
    this.advisories = const [],
  });

  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    return WeatherInfo(
      location: json['location'] as String,
      temperatureC: (json['temperature_c'] as num).toDouble(),
      humidityPct: (json['humidity_pct'] as num).toDouble(),
      condition: json['condition'] as String,
      description: json['description'] as String,
      rainfallMmLastHour: (json['rainfall_mm_last_hour'] as num).toDouble(),
      windSpeedMs: (json['wind_speed_ms'] as num).toDouble(),
      isMockResult: json['is_mock_result'] as bool? ?? false,
      advisories: (json['advisories'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }
}
