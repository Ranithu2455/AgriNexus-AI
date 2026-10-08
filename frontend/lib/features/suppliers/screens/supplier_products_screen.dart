import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../marketplace/services/marketplace_api_service.dart';
import '../../products/screens/product_list_screen.dart';

/// All active listings from one supplier.
class SupplierProductsScreen extends StatelessWidget {
  final String supplierId;
  final String? supplierName;

  const SupplierProductsScreen({super.key, required this.supplierId, this.supplierName});

  @override
  Widget build(BuildContext context) {
    final api = context.read<MarketplaceApiService>();
    return ProductListScreen(
      title: supplierName != null ? "$supplierName's products" : 'Supplier products',
      fetcher: () => api.getSupplierProducts(supplierId),
    );
  }
}
