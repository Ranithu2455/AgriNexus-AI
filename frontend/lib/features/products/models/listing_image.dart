class ListingImage {
  final String id;
  final String imageUrl;
  final bool isPrimary;

  ListingImage({required this.id, required this.imageUrl, required this.isPrimary});

  factory ListingImage.fromJson(Map<String, dynamic> json) => ListingImage(
        id: json['id'] as String,
        imageUrl: json['image_url'] as String,
        isPrimary: json['is_primary'] as bool? ?? false,
      );
}
