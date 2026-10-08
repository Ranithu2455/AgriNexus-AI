import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/state_widgets.dart';
import '../models/listing.dart';
import '../../marketplace/providers/marketplace_provider.dart';
import '../providers/listing_provider.dart';
import 'add_listing_screen.dart';
import 'edit_listing_screen.dart';

/// Seller-facing: every listing (farm produce or agri-input) the current
/// user owns, with quick access to edit/delete and a FAB to add a new one.
class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ListingProvider>().loadMyListings());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Listings')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddListingScreen())),
        child: const Icon(Icons.add),
      ),
      body: Consumer<ListingProvider>(
        builder: (context, provider, _) {
          switch (provider.status) {
            case LoadStatus.idle:
            case LoadStatus.loading:
              return const LoadingView();
            case LoadStatus.error:
              return ErrorView(
                message: provider.errorMessage ?? 'Failed to load your listings',
                onRetry: provider.loadMyListings,
              );
            case LoadStatus.empty:
              return const EmptyView(
                message: "You haven't listed anything yet. Tap + to add your first listing.",
                icon: Icons.storefront_outlined,
              );
            default:
              return RefreshIndicator(
                onRefresh: provider.loadMyListings,
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: provider.myListings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _ListingTile(listing: provider.myListings[i]),
                ),
              );
          }
        },
      ),
    );
  }
}

class _ListingTile extends StatelessWidget {
  final Listing listing;
  const _ListingTile({required this.listing});

  Color _statusColor() {
    switch (listing.status) {
      case ListingStatus.active:
        return Colors.green;
      case ListingStatus.inactive:
        return Colors.grey;
      case ListingStatus.soldOut:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final priceFormat = NumberFormat.currency(symbol: '${listing.currency} ', decimalDigits: 2);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey.shade200,
          backgroundImage: listing.primaryImageUrl != null ? NetworkImage(listing.primaryImageUrl!) : null,
          child: listing.primaryImageUrl == null ? const Icon(Icons.image_outlined, color: Colors.grey) : null,
        ),
        title: Text(listing.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${priceFormat.format(listing.price)} / ${listing.unit}'),
        trailing: Chip(
          label: Text(listingStatusLabel(listing.status), style: const TextStyle(fontSize: 11)),
          backgroundColor: _statusColor().withOpacity(0.12),
          labelStyle: TextStyle(color: _statusColor()),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditListingScreen(listing: listing))),
      ),
    );
  }
}
