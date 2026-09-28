class Farm {
  final String id;
  final String name;
  final String? location;
  final String? district;
  final double? sizeAcres;
  final String? soilInfo;
  final String waterAvailability; // abundant | moderate | limited | none

  Farm({
    required this.id,
    required this.name,
    this.location,
    this.district,
    this.sizeAcres,
    this.soilInfo,
    required this.waterAvailability,
  });

  factory Farm.fromJson(Map<String, dynamic> json) {
    return Farm(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String?,
      district: json['district'] as String?,
      sizeAcres: (json['size_acres'] as num?)?.toDouble(),
      soilInfo: json['soil_info'] as String?,
      waterAvailability: json['water_availability'] as String? ?? 'moderate',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (location != null) 'location': location,
      if (district != null) 'district': district,
      if (sizeAcres != null) 'size_acres': sizeAcres,
      if (soilInfo != null) 'soil_info': soilInfo,
      'water_availability': waterAvailability,
    };
  }
}
