import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/auth_service.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../models/category.dart';
import '../../products/models/listing.dart';
import '../providers/marketplace_provider.dart';
import '../widgets/category_chip.dart';
import '../../products/widgets/product_card.dart';
import 'category_screen.dart';
import '../../products/screens/my_listings_screen.dart';
import '../../orders/screens/my_orders_screen.dart';
import '../../orders/screens/buyer_requests_screen.dart';
import '../../products/screens/product_details_screen.dart';
import 'search_screen.dart';

/// Entry point for the Marketplace module. Shows categories + recently
/// listed products for buyers, and quick links to seller tools for
/// farmers/suppliers.
class MarketplaceHomeScreen extends StatefulWidget {
  const MarketplaceHomeScreen({super.key});

  @override
  State<MarketplaceHomeScreen> createState() => _MarketplaceHomeScreenState();
}

class _MarketplaceHomeScreenState extends State<MarketplaceHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MarketplaceProvider>();
      provider.loadCategories();
      if (provider.productsStatus == LoadStatus.idle) provider.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final role = auth.currentUser?.role;
    final isSeller = role == 'farmer' || role == 'supplier';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
        ],
      ),
      floatingActionButton: isSeller
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyListingsScreen()),
              ),
              icon: const Icon(Icons.storefront_outlined),
              label: const Text('My Listings'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => context.read<MarketplaceProvider>().refresh(),
        child: Consumer<MarketplaceProvider>(
          builder: (context, provider, _) {
            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                if (isSeller)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: ListTile(
                        leading: const Icon(Icons.inventory_2_outlined),
                        title: const Text('Buyer requests'),
                        subtitle: const Text('View and respond to orders on your listings'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const BuyerRequestsScreen()),
                        ),
                      ),
                    ),
                  ),
                if (!isSeller && role != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Card(
                      child: ListTile(
                        leading: const Icon(Icons.receipt_long_outlined),
                        title: const Text('My orders'),
                        subtitle: const Text('Track orders you have placed'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                        ),
                      ),
                    ),
                  ),
                _CategoriesSection(categories: provider.categories, status: provider.categoriesStatus),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text('Recently listed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                _ProductsSection(provider: provider),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CategoriesSection extends StatelessWidget {
  final List<Category> categories;
  final LoadStatus status;

  const _CategoriesSection({required this.categories, required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == LoadStatus.loading) {
      return const Padding(padding: EdgeInsets.all(16), child: LoadingView());
    }
    if (categories.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 44,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        children: categories
            .map((c) => CategoryChip(
                  category: c,
                  selected: false,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => CategoryScreen(category: c)),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _ProductsSection extends StatelessWidget {
  final MarketplaceProvider provider;
  const _ProductsSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    switch (provider.productsStatus) {
      case LoadStatus.idle:
      case LoadStatus.loading:
        return const Padding(padding: EdgeInsets.all(32), child: LoadingView());
      case LoadStatus.error:
        return ErrorView(message: provider.errorMessage ?? 'Failed to load products', onRetry: provider.refresh);
      case LoadStatus.empty:
        return const Padding(
          padding: EdgeInsets.all(24),
          child: EmptyView(message: 'No listings yet. Check back soon!', icon: Icons.storefront_outlined),
        );
      default:
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.72,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: provider.products.length,
          itemBuilder: (context, i) {
            final Listing listing = provider.products[i];
            return ProductCard(
              listing: listing,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ProductDetailsScreen(listingId: listing.id)),
              ),
            );
          },
        );
    }
  }
}
