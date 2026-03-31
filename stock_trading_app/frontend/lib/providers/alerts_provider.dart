import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_trading_app/models/alert.dart';
import 'package:stock_trading_app/services/api_service.dart';

final alertsProvider = StateNotifierProvider<AlertsNotifier, AsyncValue<List<Alert>>>((ref) {
  return AlertsNotifier();
});

class AlertsNotifier extends StateNotifier<AsyncValue<List<Alert>>> {
  final ApiService _apiService = ApiService();

  AlertsNotifier() : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final alerts = await _apiService.getAlerts();
      state = AsyncValue.data(alerts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> add(Alert alert) async {
    try {
      final newAlert = await _apiService.createAlert(alert);
      state.whenData((alerts) {
        state = AsyncValue.data([...alerts, newAlert]);
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> update(Alert alert) async {
    try {
      final updated = await _apiService.updateAlert(alert);
      state.whenData((alerts) {
        final index = alerts.indexWhere((a) => a.id == updated.id);
        if (index != -1) {
          final newList = List<Alert>.from(alerts);
          newList[index] = updated;
          state = AsyncValue.data(newList);
        }
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _apiService.deleteAlert(id);
      state.whenData((alerts) {
        state = AsyncValue.data(alerts.where((a) => a.id != id).toList());
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleAlert(String id) async {
    state.whenData((alerts) {
      final alert = alerts.firstWhere((a) => a.id == id);
      final updatedAlert = Alert(
        id: alert.id,
        symbol: alert.symbol,
        type: alert.type,
        condition: alert.condition,
        value: alert.value,
        isActive: !alert.isActive,
        triggeredAt: alert.triggeredAt,
        createdAt: alert.createdAt,
        updatedAt: DateTime.now(),
      );
      update(updatedAlert);
    });
  }
}