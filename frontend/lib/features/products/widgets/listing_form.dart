import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/auth_service.dart';
import '../models/listing.dart';
import '../../marketplace/providers/marketplace_provider.dart';

/// Fields collected by the form; screens decide what to do with them
/// (create vs update) via [onSubmit].
class ListingFormValues {
  final String categoryId;
  final ListingType listingType;
  final String? supplierProductType;
  final String title;
  final String? description;
  final double quantity;
  final String unit;
  final double price;
  final String? location;
  final DateTime? availableDate;

  ListingFormValues({
    required this.categoryId,
    required this.listingType,
    this.supplierProductType,
    required this.title,
    this.description,
    required this.quantity,
    required this.unit,
    required this.price,
    this.location,
    this.availableDate,
  });
}

class ListingForm extends StatefulWidget {
  final Listing? initial;
  final Future<void> Function(ListingFormValues values) onSubmit;
  final String submitLabel;

  const ListingForm(
      {super.key,
      this.initial,
      required this.onSubmit,
      this.submitLabel = 'Save'});

  @override
  State<ListingForm> createState() => _ListingFormState();
}

class _ListingFormState extends State<ListingForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _quantity;
  late final TextEditingController _unit;
  late final TextEditingController _price;
  late final TextEditingController _location;

  String? _categoryId;
  late ListingType _listingType;
  String? _supplierProductType;
  DateTime? _availableDate;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final l = widget.initial;
    _title = TextEditingController(text: l?.title ?? '');
    _description = TextEditingController(text: l?.description ?? '');
    _quantity = TextEditingController(text: l?.quantity.toString() ?? '');
    _unit = TextEditingController(text: l?.unit ?? '');
    _price = TextEditingController(text: l?.price.toString() ?? '');
    _location = TextEditingController(text: l?.location ?? '');
    _categoryId = l?.categoryId;
    _availableDate = l?.availableDate;

    // Default listing type follows the current user's role — a supplier
    // creating a listing is almost always listing a supplier product.
    final role = context.read<AuthService>().currentUser?.role;
    _listingType = l?.listingType ??
        (role == 'supplier'
            ? ListingType.supplierProduct
            : ListingType.farmerProduct);
    _supplierProductType = l?.supplierProductType;

    if (context.read<MarketplaceProvider>().categories.isEmpty) {
      context.read<MarketplaceProvider>().loadCategories();
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _quantity.dispose();
    _unit.dispose();
    _price.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please choose a category')));
      return;
    }
    if (_listingType == ListingType.supplierProduct &&
        _supplierProductType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please choose a product type')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(ListingFormValues(
        categoryId: _categoryId!,
        listingType: _listingType,
        supplierProductType: _listingType == ListingType.supplierProduct
            ? _supplierProductType
            : null,
        title: _title.text.trim(),
        description:
            _description.text.trim().isEmpty ? null : _description.text.trim(),
        quantity: double.parse(_quantity.text),
        unit: _unit.text.trim(),
        price: double.parse(_price.text),
        location: _location.text.trim().isEmpty ? null : _location.text.trim(),
        availableDate: _availableDate,
      ));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<MarketplaceProvider>().categories;
    final isEditing = widget.initial != null;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!isEditing) ...[
            SegmentedButton<ListingType>(
              segments: const [
                ButtonSegment(
                    value: ListingType.farmerProduct,
                    label: Text('Farm produce')),
                ButtonSegment(
                    value: ListingType.supplierProduct,
                    label: Text('Agri-input')),
              ],
              selected: {_listingType},
              onSelectionChanged: (s) => setState(() => _listingType = s.first),
            ),
            const SizedBox(height: 16),
          ],
          if (_listingType == ListingType.supplierProduct) ...[
            DropdownButtonFormField<String>(
              value: _supplierProductType,
              decoration: const InputDecoration(
                  labelText: 'Product type', border: OutlineInputBorder()),
              items: supplierProductTypes
                  .map((t) => DropdownMenuItem(
                      value: t, child: Text(t.replaceAll('_', ' '))))
                  .toList(),
              onChanged: (v) => setState(() => _supplierProductType = v),
            ),
            const SizedBox(height: 12),
          ],
          DropdownButtonFormField<String>(
            value:
                categories.any((c) => c.id == _categoryId) ? _categoryId : null,
            decoration: const InputDecoration(
                labelText: 'Category', border: OutlineInputBorder()),
            items: categories
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                .toList(),
            onChanged: (v) => setState(() => _categoryId = v),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _title,
            decoration: const InputDecoration(
                labelText: 'Title', border: OutlineInputBorder()),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _description,
            decoration: const InputDecoration(
                labelText: 'Description', border: OutlineInputBorder()),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _quantity,
                  decoration: const InputDecoration(
                      labelText: 'Quantity', border: OutlineInputBorder()),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => (double.tryParse(v ?? '') == null ||
                          double.parse(v!) <= 0)
                      ? 'Invalid'
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _unit,
                  decoration: const InputDecoration(
                      labelText: 'Unit (kg, bag...)',
                      border: OutlineInputBorder()),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _price,
            decoration: const InputDecoration(
                labelText: 'Price per unit (LKR)',
                border: OutlineInputBorder()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) =>
                (double.tryParse(v ?? '') == null || double.parse(v!) <= 0)
                    ? 'Invalid'
                    : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _location,
            decoration: const InputDecoration(
                labelText: 'Location', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_availableDate == null
                ? 'Available date (optional)'
                : 'Available from ${_availableDate!.toLocal().toString().split(' ').first}'),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _availableDate ?? DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _availableDate = picked);
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(widget.submitLabel),
          ),
        ],
      ),
    );
  }
}
