import 'package:flutter/material.dart';

import '../../../shared/api/api_client.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../models/listing.dart';
import '../widgets/product_card.dart';
import 'product_details_screen.dart';

/// Generic reusable product grid screen, driven by a [fetcher] callback.
/// Used by Supplier Products and Farmer/Seller Profile to show "this
/// seller's listings" without duplicating the grid/loading/error/empty
/// boilerplate that SearchScreen and CategoryScreen also need.
class ProductListScreen extends StatefulWidget {
  final String title;
  final Future<List<Listing>> Function() fetcher;

  const ProductListScreen({super.key, required this.title, required this.fetcher});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

enum _LoadState { loading, success, empty, error }

class _ProductListScreenState extends State<ProductListScreen> {
  _LoadState _state = _LoadState.loading;
  String? _error;
  List<Listing> _listings = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = _LoadState.loading);
    try {
      final items = await widget.fetcher();
      setState(() {
        _listings = items;
        _state = items.isEmpty ? _LoadState.empty : _LoadState.success;
      });
    } on NetworkException catch (e) {
      setState(() {
        _error = e.message;
        _state = _LoadState.error;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _state = _LoadState.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: switch (_state) {
        _LoadState.loading => const LoadingView(),
        _LoadState.error => ErrorView(message: _error ?? 'Failed to load listings', onRetry: _load),
        _LoadState.empty => const EmptyView(message: 'No listings here yet', icon: Icons.inventory_2_outlined),
        _LoadState.success => GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _listings.length,
            itemBuilder: (context, i) {
              final listing = _listings[i];
              return ProductCard(
                listing: listing,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ProductDetailsScreen(listingId: listing.id)),
                ),
              );
            },
          ),
      },
    );
  }
}
