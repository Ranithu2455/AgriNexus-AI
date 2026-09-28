import '../api/api_client.dart';
import '../models/feedback.dart';

class FeedbackService {
  FeedbackService._();
  static final FeedbackService instance = FeedbackService._();

  final _client = ApiClient.instance;

  Future<FarmerFeedback> submit({
    required String feedbackType,
    String? description,
    String? farmId,
    String? cropId,
  }) async {
    final data = await _client.post('/farmer-feedback', body: {
      'feedback_type': feedbackType,
      if (description != null && description.isNotEmpty) 'description': description,
      if (farmId != null) 'farm_id': farmId,
      if (cropId != null) 'crop_id': cropId,
    });
    return FarmerFeedback.fromJson(data as Map<String, dynamic>);
  }

  Future<List<FarmerFeedback>> listMine() async {
    final data = await _client.get('/farmer-feedback') as List<dynamic>;
    return data.map((e) => FarmerFeedback.fromJson(e as Map<String, dynamic>)).toList();
  }
}
