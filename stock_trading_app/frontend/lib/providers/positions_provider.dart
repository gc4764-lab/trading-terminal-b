import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_trading_app/models/position.dart';
import 'package:stock_trading_app/services/api_service.dart';

final positionsProvider = StateNotifierProvider<PositionsNotifier, AsyncValue<List<Position>>>((ref) {
  return PositionsNotifier();
});

final holdingsProvider = StateNotifierProvider<HoldingsNotifier, AsyncValue<List<Holding>>>((ref) {
  return HoldingsNotifier();
});

class PositionsNotifier extends StateNotifier<AsyncValue<List<Position>>> {
  final ApiService _apiService = ApiService();

  PositionsNotifier() : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final positions = await _apiService.getPositions();
      state = AsyncValue.data(positions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

class HoldingsNotifier extends StateNotifier<AsyncValue<List<Holding>>> {
  final ApiService _apiService = ApiService();

  HoldingsNotifier() : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final holdings = await _apiService.getHoldings();
      state = AsyncValue.data(holdings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}