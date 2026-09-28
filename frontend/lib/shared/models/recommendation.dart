class CropSuitability {
  final String cropName;
  final double suitabilityScore;
  final String suitabilityLevel; // high | moderate | low
  final List<String> reasons;
  final List<String> warnings;

  CropSuitability({
    required this.cropName,
    required this.suitabilityScore,
    required this.suitabilityLevel,
    this.reasons = const [],
    this.warnings = const [],
  });

  factory CropSuitability.fromJson(Map<String, dynamic> json) {
    return CropSuitability(
      cropName: json['crop_name'] as String,
      suitabilityScore: (json['suitability_score'] as num).toDouble(),
      suitabilityLevel: json['suitability_level'] as String,
      reasons: (json['reasons'] as List<dynamic>?)?.cast<String>() ?? const [],
      warnings: (json['warnings'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }
}

class CropRecommendationResult {
  final List<CropSuitability> recommendations;
  final String disclaimer;

  CropRecommendationResult({required this.recommendations, required this.disclaimer});

  factory CropRecommendationResult.fromJson(Map<String, dynamic> json) {
    return CropRecommendationResult(
      recommendations: (json['recommendations'] as List<dynamic>)
          .map((e) => CropSuitability.fromJson(e as Map<String, dynamic>))
          .toList(),
      disclaimer: json['disclaimer'] as String? ?? '',
    );
  }
}
