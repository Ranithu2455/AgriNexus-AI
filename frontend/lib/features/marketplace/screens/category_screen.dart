import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/api/api_client.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../models/category.dart';
import '../../products/models/listing.dart';
import '../services/marketplace_api_service.dart';
import '../../products/widgets/product_card.dart';
import '../../products/screens/product_details_screen.dart';

enum _LoadState { loading, success, empty, error }

/// Shows every active listing in one category. Reachable from the
/// marketplace home's category row.
class CategoryScreen extends StatefulWidget {
  final Category category;
  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
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
      final api = context.read<MarketplaceApiService>();
      final result = await api.browseProducts(categoryId: widget.category.id, pageSize: 50);
      setState(() {
        _listings = result.items;
        _state = _listings.isEmpty ? _LoadState.empty : _LoadState.success;
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
      appBar: AppBar(title: Text(widget.category.name)),
      body: switch (_state) {
        _LoadState.loading => const LoadingView(),
        _LoadState.error => ErrorView(message: _error ?? 'Failed to load category', onRetry: _load),
        _LoadState.empty => const EmptyView(
            message: 'No listings in this category yet',
            icon: Icons.category_outlined,
          ),
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
