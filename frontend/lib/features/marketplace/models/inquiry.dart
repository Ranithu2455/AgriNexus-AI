class Inquiry {
  final String id;
  final String listingId;
  final String buyerId;
  final String message;
  final DateTime createdAt;

  Inquiry({
    required this.id,
    required this.listingId,
    required this.buyerId,
    required this.message,
    required this.createdAt,
  });

  factory Inquiry.fromJson(Map<String, dynamic> json) => Inquiry(
        id: json['id'] as String,
        listingId: json['listing_id'] as String,
        buyerId: json['buyer_id'] as String,
        message: json['message'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
