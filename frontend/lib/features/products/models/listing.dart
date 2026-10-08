import 'listing_image.dart';
import '../../marketplace/models/seller_summary.dart';
import '../../marketplace/models/category.dart';

/// Mirrors the backend's ListingType enum.
enum ListingType { farmerProduct, supplierProduct }

ListingType listingTypeFromString(String value) =>
    value == 'supplier_product' ? ListingType.supplierProduct : ListingType.farmerProduct;

String listingTypeToString(ListingType type) =>
    type == ListingType.supplierProduct ? 'supplier_product' : 'farmer_product';

/// Supplier product sub-types. Kept as raw strings (matching the backend's
/// SupplierProductType enum values) rather than a Dart enum, so the
/// dropdown in ListingForm can render them directly without a mapping layer.
const List<String> supplierProductTypes = [
  'seeds',
  'fertilizer',
  'organic_fertilizer',
  'pesticides',
  'herbicides',
  'farming_equipment',
  'irrigation_equipment',
  'other',
];

enum ListingStatus { active, inactive, soldOut }

ListingStatus listingStatusFromString(String value) {
  switch (value) {
    case 'inactive':
      return ListingStatus.inactive;
    case 'sold_out':
      return ListingStatus.soldOut;
    default:
      return ListingStatus.active;
  }
}

String listingStatusToString(ListingStatus status) {
  switch (status) {
    case ListingStatus.inactive:
      return 'inactive';
    case ListingStatus.soldOut:
      return 'sold_out';
    case ListingStatus.active:
      return 'active';
  }
}

String listingStatusLabel(ListingStatus status) {
  switch (status) {
    case ListingStatus.inactive:
      return 'Inactive';
    case ListingStatus.soldOut:
      return 'Sold out';
    case ListingStatus.active:
      return 'Active';
  }
}

class Listing {
  final String id;
  final String sellerId;
  final String categoryId;
  final ListingType listingType;
  final String? supplierProductType;
  final String title;
  final String? description;
  final double quantity;
  final String unit;
  final double price;
  final String currency;
  final String? location;
  final DateTime? availableDate;
  final ListingStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ListingImage> images;

  Listing({
    required this.id,
    required this.sellerId,
    required this.categoryId,
    required this.listingType,
    this.supplierProductType,
    required this.title,
    this.description,
    required this.quantity,
    required this.unit,
    required this.price,
    required this.currency,
    this.location,
    this.availableDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.images = const [],
  });

  String? get primaryImageUrl {
    if (images.isEmpty) return null;
    final primary = images.where((i) => i.isPrimary).toList();
    return (primary.isNotEmpty ? primary.first : images.first).imageUrl;
  }

  factory Listing.fromJson(Map<String, dynamic> json) => Listing(
        id: json['id'] as String,
        sellerId: json['seller_id'] as String,
        categoryId: json['category_id'] as String,
        listingType: listingTypeFromString(json['listing_type'] as String),
        supplierProductType: json['supplier_product_type'] as String?,
        title: json['title'] as String,
        description: json['description'] as String?,
        quantity: double.parse(json['quantity'].toString()),
        unit: json['unit'] as String,
        price: double.parse(json['price'].toString()),
        currency: json['currency'] as String? ?? 'LKR',
        location: json['location'] as String?,
        availableDate: json['available_date'] != null ? DateTime.tryParse(json['available_date']) : null,
        status: listingStatusFromString(json['status'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        images: (json['images'] as List<dynamic>? ?? [])
            .map((e) => ListingImage.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Extra fields returned only by GET /products/{id} (the product-details screen).
class ListingDetail extends Listing {
  final SellerSummary seller;
  final Category category;
  final double? averageRating;
  final int reviewCount;

  ListingDetail({
    required super.id,
    required super.sellerId,
    required super.categoryId,
    required super.listingType,
    super.supplierProductType,
    required super.title,
    super.description,
    required super.quantity,
    required super.unit,
    required super.price,
    required super.currency,
    super.location,
    super.availableDate,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    super.images,
    required this.seller,
    required this.category,
    this.averageRating,
    this.reviewCount = 0,
  });

  factory ListingDetail.fromJson(Map<String, dynamic> json) {
    final base = Listing.fromJson(json);
    return ListingDetail(
      id: base.id,
      sellerId: base.sellerId,
      categoryId: base.categoryId,
      listingType: base.listingType,
      supplierProductType: base.supplierProductType,
      title: base.title,
      description: base.description,
      quantity: base.quantity,
      unit: base.unit,
      price: base.price,
      currency: base.currency,
      location: base.location,
      availableDate: base.availableDate,
      status: base.status,
      createdAt: base.createdAt,
      updatedAt: base.updatedAt,
      images: base.images,
      seller: SellerSummary.fromJson(json['seller'] as Map<String, dynamic>),
      category: Category.fromJson(json['category'] as Map<String, dynamic>),
      averageRating: json['average_rating'] != null ? double.parse(json['average_rating'].toString()) : null,
      reviewCount: json['review_count'] as int? ?? 0,
    );
  }
}

class PaginatedListings {
  final List<Listing> items;
  final int total;
  final int page;
  final int pageSize;

  PaginatedListings({required this.items, required this.total, required this.page, required this.pageSize});

  bool get hasMore => page * pageSize < total;

  factory PaginatedListings.fromJson(Map<String, dynamic> json) => PaginatedListings(
        items: (json['items'] as List<dynamic>).map((e) => Listing.fromJson(e as Map<String, dynamic>)).toList(),
        total: json['total'] as int,
        page: json['page'] as int,
        pageSize: json['page_size'] as int,
      );
}
