import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_trading_app/models/broker_config.dart';
import 'package:stock_trading_app/services/api_service.dart';

final brokersProvider = StateNotifierProvider<BrokersNotifier, AsyncValue<List<BrokerConfig>>>((ref) {
  return BrokersNotifier();
});

class BrokersNotifier extends StateNotifier<AsyncValue<List<BrokerConfig>>> {
  final ApiService _apiService = ApiService();

  BrokersNotifier() : super(const AsyncValue.loading()) {
    loadBrokers();
  }

  Future<void> loadBrokers() async {
    state = const AsyncValue.loading();
    try {
      final brokers = await _apiService.getBrokers();
      state = AsyncValue.data(brokers);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> connect(BrokerConfig config) async {
    try {
      final newBroker = await _apiService.connectBroker(config);
      state.whenData((brokers) {
        state = AsyncValue.data([...brokers, newBroker]);
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> disconnect(String id) async {
    try {
      await _apiService.disconnectBroker(id);
      state.whenData((brokers) {
        state = AsyncValue.data(brokers.where((b) => b.id != id).toList());
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}