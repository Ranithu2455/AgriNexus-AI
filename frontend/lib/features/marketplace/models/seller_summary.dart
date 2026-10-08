class SellerSummary {
  final String id;
  final String fullName;
  final String role;
  final String? location;
  final String? phoneNumber;

  SellerSummary({
    required this.id,
    required this.fullName,
    required this.role,
    this.location,
    this.phoneNumber,
  });

  factory SellerSummary.fromJson(Map<String, dynamic> json) => SellerSummary(
        id: json['id'] as String,
        fullName: json['full_name'] as String,
        role: json['role'] as String,
        location: json['location'] as String?,
        phoneNumber: json['phone_number'] as String?,
      );
}
