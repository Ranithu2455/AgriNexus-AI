import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../auth/auth_service.dart';
import '../../../shared/api/api_client.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../models/listing.dart';
import '../../orders/providers/order_provider.dart';
import '../../marketplace/services/marketplace_api_service.dart';
import '../../marketplace/widgets/rating_stars.dart';
import '../../marketplace/screens/farmer_profile_screen.dart';
import '../../orders/screens/order_details_screen.dart';
import '../../suppliers/screens/supplier_profile_screen.dart';

enum _LoadState { loading, success, error }

/// Buyer-facing product details: images, seller info + rating, description,
/// and the two buyer actions this module requires — send an inquiry, or
/// place an order/request.
class ProductDetailsScreen extends StatefulWidget {
  final String listingId;
  const ProductDetailsScreen({super.key, required this.listingId});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  _LoadState _state = _LoadState.loading;
  String? _error;
  ListingDetail? _listing;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = _LoadState.loading);
    try {
      final detail = await context.read<MarketplaceApiService>().getProductDetails(widget.listingId);
      setState(() {
        _listing = detail;
        _state = _LoadState.success;
      });
    } on NetworkException catch (e) {
      setState(() {
        _error = e.message;
        _state = _LoadState.error;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.isNotFound ? 'This listing is no longer available' : e.message;
        _state = _LoadState.error;
      });
    }
  }

  Future<void> _sendInquiry() async {
    final controller = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send an inquiry'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Ask the seller a question...', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Send')),
        ],
      ),
    );
    if (message == null || message.isEmpty || !mounted) return;
    try {
      await context.read<MarketplaceApiService>().sendInquiry(widget.listingId, message);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inquiry sent to the seller')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not send inquiry: $e')));
    }
  }

  Future<void> _placeOrder() async {
    final listing = _listing!;
    final quantityController = TextEditingController(text: '1');
    final messageController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Place order'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: quantityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Quantity (${listing.unit})', border: const OutlineInputBorder()),
                validator: (v) {
                  final q = double.tryParse(v ?? '');
                  if (q == null || q <= 0) return 'Enter a valid quantity';
                  if (q > listing.quantity) return 'Only ${listing.quantity} ${listing.unit} available';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: messageController,
                decoration: const InputDecoration(labelText: 'Message (optional)', border: OutlineInputBorder()),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Place order'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    try {
      final order = await context.read<OrderProvider>().createOrder(
            listingId: listing.id,
            quantity: double.parse(quantityController.text),
            message: messageController.text.trim().isEmpty ? null : messageController.text.trim(),
          );
      if (mounted) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderDetailsScreen(orderId: order.id)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not place order: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final listing = _listing;
    final auth = context.watch<AuthService>();
    final isOwnListing = listing != null && auth.currentUser?.id == listing.sellerId;

    return Scaffold(
      appBar: AppBar(title: Text(listing?.title ?? 'Product')),
      body: switch (_state) {
        _LoadState.loading => const LoadingView(),
        _LoadState.error => ErrorView(message: _error ?? 'Failed to load product', onRetry: _load),
        _LoadState.success => _buildContent(context, listing!),
      },
      bottomNavigationBar: (_state == _LoadState.success && !isOwnListing)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _sendInquiry,
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Inquire'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _placeOrder,
                      icon: const Icon(Icons.shopping_cart_outlined),
                      label: const Text('Order'),
                    ),
                  ),
                ]),
              ),
            )
          : null,
    );
  }

  Widget _buildContent(BuildContext context, ListingDetail listing) {
    final priceFormat = NumberFormat.currency(symbol: '${listing.currency} ', decimalDigits: 2);

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        AspectRatio(
          aspectRatio: 16 / 10,
          child: listing.images.isEmpty
              ? Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image_not_supported_outlined, size: 48, color: Colors.grey),
                )
              : PageView(
                  children: listing.images
                      .map((img) => Image.network(img.imageUrl, fit: BoxFit.cover))
                      .toList(),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(listing.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                '${priceFormat.format(listing.price)} / ${listing.unit}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text('${listing.quantity.toStringAsFixed(listing.quantity.truncateToDouble() == listing.quantity ? 0 : 2)} ${listing.unit} available'),
              if (listing.location != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(listing.location!, style: const TextStyle(color: Colors.grey)),
                ]),
              ],
              const Divider(height: 32),
              if (listing.description != null) ...[
                Text('Description', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(listing.description!),
                const Divider(height: 32),
              ],
              Text('Seller', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(listing.seller.fullName.isNotEmpty ? listing.seller.fullName[0] : '?')),
                  title: Text(listing.seller.fullName),
                  subtitle: RatingStars(rating: listing.averageRating, reviewCount: listing.reviewCount),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => listing.seller.role == 'supplier'
                          ? SupplierProfileScreen(userId: listing.seller.id)
                          : FarmerProfileScreen(userId: listing.seller.id),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
