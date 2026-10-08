import 'package:flutter/foundation.dart';

import '../../../shared/api/api_client.dart';
import '../models/order.dart';
import '../../marketplace/services/marketplace_api_service.dart';
import '../../marketplace/providers/marketplace_provider.dart';

/// Drives buyer-requests (seller side) and my-orders (buyer side) screens,
/// plus the order-details screen's status-update actions.
class OrderProvider extends ChangeNotifier {
  final MarketplaceApiService _api;
  OrderProvider(this._api);

  List<MarketOrder> myOrders = [];
  List<MarketOrder> receivedOrders = [];
  LoadStatus myOrdersStatus = LoadStatus.idle;
  LoadStatus receivedOrdersStatus = LoadStatus.idle;
  String? errorMessage;

  Future<void> loadMyOrders() async {
    myOrdersStatus = LoadStatus.loading;
    notifyListeners();
    try {
      myOrders = await _api.getMyOrdersAsBuyer();
      myOrdersStatus = myOrders.isEmpty ? LoadStatus.empty : LoadStatus.success;
    } on NetworkException catch (e) {
      errorMessage = e.message;
      myOrdersStatus = LoadStatus.error;
    } on ApiException catch (e) {
      errorMessage = e.message;
      myOrdersStatus = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> loadReceivedOrders() async {
    receivedOrdersStatus = LoadStatus.loading;
    notifyListeners();
    try {
      receivedOrders = await _api.getOrdersReceivedAsSeller();
      receivedOrdersStatus = receivedOrders.isEmpty ? LoadStatus.empty : LoadStatus.success;
    } on NetworkException catch (e) {
      errorMessage = e.message;
      receivedOrdersStatus = LoadStatus.error;
    } on ApiException catch (e) {
      errorMessage = e.message;
      receivedOrdersStatus = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<MarketOrder> createOrder({required String listingId, required double quantity, String? message}) async {
    final order = await _api.createOrder(listingId: listingId, quantity: quantity, message: message);
    myOrders = [order, ...myOrders];
    notifyListeners();
    return order;
  }

  Future<MarketOrder> updateStatus(String orderId, OrderStatus status) async {
    final updated = await _api.updateOrderStatus(orderId, status);
    myOrders = myOrders.map((o) => o.id == orderId ? updated : o).toList();
    receivedOrders = receivedOrders.map((o) => o.id == orderId ? updated : o).toList();
    notifyListeners();
    return updated;
  }
}
