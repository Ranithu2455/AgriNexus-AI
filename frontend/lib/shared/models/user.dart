class FarmerProfile {
  final String id;
  final String fullName;
  final String? district;
  final String? location;
  final String? profileImageUrl;
  final String? farmerInfo;

  FarmerProfile({
    required this.id,
    required this.fullName,
    this.district,
    this.location,
    this.profileImageUrl,
    this.farmerInfo,
  });

  factory FarmerProfile.fromJson(Map<String, dynamic> json) {
    return FarmerProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      district: json['district'] as String?,
      location: json['location'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      farmerInfo: json['farmer_info'] as String?,
    );
  }
}

class AppUser {
  final String id;
  final String email;
  final String? phone;
  final String role;
  final bool isActive;
  final FarmerProfile? farmerProfile;

  AppUser({
    required this.id,
    required this.email,
    this.phone,
    required this.role,
    required this.isActive,
    this.farmerProfile,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String,
      isActive: json['is_active'] as bool,
      farmerProfile: json['farmer_profile'] != null
          ? FarmerProfile.fromJson(json['farmer_profile'] as Map<String, dynamic>)
          : null,
    );
  }
}
