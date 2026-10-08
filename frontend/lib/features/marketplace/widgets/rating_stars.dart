import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  final double? rating; // null = no ratings yet
  final int reviewCount;
  final double size;

  const RatingStars({super.key, required this.rating, this.reviewCount = 0, this.size = 16});

  @override
  Widget build(BuildContext context) {
    if (rating == null) {
      return const Text('No reviews yet', style: TextStyle(color: Colors.grey, fontSize: 12));
    }
    final full = rating!.floor();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (i) {
          IconData icon;
          if (i < full) {
            icon = Icons.star;
          } else if (i == full && (rating! - full) >= 0.5) {
            icon = Icons.star_half;
          } else {
            icon = Icons.star_border;
          }
          return Icon(icon, size: size, color: Colors.amber);
        }),
        const SizedBox(width: 4),
        Text('${rating!.toStringAsFixed(1)} ($reviewCount)', style: TextStyle(fontSize: size * 0.75, color: Colors.grey)),
      ],
    );
  }
}
