import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/state_widgets.dart';
import '../models/order.dart';
import '../../marketplace/providers/marketplace_provider.dart';
import '../providers/order_provider.dart';
import '../widgets/order_status_badge.dart';
import 'order_details_screen.dart';

/// Buyer-facing: every order/request the current user has placed. Not one
/// of the module's named screens, but necessary so a buyer can actually
/// find their way back to an order after leaving ProductDetailsScreen.
class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<OrderProvider>().loadMyOrders());
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd().add_jm();
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: Consumer<OrderProvider>(
        builder: (context, provider, _) {
          switch (provider.myOrdersStatus) {
            case LoadStatus.idle:
            case LoadStatus.loading:
              return const LoadingView();
            case LoadStatus.error:
              return ErrorView(message: provider.errorMessage ?? 'Failed to load orders', onRetry: provider.loadMyOrders);
            case LoadStatus.empty:
              return const EmptyView(message: "You haven't placed any orders yet", icon: Icons.receipt_long_outlined);
            default:
              return RefreshIndicator(
                onRefresh: provider.loadMyOrders,
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: provider.myOrders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final MarketOrder order = provider.myOrders[i];
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
