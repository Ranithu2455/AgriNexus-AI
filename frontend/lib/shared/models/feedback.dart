class FarmerFeedback {
  final String id;
  final String feedbackType;
  final String? description;
  final String? farmId;
  final String? cropId;
  final DateTime createdAt;

  FarmerFeedback({
    required this.id,
    required this.feedbackType,
    this.description,
    this.farmId,
    this.cropId,
    required this.createdAt,
  });

  factory FarmerFeedback.fromJson(Map<String, dynamic> json) {
    return FarmerFeedback(
      id: json['id'] as String,
      feedbackType: json['feedback_type'] as String,
      description: json['description'] as String?,
      farmId: json['farm_id'] as String?,
      cropId: json['crop_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

const List<String> kFeedbackTypes = [
  'waterlogging',
  'drought',
  'salinity',
  'pest_outbreak',
  'disease_outbreak',
  'unexpected_weather',
  'crop_growth_problem',
  'other',
];
