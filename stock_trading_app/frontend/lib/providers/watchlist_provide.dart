import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stock_trading_app/models/watchlist.dart';
import 'package:stock_trading_app/services/api_service.dart';

final watchlistProvider = StateNotifierProvider<WatchlistNotifier, AsyncValue<List<WatchlistItem>>>((ref) {
  return WatchlistNotifier();
});

class WatchlistNotifier extends StateNotifier<AsyncValue<List<WatchlistItem>>> {
  final ApiService _apiService = ApiService();

  WatchlistNotifier() : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final items = await _apiService.getWatchlist();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> add(WatchlistItem item) async {
    try {
      final newItem = await _apiService.addToWatchlist(item);
      state.whenData((items) {
        state = AsyncValue.data([...items, newItem]);
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> update(WatchlistItem item) async {
    try {
      final updated = await _apiService.updateWatchlistItem(item);
      state.whenData((items) {
        final index = items.indexWhere((i) => i.id == updated.id);
        if (index != -1) {
          final newList = List<WatchlistItem>.from(items);
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
      await _apiService.deleteFromWatchlist(id);
      state.whenData((items) {
        state = AsyncValue.data(items.where((i) => i.id != id).toList());
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}