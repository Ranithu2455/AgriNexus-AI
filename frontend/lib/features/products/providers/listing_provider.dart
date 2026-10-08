import 'package:flutter/foundation.dart';

import '../../../shared/api/api_client.dart';
import '../models/listing.dart';
import '../../marketplace/services/marketplace_api_service.dart';
import '../../marketplace/providers/marketplace_provider.dart';

/// Drives the seller-facing "My Listings" / add / edit listing screens.
class ListingProvider extends ChangeNotifier {
  final MarketplaceApiService _api;
  ListingProvider(this._api);

  List<Listing> myListings = [];
  LoadStatus status = LoadStatus.idle;
  String? errorMessage;

  Future<void> loadMyListings() async {
    status = LoadStatus.loading;
    notifyListeners();
    try {
      myListings = await _api.getMyListings();
      status = myListings.isEmpty ? LoadStatus.empty : LoadStatus.success;
    } on NetworkException catch (e) {
      errorMessage = e.message;
      status = LoadStatus.error;
    } on ApiException catch (e) {
      errorMessage = e.message;
      status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<Listing> createListing({
    required String categoryId,
    required ListingType listingType,
    String? supplierProductType,
    required String title,
    String? description,
    required double quantity,
    required String unit,
    required double price,
    String? location,
    DateTime? availableDate,
  }) async {
    final listing = await _api.createListing(
      categoryId: categoryId,
      listingType: listingType,
      supplierProductType: supplierProductType,
      title: title,
      description: description,
      quantity: quantity,
      unit: unit,
      price: price,
      location: location,
      availableDate: availableDate,
    );
    myListings = [listing, ...myListings];
    status = LoadStatus.success;
    notifyListeners();
    return listing;
  }

  Future<Listing> updateListing(String id, Map<String, dynamic> changes) async {
    final updated = await _api.updateListing(id, changes);
    myListings = myListings.map((l) => l.id == id ? updated : l).toList();
    notifyListeners();
    return updated;
  }

  Future<void> deleteListing(String id) async {
    await _api.deleteListing(id);
    myListings = myListings.where((l) => l.id != id).toList();
    if (myListings.isEmpty) status = LoadStatus.empty;
    notifyListeners();
  }

  Future<void> uploadImage(String listingId, String filePath, {bool setPrimary = false}) async {
    final image = await _api.uploadListingImage(listingId, filePath, setPrimary: setPrimary);
    myListings = myListings.map((l) {
      if (l.id != listingId) return l;
      return Listing(
        id: l.id, sellerId: l.sellerId, categoryId: l.categoryId, listingType: l.listingType,
        supplierProductType: l.supplierProductType, title: l.title, description: l.description,
        quantity: l.quantity, unit: l.unit, price: l.price, currency: l.currency, location: l.location,
        availableDate: l.availableDate, status: l.status, createdAt: l.createdAt, updatedAt: l.updatedAt,
        images: [...l.images, image],
      );
    }).toList();
    notifyListeners();
  }
}
