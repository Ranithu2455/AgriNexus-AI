import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/api/api_client.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../models/seller_summary.dart';
import '../services/marketplace_api_service.dart';
import '../widgets/rating_stars.dart';
import '../../products/screens/product_list_screen.dart';
import 'reviews_screen.dart';

enum _LoadState { loading, success, error }

/// Public profile for a farmer (or any non-supplier seller): contact info,
/// rating, and their current listings.
///
/// Reuses the generic `/api/buyers/{id}` (any-user lookup) and
/// `/api/suppliers/{id}/rating` (reviewee-based, not role-restricted)
/// endpoints rather than adding farmer-specific backend routes, since the
/// farmer module itself belongs to a teammate — see backend/app/farmer/.
class FarmerProfileScreen extends StatefulWidget {
  final String userId;
  const FarmerProfileScreen({super.key, required this.userId});

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  _LoadState _state = _LoadState.loading;
  String? _error;
  SellerSummary? _profile;
  double? _rating;
  int _reviewCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = _LoadState.loading);
    try {
      final api = context.read<MarketplaceApiService>();
      final results = await Future.wait([
        api.getBuyerProfile(widget.userId),
        api.getSupplierRating(widget.userId),
      ]);
      setState(() {
        _profile = results[0] as SellerSummary;
        final ratingData = results[1] as Map<String, dynamic>;
        _rating = ratingData['average_rating'] != null ? (ratingData['average_rating'] as num).toDouble() : null;
        _reviewCount = ratingData['review_count'] as int? ?? 0;
        _state = _LoadState.success;
      });
    } on NetworkException catch (e) {
      setState(() {
        _error = e.message;
        _state = _LoadState.error;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.isNotFound ? 'User not found' : e.message;
        _state = _LoadState.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Farmer profile')),
      body: switch (_state) {
        _LoadState.loading => const LoadingView(),
        _LoadState.error => ErrorView(message: _error ?? 'Failed to load profile', onRetry: _load),
        _LoadState.success => _buildContent(context, _profile!),
      },
    );
  }

  Widget _buildContent(BuildContext context, SellerSummary profile) {
    final api = context.read<MarketplaceApiService>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CircleAvatar(
          radius: 40,
          child: Text(profile.fullName.isNotEmpty ? profile.fullName[0] : '?', style: const TextStyle(fontSize: 28)),
        ),
        const SizedBox(height: 12),
        Center(child: Text(profile.fullName, style: Theme.of(context).textTheme.headlineSmall)),
        const SizedBox(height: 4),
        Center(child: RatingStars(rating: _rating, reviewCount: _reviewCount)),
        if (profile.location != null) ...[
          const SizedBox(height: 4),
          Center(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(profile.location!, style: const TextStyle(color: Colors.grey)),
            ]),
          ),
        ],
        const SizedBox(height: 24),
        Card(
          child: ListTile(
            leading: const Icon(Icons.agriculture_outlined),
            title: const Text('View listings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProductListScreen(
                  title: "${profile.fullName}'s listings",
                  fetcher: () async => (await api.browseProducts(sellerId: profile.id, pageSize: 50)).items,
                ),
              ),
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.star_outline),
            title: const Text('View reviews'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ReviewsScreen(userId: profile.id, userName: profile.fullName)),
            ),
          ),
        ),
      ],
    );
  }
}
