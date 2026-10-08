import 'package:flutter/foundation.dart' hide Category;

import '../../../shared/api/api_client.dart';
import '../models/category.dart';
import '../../products/models/listing.dart';
import '../services/marketplace_api_service.dart';

enum LoadStatus { idle, loading, loadingMore, success, empty, error }

/// Drives the buyer-facing browse/search/filter screens (marketplace home,
/// search, category, product list).
class MarketplaceProvider extends ChangeNotifier {
  final MarketplaceApiService _api;
  MarketplaceProvider(this._api);

  // Categories
  List<Category> categories = [];
  LoadStatus categoriesStatus = LoadStatus.idle;

  // Product browsing
  List<Listing> products = [];
  LoadStatus productsStatus = LoadStatus.idle;
  String? errorMessage;
  int _page = 1;
  int _total = 0;
  bool get hasMore => products.length < _total;

  // Active filters
  String? searchQuery;
  String? categoryId;
  ListingType? listingType;
  String? location;
  double? minPrice;
  double? maxPrice;

  Future<void> loadCategories() async {
    categoriesStatus = LoadStatus.loading;
    notifyListeners();
    try {
      categories = await _api.getCategories();
      categoriesStatus = LoadStatus.success;
    } catch (_) {
      categoriesStatus = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> search({
    String? query,
    String? categoryId,
    ListingType? listingType,
    String? location,
    double? minPrice,
    double? maxPrice,
  }) async {
    searchQuery = query;
    this.categoryId = categoryId;
    this.listingType = listingType;
    this.location = location;
    this.minPrice = minPrice;
    this.maxPrice = maxPrice;
    await refresh();
  }

  Future<void> refresh() async {
    _page = 1;
    productsStatus = LoadStatus.loading;
    errorMessage = null;
    notifyListeners();
    await _fetchPage();
  }

  Future<void> loadMore() async {
    if (!hasMore || productsStatus == LoadStatus.loadingMore) return;
    _page += 1;
    productsStatus = LoadStatus.loadingMore;
    notifyListeners();
    await _fetchPage(append: true);
  }

  Future<void> _fetchPage({bool append = false}) async {
    try {
      final result = await _api.browseProducts(
        query: searchQuery,
        categoryId: categoryId,
        listingType: listingType,
        location: location,
        minPrice: minPrice,
        maxPrice: maxPrice,
        page: _page,
      );
      _total = result.total;
      products = append ? [...products, ...result.items] : result.items;
      productsStatus = products.isEmpty ? LoadStatus.empty : LoadStatus.success;
    } on NetworkException catch (e) {
      errorMessage = e.message;
      productsStatus = LoadStatus.error;
    } on ApiException catch (e) {
      errorMessage = e.message;
      productsStatus = LoadStatus.error;
    }
    notifyListeners();
  }
}
