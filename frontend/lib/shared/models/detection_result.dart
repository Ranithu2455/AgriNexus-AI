class DiseaseResult {
  final String id;
  final String imageUrl;
  final String? predictedDisease;
  final double? confidence;
  final List<String> symptoms;
  final List<String> recommendedActions;
  final String modelBackendUsed;
  final bool isMockResult;
  final String disclaimer;
  final DateTime createdAt;

  DiseaseResult({
    required this.id,
    required this.imageUrl,
    this.predictedDisease,
    this.confidence,
    this.symptoms = const [],
    this.recommendedActions = const [],
    required this.modelBackendUsed,
    required this.isMockResult,
    required this.disclaimer,
    required this.createdAt,
  });

  factory DiseaseResult.fromJson(Map<String, dynamic> json) {
    return DiseaseResult(
      id: json['id'] as String,
      imageUrl: json['image_url'] as String,
      predictedDisease: json['predicted_disease'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      symptoms: (json['symptoms'] as List<dynamic>?)?.cast<String>() ?? const [],
      recommendedActions:
          (json['recommended_actions'] as List<dynamic>?)?.cast<String>() ?? const [],
      modelBackendUsed: json['model_backend_used'] as String? ?? 'mock',
      isMockResult: json['is_mock_result'] as bool? ?? true,
      disclaimer: json['disclaimer'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class PestResult {
  final String id;
  final String imageUrl;
  final String? predictedPest;
  final double? confidence;
  final List<String> symptoms;
  final List<String> recommendedActions;
  final String modelBackendUsed;
  final bool isMockResult;
  final String disclaimer;
  final DateTime createdAt;

  PestResult({
    required this.id,
    required this.imageUrl,
    this.predictedPest,
    this.confidence,
    this.symptoms = const [],
    this.recommendedActions = const [],
    required this.modelBackendUsed,
    required this.isMockResult,
    required this.disclaimer,
    required this.createdAt,
  });

  factory PestResult.fromJson(Map<String, dynamic> json) {
    return PestResult(
      id: json['id'] as String,
      imageUrl: json['image_url'] as String,
      predictedPest: json['predicted_pest'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      symptoms: (json['symptoms'] as List<dynamic>?)?.cast<String>() ?? const [],
      recommendedActions:
          (json['recommended_actions'] as List<dynamic>?)?.cast<String>() ?? const [],
      modelBackendUsed: json['model_backend_used'] as String? ?? 'mock',
      isMockResult: json['is_mock_result'] as bool? ?? true,
      disclaimer: json['disclaimer'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
