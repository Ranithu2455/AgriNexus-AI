import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/listing.dart';
import '../providers/listing_provider.dart';
import '../widgets/listing_form.dart';
import '../widgets/listing_image_manager.dart';

/// Edit an existing listing's details, manage its photos, change its
/// status (active/inactive/sold out), or delete it. Ownership is enforced
/// server-side (see backend/app/marketplace/permissions.py) — this screen
/// is only ever reached from "My Listings", which only shows the current
/// user's own listings.
class EditListingScreen extends StatefulWidget {
  final Listing listing;
  const EditListingScreen({super.key, required this.listing});

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  late Listing _listing;

  @override
  void initState() {
    super.initState();
    _listing = widget.listing;
  }

  Future<void> _save(ListingFormValues values) async {
    final provider = context.read<ListingProvider>();
    try {
      final updated = await provider.updateListing(_listing.id, {
        'category_id': values.categoryId,
        'title': values.title,
        'description': values.description,
        'quantity': values.quantity,
        'unit': values.unit,
        'price': values.price,
        'location': values.location,
        'available_date': values.availableDate?.toIso8601String(),
      });
      setState(() => _listing = updated);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing updated')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save: $e')));
    }
  }

  Future<void> _changeStatus(ListingStatus status) async {
    final provider = context.read<ListingProvider>();
    try {
      final updated = await provider.updateListing(_listing.id, {'status': listingStatusToString(status)});
      setState(() => _listing = updated);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update status: $e')));
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete listing?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<ListingProvider>().deleteListing(_listing.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not delete: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit listing'),
        actions: [
          PopupMenuButton<ListingStatus>(
            icon: const Icon(Icons.more_vert),
            onSelected: _changeStatus,
            itemBuilder: (_) => ListingStatus.values
                .map((s) => PopupMenuItem(value: s, child: Text('Mark as ${listingStatusLabel(s)}')))
                .toList(),
          ),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            // Watches the provider so newly-uploaded images show up
            // immediately; falls back to the locally-held copy if this
            // listing isn't in `myListings` yet (e.g. navigated here
            // directly after creation).
            child: Consumer<ListingProvider>(
              builder: (context, provider, _) {
                final live = provider.myListings.where((l) => l.id == _listing.id);
                final current = live.isNotEmpty ? live.first : _listing;
                return ListingImageManager(listing: current, provider: provider);
              },
            ),
          ),
          ListingForm(initial: _listing, onSubmit: _save, submitLabel: 'Save changes'),
        ],
      ),
    );
  }
}
