class CropHistoryEntry {
  final String id;
  final String event;
  final String? details;
  final DateTime recordedAt;

  CropHistoryEntry({
    required this.id,
    required this.event,
    this.details,
    required this.recordedAt,
  });

  factory CropHistoryEntry.fromJson(Map<String, dynamic> json) {
    return CropHistoryEntry(
      id: json['id'] as String,
      event: json['event'] as String,
      details: json['details'] as String?,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
    );
  }
}

class Crop {
  final String id;
  final String farmId;
  final String name;
  final DateTime? plantingDate;
  final DateTime? expectedHarvestDate;
  final String status;
  final List<CropHistoryEntry> historyEntries;

  Crop({
    required this.id,
    required this.farmId,
    required this.name,
    this.plantingDate,
    this.expectedHarvestDate,
    required this.status,
    this.historyEntries = const [],
  });

  factory Crop.fromJson(Map<String, dynamic> json) {
    return Crop(
      id: json['id'] as String,
      farmId: json['farm_id'] as String,
      name: json['name'] as String,
      plantingDate: json['planting_date'] != null
          ? DateTime.parse(json['planting_date'] as String)
          : null,
      expectedHarvestDate: json['expected_harvest_date'] != null
          ? DateTime.parse(json['expected_harvest_date'] as String)
          : null,
      status: json['status'] as String? ?? 'planned',
      historyEntries: (json['history_entries'] as List<dynamic>?)
              ?.map((e) => CropHistoryEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'farm_id': farmId,
      if (plantingDate != null) 'planting_date': _dateOnly(plantingDate!),
      if (expectedHarvestDate != null) 'expected_harvest_date': _dateOnly(expectedHarvestDate!),
      'status': status,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      if (plantingDate != null) 'planting_date': _dateOnly(plantingDate!),
      if (expectedHarvestDate != null) 'expected_harvest_date': _dateOnly(expectedHarvestDate!),
      'status': status,
    };
  }

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
