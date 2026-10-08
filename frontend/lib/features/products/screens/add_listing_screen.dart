import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/listing_provider.dart';
import '../widgets/listing_form.dart';
import 'edit_listing_screen.dart';

/// Create a new listing. Images are attached after creation (the backend
/// uploads images against an existing listing_id), so a successful submit
/// moves straight into EditListingScreen's photo manager.
class AddListingScreen extends StatelessWidget {
  const AddListingScreen({super.key});

  Future<void> _submit(BuildContext context, ListingFormValues values) async {
    final provider = context.read<ListingProvider>();
    try {
      final listing = await provider.createListing(
        categoryId: values.categoryId,
        listingType: values.listingType,
        supplierProductType: values.supplierProductType,
        title: values.title,
        description: values.description,
        quantity: values.quantity,
        unit: values.unit,
        price: values.price,
        location: values.location,
        availableDate: values.availableDate,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing created — add some photos!')),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => EditListingScreen(listing: listing)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not create listing: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New listing')),
      body: ListingForm(
        submitLabel: 'Create listing',
        onSubmit: (values) => _submit(context, values),
      ),
    );
  }
}
