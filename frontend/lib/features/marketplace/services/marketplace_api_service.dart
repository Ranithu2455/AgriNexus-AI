import '../../../shared/api/api_client.dart';
import '../models/category.dart';
import '../models/inquiry.dart';
import '../../products/models/listing.dart';
import '../../products/models/listing_image.dart';
import '../../orders/models/order.dart';
import '../models/review.dart';
import '../models/seller_summary.dart';

class MarketplaceApiService {
  final ApiClient _client;

  MarketplaceApiService(this._client);

  // ---------------- Categories ----------------

  Future<List<Category>> getCategories() async {
    final res = await _client.get('/api/categories') as List<dynamic>;
    return res
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---------------- Products (public browse/search) ----------------

  Future<PaginatedListings> browseProducts({
    String? query,
    String? categoryId,
    ListingType? listingType,
    String? sellerId,
    String? location,
    double? minPrice,
    double? maxPrice,
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await _client.get('/api/products', query: {
      'q': query,
      'category_id': categoryId,
      'listing_type':
          listingType == null ? null : listingTypeToString(listingType),
      'seller_id': sellerId,
      'location': location,
      'min_price': minPrice,
      'max_price': maxPrice,
      'page': page,
      'page_size': pageSize,
    });
    return PaginatedListings.fromJson(res as Map<String, dynamic>);
  }

  Future<ListingDetail> getProductDetails(String listingId) async {
    final res = await _client.get('/api/products/$listingId');
    return ListingDetail.fromJson(res as Map<String, dynamic>);
  }

  // ---------------- Listings (seller-owned CRUD) ----------------

  Future<Listing> createListing({
    required String categoryId,
    required ListingType listingType,
    String? supplierProductType,
    required String title,
    String? description,
    required double quantity,
    required String unit,
    required double price,
    String currency = 'LKR',
    String? location,
    DateTime? availableDate,
  }) async {
    final res = await _client.post('/api/listings', body: {
      'category_id': categoryId,
      'listing_type': listingTypeToString(listingType),
      'supplier_product_type': supplierProductType,
      'title': title,
      'description': description,
      'quantity': quantity,
      'unit': unit,
      'price': price,
      'currency': currency,
      'location': location,
      'available_date': availableDate?.toIso8601String(),
    });
    return Listing.fromJson(res as Map<String, dynamic>);
  }

  Future<List<Listing>> getMyListings() async {
    final res = await _client.get('/api/listings/my') as List<dynamic>;
    return res.map((e) => Listing.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Listing> getListing(String id) async {
    final res = await _client.get('/api/listings/$id');
    return Listing.fromJson(res as Map<String, dynamic>);
  }

  Future<Listing> updateListing(String id, Map<String, dynamic> changes) async {
    final res = await _client.put('/api/listings/$id', body: changes);
    return Listing.fromJson(res as Map<String, dynamic>);
  }

  Future<void> deleteListing(String id) => _client.delete('/api/listings/$id');

  Future<ListingImage> uploadListingImage(String listingId, String filePath,
      {bool setPrimary = false}) async {
    final res = await _client.uploadFile(
      '/api/listings/$listingId/images',
      'file',
      filePath,
      fields: {'set_primary': setPrimary.toString()},
    );
    return ListingImage.fromJson(res as Map<String, dynamic>);
  }

  Future<void> deleteListingImage(String listingId, String imageId) =>
      _client.delete('/api/listings/$listingId/images/$imageId');

  // ---------------- Inquiries ----------------

  Future<Inquiry> sendInquiry(String listingId, String message) async {
    final res = await _client
        .post('/api/listings/$listingId/inquiries', body: {'message': message});
    return Inquiry.fromJson(res as Map<String, dynamic>);
  }

  Future<List<Inquiry>> getInquiriesForListing(String listingId) async {
    final res = await _client.get('/api/listings/$listingId/inquiries')
        as List<dynamic>;
    return res.map((e) => Inquiry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Inquiry>> getMySentInquiries() async {
    final res = await _client.get('/api/buyers/me/inquiries') as List<dynamic>;
    return res.map((e) => Inquiry.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ---------------- Orders ----------------

  Future<MarketOrder> createOrder(
      {required String listingId,
      required double quantity,
      String? message}) async {
    final res = await _client.post('/api/orders', body: {
      'listing_id': listingId,
      'quantity': quantity,
      'message': message,
    });
    return MarketOrder.fromJson(res as Map<String, dynamic>);
  }

  Future<List<MarketOrder>> getMyOrdersAsBuyer() async {
    final res = await _client.get('/api/orders/my') as List<dynamic>;
    return res
        .map((e) => MarketOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MarketOrder>> getOrdersReceivedAsSeller() async {
    final res = await _client.get('/api/orders/received') as List<dynamic>;
    return res
        .map((e) => MarketOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MarketOrder> getOrder(String orderId) async {
    final res = await _client.get('/api/orders/$orderId');
    return MarketOrder.fromJson(res as Map<String, dynamic>);
  }

  Future<MarketOrder> updateOrderStatus(
      String orderId, OrderStatus status) async {
    final res = await _client.patch('/api/orders/$orderId/status', body: {
      'status': orderStatusToString(status),
    });
    return MarketOrder.fromJson(res as Map<String, dynamic>);
  }

  // ---------------- Suppliers / Buyers profiles ----------------

  Future<SellerSummary> getSupplierProfile(String userId) async {
    final res = await _client.get('/api/suppliers/$userId');
    return SellerSummary.fromJson(res as Map<String, dynamic>);
  }

  Future<List<Listing>> getSupplierProducts(String userId,
      {int page = 1, int pageSize = 20}) async {
    final res = await _client.get('/api/suppliers/$userId/products',
        query: {'page': page, 'page_size': pageSize}) as List<dynamic>;
    return res.map((e) => Listing.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> getSupplierRating(String userId) async {
    return await _client.get('/api/suppliers/$userId/rating')
        as Map<String, dynamic>;
  }

  Future<SellerSummary> getBuyerProfile(String userId) async {
    final res = await _client.get('/api/buyers/$userId');
    return SellerSummary.fromJson(res as Map<String, dynamic>);
  }

  // ---------------- Reviews ----------------

  Future<Review> createReview(
      {required String orderId, required int rating, String? comment}) async {
    final res = await _client.post('/api/reviews', body: {
      'order_id': orderId,
      'rating': rating,
      'comment': comment,
    });
    return Review.fromJson(res as Map<String, dynamic>);
  }

  Future<List<Review>> getReviewsForUser(String userId) async {
    final res = await _client.get('/api/reviews/user/$userId') as List<dynamic>;
    return res.map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
  }
}
