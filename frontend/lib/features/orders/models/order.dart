enum OrderStatus { pending, accepted, rejected, completed, cancelled }

OrderStatus orderStatusFromString(String value) {
  switch (value) {
    case 'accepted':
      return OrderStatus.accepted;
    case 'rejected':
      return OrderStatus.rejected;
    case 'completed':
      return OrderStatus.completed;
    case 'cancelled':
      return OrderStatus.cancelled;
    default:
      return OrderStatus.pending;
  }
}

String orderStatusToString(OrderStatus status) => status.name;

String orderStatusLabel(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return 'Pending';
    case OrderStatus.accepted:
      return 'Accepted';
    case OrderStatus.rejected:
      return 'Rejected';
    case OrderStatus.completed:
      return 'Completed';
    case OrderStatus.cancelled:
      return 'Cancelled';
  }
}

/// A buyer's request/order against a listing. Named `MarketOrder` (rather
/// than `Order`) to keep call sites unambiguous next to Dart/Flutter's own
/// ordering concepts (list ordering, widget order, etc.).
class MarketOrder {
  final String id;
  final String listingId;
  final String buyerId;
  final String sellerId;
  final double quantity;
  final double unitPriceSnapshot;
  final double totalPrice;
  final String? message;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  MarketOrder({
    required this.id,
    required this.listingId,
    required this.buyerId,
    required this.sellerId,
    required this.quantity,
    required this.unitPriceSnapshot,
    required this.totalPrice,
    this.message,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MarketOrder.fromJson(Map<String, dynamic> json) => MarketOrder(
        id: json['id'] as String,
        listingId: json['listing_id'] as String,
        buyerId: json['buyer_id'] as String,
        sellerId: json['seller_id'] as String,
        quantity: double.parse(json['quantity'].toString()),
        unitPriceSnapshot: double.parse(json['unit_price_snapshot'].toString()),
        totalPrice: double.parse(json['total_price'].toString()),
        message: json['message'] as String?,
        status: orderStatusFromString(json['status'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}
