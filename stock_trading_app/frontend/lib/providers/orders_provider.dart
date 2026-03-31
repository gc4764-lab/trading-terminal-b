import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_trading_app/models/order.dart';
import 'package:stock_trading_app/services/api_service.dart';

final ordersProvider = StateNotifierProvider<OrdersNotifier, AsyncValue<List<Order>>>((ref) {
  return OrdersNotifier();
});

class OrdersNotifier extends StateNotifier<AsyncValue<List<Order>>> {
  final ApiService _apiService = ApiService();

  OrdersNotifier() : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final orders = await _apiService.getOrders();
      state = AsyncValue.data(orders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> placeOrder(Order order) async {
    try {
      final newOrder = await _apiService.placeOrder(order);
      state.whenData((orders) {
        state = AsyncValue.data([newOrder, ...orders]);
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}