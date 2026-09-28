import 'dart:io';

import '../api/api_client.dart';
import '../models/detection_result.dart';

class DiseaseService {
  DiseaseService._();
  static final DiseaseService instance = DiseaseService._();

  final _client = ApiClient.instance;

  Future<DiseaseResult> detect(File image, {String? cropId}) async {
    final data = await _client.uploadFile(
      '/disease-detection',
      file: image,
      fieldName: 'file',
      extraFields: cropId != null ? {'crop_id': cropId} : null,
    );
    return DiseaseResult.fromJson(data as Map<String, dynamic>);
  }

  Future<List<DiseaseResult>> getHistory() async {
    final data = await _client.get('/disease-detection/history') as List<dynamic>;
    return data.map((e) => DiseaseResult.fromJson(e as Map<String, dynamic>)).toList();
  }
}

class PestService {
  PestService._();
  static final PestService instance = PestService._();

  final _client = ApiClient.instance;

  Future<PestResult> identify(File image, {String? cropId}) async {
    final data = await _client.uploadFile(
      '/pest-detection',
      file: image,
      fieldName: 'file',
      extraFields: cropId != null ? {'crop_id': cropId} : null,
    );
    return PestResult.fromJson(data as Map<String, dynamic>);
  }

  Future<List<PestResult>> getHistory() async {
    final data = await _client.get('/pest-detection/history') as List<dynamic>;
    return data.map((e) => PestResult.fromJson(e as Map<String, dynamic>)).toList();
  }
}
