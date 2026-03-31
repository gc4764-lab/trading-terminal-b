import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_trading_app/providers/orders_provider.dart';
import 'package:stock_trading_app/widgets/order_item.dart';
import 'package:intl/intl.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);
    final brokerList = ref.watch(brokersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders & Trades'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(ordersProvider.notifier).refresh(),
          ),
        ],
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(child: Text('No orders found'));
          }
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return OrderItem(order: order);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPlaceOrderDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showPlaceOrderDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => PlaceOrderDialog(
        onPlace: (order) {
          ref.read(ordersProvider.notifier).placeOrder(order);
        },
      ),
    );
  }
}