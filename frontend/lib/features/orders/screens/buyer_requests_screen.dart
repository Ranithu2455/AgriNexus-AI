import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/state_widgets.dart';
import '../models/order.dart';
import '../../marketplace/providers/marketplace_provider.dart';
import '../providers/order_provider.dart';
import '../widgets/order_status_badge.dart';
import 'order_details_screen.dart';

/// Seller-facing: every order/request placed against the current user's
/// listings, so they can accept, reject, or mark it complete.
class BuyerRequestsScreen extends StatefulWidget {
  const BuyerRequestsScreen({super.key});

  @override
  State<BuyerRequestsScreen> createState() => _BuyerRequestsScreenState();
}

class _BuyerRequestsScreenState extends State<BuyerRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<OrderProvider>().loadReceivedOrders());
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd().add_jm();
    return Scaffold(
      appBar: AppBar(title: const Text('Buyer Requests')),
      body: Consumer<OrderProvider>(
        builder: (context, provider, _) {
          switch (provider.receivedOrdersStatus) {
            case LoadStatus.idle:
            case LoadStatus.loading:
              return const LoadingView();
            case LoadStatus.error:
              return ErrorView(
                message: provider.errorMessage ?? 'Failed to load requests',
                onRetry: provider.loadReceivedOrders,
              );
            case LoadStatus.empty:
              return const EmptyView(
                message: 'No buyer requests yet',
                icon: Icons.move_to_inbox_outlined,
              );
            default:
              return RefreshIndicator(
                onRefresh: provider.loadReceivedOrders,
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: provider.receivedOrders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final MarketOrder order = provider.receivedOrders[i];
                    return Card(
                      child: ListTile(
                        title: Text('${order.quantity} units · LKR ${order.totalPrice.toStringAsFixed(2)}'),
                        subtitle: Text(dateFormat.format(order.createdAt)),
                        trailing: OrderStatusBadge(status: order.status),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => OrderDetailsScreen(orderId: order.id)),
                        ),
                      ),
                    );
                  },
                ),
              );
          }
        },
      ),
    );
  }
}
