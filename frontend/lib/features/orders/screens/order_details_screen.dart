import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../auth/auth_service.dart';
import '../../../shared/api/api_client.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../products/models/listing.dart';
import '../models/order.dart';
import '../../marketplace/models/seller_summary.dart';
import '../providers/order_provider.dart';
import '../../marketplace/services/marketplace_api_service.dart';
import '../widgets/order_status_badge.dart';

enum _LoadState { loading, success, error }

/// Full detail for one order/request: what was ordered, who's involved,
/// its current status, and the actions available to accept/reject/
/// complete/cancel it or (once completed) leave a review.
class OrderDetailsScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  _LoadState _state = _LoadState.loading;
  String? _error;
  MarketOrder? _order;
  ListingDetail? _listing;
  SellerSummary? _buyer;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = _LoadState.loading);
    try {
      final api = context.read<MarketplaceApiService>();
      final order = await api.getOrder(widget.orderId);
      final results = await Future.wait([
        api.getProductDetails(order.listingId),
        api.getBuyerProfile(order.buyerId),
      ]);
      setState(() {
        _order = order;
        _listing = results[0] as ListingDetail;
        _buyer = results[1] as SellerSummary;
        _state = _LoadState.success;
      });
    } on NetworkException catch (e) {
      setState(() {
        _error = e.message;
        _state = _LoadState.error;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.isForbidden ? "You don't have access to this order" : e.message;
        _state = _LoadState.error;
      });
    }
  }

  Future<void> _updateStatus(OrderStatus status) async {
    setState(() => _busy = true);
    try {
      final updated = await context.read<OrderProvider>().updateStatus(widget.orderId, status);
      setState(() => _order = updated);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update order: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leaveReview() async {
    int rating = 5;
    final commentController = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Leave a review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final starIndex = i + 1;
                  return IconButton(
                    icon: Icon(starIndex <= rating ? Icons.star : Icons.star_border, color: Colors.amber),
                    onPressed: () => setDialogState(() => rating = starIndex),
                  );
                }),
              ),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Comment (optional)', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit')),
          ],
        ),
      ),
    );

    if (submitted != true || !mounted) return;
    try {
      await context.read<MarketplaceApiService>().createReview(
            orderId: widget.orderId,
            rating: rating,
            comment: commentController.text.trim().isEmpty ? null : commentController.text.trim(),
          );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review submitted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not submit review: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order details')),
      body: switch (_state) {
        _LoadState.loading => const LoadingView(),
        _LoadState.error => ErrorView(message: _error ?? 'Failed to load order', onRetry: _load),
        _LoadState.success => _buildContent(context),
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    final order = _order!;
    final listing = _listing!;
    final auth = context.watch<AuthService>();
    final currentUserId = auth.currentUser?.id;
    final isSeller = currentUserId == order.sellerId;
    final isBuyer = currentUserId == order.buyerId;
    final dateFormat = DateFormat.yMMMd().add_jm();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(child: Text(listing.title, style: Theme.of(context).textTheme.titleLarge)),
            OrderStatusBadge(status: order.status),
          ],
        ),
        const SizedBox(height: 16),
        _InfoRow(label: 'Quantity', value: '${order.quantity} ${listing.unit}'),
        _InfoRow(label: 'Price per unit', value: '${listing.currency} ${order.unitPriceSnapshot.toStringAsFixed(2)}'),
        _InfoRow(label: 'Total', value: '${listing.currency} ${order.totalPrice.toStringAsFixed(2)}'),
        _InfoRow(label: 'Seller', value: listing.seller.fullName),
        _InfoRow(label: 'Buyer', value: _buyer?.fullName ?? '—'),
        _InfoRow(label: 'Placed', value: dateFormat.format(order.createdAt)),
        if (order.message != null && order.message!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Message', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(order.message!),
        ],
        const SizedBox(height: 24),
        if (_busy) const Center(child: CircularProgressIndicator()),
        if (!_busy) ..._buildActions(order, isSeller, isBuyer),
      ],
    );
  }

  List<Widget> _buildActions(MarketOrder order, bool isSeller, bool isBuyer) {
    final actions = <Widget>[];

    if (isSeller && order.status == OrderStatus.pending) {
      actions.add(Row(children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _updateStatus(OrderStatus.rejected),
            child: const Text('Reject'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: () => _updateStatus(OrderStatus.accepted),
            child: const Text('Accept'),
          ),
        ),
      ]));
    } else if (isSeller && order.status == OrderStatus.accepted) {
      actions.add(SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: () => _updateStatus(OrderStatus.completed),
          child: const Text('Mark as completed'),
        ),
      ));
    } else if (isBuyer && order.status == OrderStatus.pending) {
      actions.add(SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => _updateStatus(OrderStatus.cancelled),
          child: const Text('Cancel order'),
        ),
      ));
    } else if (isBuyer && order.status == OrderStatus.completed) {
      actions.add(SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _leaveReview,
          icon: const Icon(Icons.star_outline),
          label: const Text('Leave a review'),
        ),
      ));
    }

    return actions;
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
