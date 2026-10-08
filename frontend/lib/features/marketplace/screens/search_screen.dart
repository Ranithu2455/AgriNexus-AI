import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/state_widgets.dart';
import '../../products/models/listing.dart';
import '../providers/marketplace_provider.dart';
import '../../products/widgets/product_card.dart';
import '../../products/screens/product_details_screen.dart';

/// Buyer search + filter screen. Filters: free-text query, category,
/// listing type, location, and price range — matching the backend's
/// GET /api/products query parameters.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _queryController = TextEditingController();
  final _locationController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  String? _categoryId;
  ListingType? _listingType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<MarketplaceProvider>().categories.isEmpty) {
        context.read<MarketplaceProvider>().loadCategories();
      }
    });
  }

  void _runSearch() {
    context.read<MarketplaceProvider>().search(
          query: _queryController.text.trim().isEmpty ? null : _queryController.text.trim(),
          categoryId: _categoryId,
          listingType: _listingType,
          location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
          minPrice: double.tryParse(_minPriceController.text),
          maxPrice: double.tryParse(_maxPriceController.text),
        );
  }

  void _openFilters() {
    final categories = context.read<MarketplaceProvider>().categories;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (ctx, setSheetState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Filters', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  value: _categoryId,
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Any category')),
                    ...categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                  ],
                  onChanged: (v) => setSheetState(() => _categoryId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ListingType?>(
                  value: _listingType,
                  decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Any type')),
                    DropdownMenuItem(value: ListingType.farmerProduct, child: Text('Farm produce')),
                    DropdownMenuItem(value: ListingType.supplierProduct, child: Text('Agri-input')),
                  ],
                  onChanged: (v) => setSheetState(() => _listingType = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _minPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Min price', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _maxPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Max price', border: OutlineInputBorder()),
                    ),
                  ),
                ]),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _runSearch();
                  },
                  child: const Text('Apply filters'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _queryController.dispose();
    _locationController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _queryController,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(hintText: 'Search products...', border: InputBorder.none),
          onSubmitted: (_) => _runSearch(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.tune), onPressed: _openFilters),
        ],
      ),
      body: Consumer<MarketplaceProvider>(
        builder: (context, provider, _) {
          Widget body;
          switch (provider.productsStatus) {
            case LoadStatus.loading:
              body = const LoadingView();
              break;
            case LoadStatus.error:
              body = ErrorView(message: provider.errorMessage ?? 'Search failed', onRetry: _runSearch);
              break;
            case LoadStatus.empty:
              body = const EmptyView(message: 'No products match your search', icon: Icons.search_off);
              break;
            case LoadStatus.idle:
              body = const EmptyView(message: 'Search for products, or use filters to browse', icon: Icons.search);
              break;
            default:
              body = NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
                    provider.loadMore();
                  }
                  return false;
                },
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: provider.products.length,
                  itemBuilder: (context, i) {
                    final listing = provider.products[i];
                    return ProductCard(
                      listing: listing,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ProductDetailsScreen(listingId: listing.id)),
                      ),
                    );
                  },
                ),
              );
          }
          return body;
        },
      ),
    );
  }
}
