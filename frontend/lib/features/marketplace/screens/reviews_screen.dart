import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../shared/api/api_client.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../models/review.dart';
import '../services/marketplace_api_service.dart';
import '../widgets/rating_stars.dart';

enum _LoadState { loading, success, empty, error }

/// Every review a seller (farmer or supplier) has received.
class ReviewsScreen extends StatefulWidget {
  final String userId;
  final String? userName;
  const ReviewsScreen({super.key, required this.userId, this.userName});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  _LoadState _state = _LoadState.loading;
  String? _error;
  List<Review> _reviews = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = _LoadState.loading);
    try {
      final reviews = await context.read<MarketplaceApiService>().getReviewsForUser(widget.userId);
      setState(() {
        _reviews = reviews;
        _state = reviews.isEmpty ? _LoadState.empty : _LoadState.success;
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
    final dateFormat = DateFormat.yMMMd();
    return Scaffold(
      appBar: AppBar(title: Text(widget.userName != null ? "${widget.userName}'s reviews" : 'Reviews')),
      body: switch (_state) {
        _LoadState.loading => const LoadingView(),
        _LoadState.error => ErrorView(message: _error ?? 'Failed to load reviews', onRetry: _load),
        _LoadState.empty => const EmptyView(message: 'No reviews yet', icon: Icons.star_border),
        _LoadState.success => ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _reviews.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, i) {
              final review = _reviews[i];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    RatingStars(rating: review.rating.toDouble()),
                    const Spacer(),
                    Text(dateFormat.format(review.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ]),
                  if (review.comment != null && review.comment!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(review.comment!),
                  ],
                ],
              );
            },
          ),
      },
    );
  }
}
